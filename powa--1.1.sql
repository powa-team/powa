-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION powa" to load this file. \quit

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;
SET search_path = public, pg_catalog;

CREATE TYPE powa_statement_history_record AS (
    ts timestamp with time zone,
    calls bigint,
    total_time double precision,
    rows bigint,
    shared_blks_hit bigint,
    shared_blks_read bigint,
    shared_blks_dirtied bigint,
    shared_blks_written bigint,
    local_blks_hit bigint,
    local_blks_read bigint,
    local_blks_dirtied bigint,
    local_blks_written bigint,
    temp_blks_read bigint,
    temp_blks_written bigint,
    blk_read_time double precision,
    blk_write_time double precision
);

CREATE TABLE powa_last_aggregation (
    aggts timestamp with time zone
);

INSERT INTO powa_last_aggregation(aggts) VALUES (current_timestamp);

CREATE TABLE powa_last_purge (
    purgets timestamp with time zone
);

INSERT INTO powa_last_purge (purgets) VALUES (current_timestamp);

CREATE TABLE powa_statements (
    md5query text NOT NULL,
    rolname text NOT NULL,
    dbname text NOT NULL,
    query text NOT NULL
);

ALTER TABLE ONLY powa_statements
    ADD CONSTRAINT powa_statements_pkey PRIMARY KEY (md5query);

CREATE INDEX powa_statements_dbname_idx ON powa_statements(dbname);


CREATE TABLE powa_statements_history (
    md5query text,
    coalesce_range tstzrange,
    records powa_statement_history_record[]
);

CREATE INDEX powa_statements_history_query_ts ON powa_statements_history USING gist (md5query,coalesce_range);

CREATE TABLE powa_statements_history_current (
    md5query text,
    record powa_statement_history_record
);

CREATE SEQUENCE powa_coalesce_sequence INCREMENT BY 1
  START WITH 1
  CYCLE;


CREATE TABLE powa_functions (
    operation TEXT,
    function_name TEXT,
    CHECK (operation IN ('snapshot','aggregate','purge'))
);

INSERT INTO powa_functions VALUES ('snapshot','powa_take_statements_snapshot'),('aggregate','powa_statements_aggregate'),('purge','powa_statements_purge');

CREATE OR REPLACE FUNCTION powa_take_snapshot() RETURNS void AS $PROC$
DECLARE
  purgets timestamp with time zone;
  purge_seq bigint;
  funcname text;
BEGIN
    -- For all snapshot functions in the powa_functions table, execute
    FOR funcname IN SELECT function_name
                 FROM powa_functions
                 WHERE operation='snapshot' LOOP
      -- Call all of them, with no parameter
RAISE debug 'fonction: %',funcname;
      EXECUTE 'SELECT ' || quote_ident(funcname)||'()';
    END LOOP;

    -- Coalesce datas into statements_history
    SELECT nextval('powa_coalesce_sequence'::regclass) INTO purge_seq;
    IF (  purge_seq
            % current_setting('powa.coalesce')::bigint ) = 0
    THEN
      FOR funcname IN SELECT function_name
                   FROM powa_functions
                   WHERE operation='aggregate' LOOP
        -- Call all of them, with no parameter
        EXECUTE 'SELECT ' || quote_ident(funcname)||'()';
      END LOOP;
      UPDATE powa_last_aggregation SET aggts = now();
    END IF;
    -- Once every 10 packs, we also purge
    IF (  purge_seq
            % (current_setting('powa.coalesce')::bigint *10) ) = 0
    THEN
      FOR funcname IN SELECT function_name
                   FROM powa_functions
                   WHERE operation='purge' LOOP
        -- Call all of them, with no parameter
        EXECUTE 'SELECT ' || quote_ident(funcname)||'()';
      END LOOP;
      UPDATE powa_last_purge SET purgets=now();
    END IF;
END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_take_statements_snapshot() RETURNS void AS $PROC$
DECLARE
BEGIN
    RAISE DEBUG 'running powa_take_statements_snapshot';
    INSERT INTO powa_statements (md5query,rolname,dbname,query)
    SELECT DISTINCT  md5(rolname||datname||query),rolname,datname,query
      FROM pg_stat_statements s
      JOIN pg_authid a ON (s.userid=a.oid)
      JOIN pg_database d ON (s.dbid=d.oid)
     WHERE NOT EXISTS (SELECT 1
                         FROM powa_statements
                        WHERE powa_statements.md5query = md5(a.rolname||d.datname||s.query));

    INSERT INTO powa_statements_history_current
    SELECT md5(rolname||datname||query),
           ROW(now(),sum(calls),sum(total_time),sum(rows),sum(shared_blks_hit),sum(shared_blks_read),
                 sum(shared_blks_dirtied),sum(shared_blks_written),sum(local_blks_hit),sum(local_blks_read),
                 sum(local_blks_dirtied),sum(local_blks_written),sum(temp_blks_read),sum(temp_blks_written),
                 sum(blk_read_time),sum(blk_write_time))::powa_statement_history_record
      FROM pg_stat_statements
      JOIN pg_authid ON (pg_stat_statements.userid=pg_authid.oid)
      JOIN pg_database ON (pg_stat_statements.dbid=pg_database.oid)
     GROUP BY md5(rolname||datname||query),now();
END;
$PROC$ language plpgsql;

CREATE OR REPLACE FUNCTION powa_statements_purge() RETURNS void AS $PROC$
BEGIN
    RAISE DEBUG 'running powa_statements_purge';
    -- Delete obsolete datas. We only bother with already coalesced data
    DELETE FROM powa_statements_history WHERE upper(coalesce_range)< (now() - current_setting('powa.retention')::interval);
    -- Update last purge timestamp
    -- FIXME maybe we should cleanup the powa_statements table ? But it will take a while: unnest all records...
END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_statements_aggregate() RETURNS void AS $PROC$
BEGIN
    RAISE DEBUG 'running powa_statements_aggregate';
    LOCK TABLE powa_statements_history_current IN SHARE MODE; -- prevent any other update
    INSERT INTO powa_statements_history
      SELECT md5query,
           tstzrange(min((record).ts), max((record).ts),'[]'),
           array_agg(record)
      FROM powa_statements_history_current
     GROUP BY md5query;
    TRUNCATE powa_statements_history_current;
END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_getstatdata (IN ts_start timestamptz, IN ts_end timestamptz)
    RETURNS TABLE (md5query text, query text, dbname text, total_calls numeric, total_runtime double precision,
    total_mesure_interval interval, total_blks_read numeric, total_blks_hit numeric)
AS
$$
BEGIN
    RETURN QUERY
    WITH statements_history AS (
        SELECT unnested.md5query,(unnested.records).*
        FROM (
            SELECT psh.md5query, psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history psh
            WHERE coalesce_range && tstzrange(ts_start,ts_end,'[]') OR coalesce_range is null
        ) AS unnested
        WHERE tstzrange(ts_start,ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT powa_statements_history_current.md5query, (powa_statements_history_current.record).*
        FROM powa_statements_history_current
        WHERE tstzrange(ts_start,ts_end,'[]') @> (record).ts
    ),
    statements_history_differential AS (
        SELECT sh.md5query, sh.ts, ps.query, ps.dbname,
        int8larger(lead(calls) over (querygroup) - calls,0) calls,
        float8larger(lead(total_time) over (querygroup) - total_time,0) runtime,
        interval_larger(lead(ts) over (querygroup) - ts,interval '0 second') mesure_interval,
        int8larger(lead(shared_blks_read) over (querygroup) - shared_blks_read,0) blks_read,
        int8larger(lead(shared_blks_hit) over (querygroup) - shared_blks_hit,0) blks_hit
        FROM statements_history sh
        NATURAL JOIN powa_statements ps
        WINDOW querygroup AS (PARTITION BY sh.md5query ORDER BY ts)
    )

    SELECT s.md5query,
    s.query,
    s.dbname,
    sum(s.calls) AS total_calls,
    sum(s.runtime) AS total_runtime,
    sum(s.mesure_interval) AS total_mesure_interval,
    sum(s.blks_read) AS total_blks_read,
    sum(s.blks_hit) AS total_blks_hit
    FROM statements_history_differential s
    GROUP BY s.md5query, s.query, s.dbname;
END
$$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION public.powa_getstatdata_sample(ts_start timestamp with time zone, ts_end timestamp with time zone, pmd5query text, samples integer)
 RETURNS TABLE(ts timestamp with time zone, total_calls bigint, total_runtime double precision, total_mesure_interval interval, rows bigint, shared_blks_read bigint, shared_blks_hit bigint, shared_blks_dirtied bigint, shared_blks_written bigint, local_blks_read bigint, local_blks_hit bigint, local_blks_dirtied bigint, local_blks_written bigint, temp_blks_read bigint, temp_blks_written bigint, blk_read_time double precision, blk_write_time double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH statements_history AS (
        SELECT (unnested.records).*
        FROM (
            SELECT psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history psh
            WHERE md5query=pmd5query
            AND (coalesce_range && tstzrange(ts_start, ts_end,'[]') OR coalesce_range is null)
        ) AS unnested
        WHERE tstzrange(ts_start, ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT (record).*
        FROM powa_statements_history_current
        WHERE tstzrange(ts_start, ts_end,'[]') @> (record).ts
    ),
    statements_history_number AS (
        SELECT row_number() over (order by statements_history.ts) as number, *
        FROM statements_history
    ),
    sampled_statements_history AS ( SELECT * FROM statements_history_number WHERE number % (int8larger((SELECT count(*) FROM statements_history)/(samples+1),1) )=0 ),

    statements_history_differential AS (
        SELECT  sh.ts,
        int8larger(lead(calls) over (querygroup) - calls,0) calls,
        float8larger(lead(total_time) over (querygroup) - total_time,0) runtime,
        interval_larger(lead(sh.ts) over (querygroup) - sh.ts,interval '0 second') mesure_interval,
        int8larger(lead(sh.rows) over (querygroup) - sh.rows,0) "rows",
        int8larger(lead(sh.shared_blks_read) over (querygroup) - sh.shared_blks_read,0) shared_blks_read,
        int8larger(lead(sh.shared_blks_hit) over (querygroup) - sh.shared_blks_hit,0) shared_blks_hit,
        int8larger(lead(sh.shared_blks_dirtied) over (querygroup) - sh.shared_blks_dirtied,0) shared_blks_dirtied,
        int8larger(lead(sh.shared_blks_written) over (querygroup) - sh.shared_blks_written,0) shared_blks_written,
        int8larger(lead(sh.local_blks_read) over (querygroup) - sh.local_blks_read,0) local_blks_read,
        int8larger(lead(sh.local_blks_hit) over (querygroup) - sh.local_blks_hit,0) local_blks_hit,
        int8larger(lead(sh.local_blks_dirtied) over (querygroup) - sh.local_blks_dirtied,0) local_blks_dirtied,
        int8larger(lead(sh.local_blks_written) over (querygroup) - sh.local_blks_written,0) local_blks_written,
        int8larger(lead(sh.temp_blks_read) over (querygroup) - sh.temp_blks_read,0) temp_blks_read,
        int8larger(lead(sh.temp_blks_written) over (querygroup) - sh.temp_blks_written,0) temp_blks_written,
        float8larger(lead(sh.blk_read_time) over (querygroup) - sh.blk_read_time,0) blk_read_time,
        float8larger(lead(sh.blk_write_time) over (querygroup) - sh.blk_write_time,0) blk_write_time
        FROM sampled_statements_history sh
        WINDOW querygroup AS (ORDER BY sh.ts)
    )

    SELECT * FROM statements_history_differential WHERE calls IS NOT NULL;
END
$function$
;

CREATE OR REPLACE FUNCTION public.powa_getstatdata_sample_db(ts_start timestamp with time zone, ts_end timestamp with time zone, p_datname text, samples integer)
 RETURNS TABLE(ts timestamp with time zone, total_calls bigint, total_runtime double precision, total_mesure_interval interval, rows bigint, shared_blks_read bigint, shared_blks_hit bigint, shared_blks_dirtied bigint, shared_blks_written bigint, local_blks_read bigint, local_blks_hit bigint, local_blks_dirtied bigint, local_blks_written bigint, temp_blks_read bigint, temp_blks_written bigint, blk_read_time double precision, blk_write_time double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH db_statements_history AS (
        SELECT (records).*
        FROM (
            SELECT psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history psh
            JOIN powa_statements ps ON (ps.md5query = psh.md5query)
            WHERE dbname = p_datname
            AND (coalesce_range && tstzrange(ts_start, ts_end,'[]') OR coalesce_range is null)
        ) AS unnested
        WHERE tstzrange(ts_start, ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT (record).*
        FROM powa_statements_history_current
        WHERE tstzrange(ts_start, ts_end,'[]') @> (record).ts
    ),
    db_statements_history_ranked AS (
        SELECT dense_rank() over (order by db_statements_history.ts) as number, *
        FROM db_statements_history
    ),
    sampled_db_statements_history AS ( SELECT * FROM db_statements_history_ranked WHERE number % (int8larger((SELECT max(number) FROM db_statements_history_ranked)/(samples+1),1) )=0 ),
    grouped_db_statements_history AS (
      SELECT sum(s.calls)::bigint as calls,
             sum(s.total_time)::bigint as total_time,
             s.ts,
             sum(s.rows)::bigint as rows,
             sum(s.shared_blks_read)::bigint as shared_blks_read,
             sum(s.shared_blks_hit)::bigint as shared_blks_hit,
             sum(s.shared_blks_dirtied)::bigint as shared_blks_dirtied,
             sum(s.shared_blks_written)::bigint as shared_blks_written,
             sum(s.local_blks_read)::bigint as local_blks_read,
             sum(s.local_blks_hit)::bigint as local_blks_hit,
             sum(s.local_blks_dirtied)::bigint as local_blks_dirtied,
             sum(s.local_blks_written)::bigint as local_blks_written,
             sum(s.temp_blks_read)::bigint as temp_blks_read,
             sum(s.temp_blks_written)::bigint as temp_blks_written,
             sum(s.blk_read_time)::bigint as blk_read_time,
             sum(s.blk_write_time)::bigint as blk_write_time
             FROM sampled_db_statements_history s
             GROUP BY s.ts
    ),
    db_statements_history_differential AS (
        SELECT  sh.ts,
        int8larger(lead(calls) over (querygroup) - calls,0) calls,
        float8larger(lead(total_time) over (querygroup) - total_time,0) runtime,
        interval_larger(lead(sh.ts) over (querygroup) - sh.ts,interval '0 second') mesure_interval,
        int8larger(lead(sh.rows) over (querygroup) - sh.rows,0) "rows",
        int8larger(lead(sh.shared_blks_read) over (querygroup) - sh.shared_blks_read,0) shared_blks_read,
        int8larger(lead(sh.shared_blks_hit) over (querygroup) - sh.shared_blks_hit,0) shared_blks_hit,
        int8larger(lead(sh.shared_blks_dirtied) over (querygroup) - sh.shared_blks_dirtied,0) shared_blks_dirtied,
        int8larger(lead(sh.shared_blks_written) over (querygroup) - sh.shared_blks_written,0) shared_blks_written,
        int8larger(lead(sh.local_blks_read) over (querygroup) - sh.local_blks_read,0) local_blks_read,
        int8larger(lead(sh.local_blks_hit) over (querygroup) - sh.local_blks_hit,0) local_blks_hit,
        int8larger(lead(sh.local_blks_dirtied) over (querygroup) - sh.local_blks_dirtied,0) local_blks_dirtied,
        int8larger(lead(sh.local_blks_written) over (querygroup) - sh.local_blks_written,0) local_blks_written,
        int8larger(lead(sh.temp_blks_read) over (querygroup) - sh.temp_blks_read,0) temp_blks_read,
        int8larger(lead(sh.temp_blks_written) over (querygroup) - sh.temp_blks_written,0) temp_blks_written,
        float8larger(lead(sh.blk_read_time) over (querygroup) - sh.blk_read_time,0) blk_read_time,
        float8larger(lead(sh.blk_write_time) over (querygroup) - sh.blk_write_time,0) blk_write_time
        FROM grouped_db_statements_history sh
        WINDOW querygroup AS (ORDER BY sh.ts)
    )

    SELECT * FROM db_statements_history_differential WHERE calls IS NOT NULL;
END
$function$
;

CREATE OR REPLACE FUNCTION public.powa_getstatdata_db(ts_start timestamp with time zone, ts_end timestamp with time zone, pdbname text)
 RETURNS TABLE(md5query text, query text, dbname text, total_calls bigint, total_runtime numeric, total_blks_read bigint, total_blks_hit bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH statements_history AS (
        SELECT unnested.md5query,(unnested.records).*
        FROM (
            SELECT psh.md5query, psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history psh
            WHERE ( coalesce_range && tstzrange(ts_start,ts_end,'[]') OR coalesce_range is null )
            AND psh.md5query IN (SELECT powa_statements.md5query FROM powa_statements WHERE powa_statements.dbname=pdbname)
        ) AS unnested
        WHERE tstzrange(ts_start,ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT powa_statements_history_current.md5query,(powa_statements_history_current.record).*
        FROM powa_statements_history_current
        WHERE tstzrange(ts_start,ts_end,'[]') @> (record).ts
    )
    SELECT s.md5query,
    s.query,
    s.dbname,
    max(h.calls)-min(h.calls) AS total_calls,
    round((max(h.total_time)-min(h.total_time))::numeric,3) AS total_runtime,
    max(h.shared_blks_read)-min(h.shared_blks_read) AS total_blks_read,
    max(h.shared_blks_hit)-min(h.shared_blks_hit) AS total_blks_hit
    FROM statements_history h
    JOIN powa_statements s USING (md5query)
    WHERE s.dbname=pdbname
    GROUP BY s.md5query, s.query, s.dbname
    HAVING (max(h.calls)-min(h.calls)) > 0;
END
$function$
;

CREATE OR REPLACE FUNCTION public.powa_stats_reset()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    TRUNCATE TABLE powa_statements_history;
    TRUNCATE TABLE powa_statements_history_current;
    TRUNCATE TABLE powa_statements;
    RETURN true;
END
$function$
;

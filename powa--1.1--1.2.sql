-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION powa" to load this file. \quit

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;
SET search_path = public, pg_catalog;

-- We need to block the tables to calculate aggregates, do the purges, and have no surprise when the upgrade finishes
LOCK TABLE powa_statements;
LOCK TABLE powa_statements_history;
LOCK TABLE powa_statements_history_current;

-- Start with the purge. We count the deleted records (but not needed here).
WITH 
 to_delete AS 
    (DELETE FROM powa_statements WHERE query ~* '^[[:space:]]*(DEALLOCATE|BEGIN)' RETURNING md5query),
 delete_from_powa_statements_history AS 
    (DELETE FROM powa_statements_history WHERE md5query IN (SELECT md5query FROM to_delete) RETURNING 1) ,
 delete_from_powa_statements_history_current AS (DELETE FROM powa_statements_history_current WHERE md5query IN (SELECT md5query FROM to_delete) RETURNING 1)
        SELECT count(*) FROM (SELECT 1 FROM to_delete UNION ALL SELECT 1 FROM delete_from_powa_statements_history UNION ALL SELECT 1 FROM delete_from_powa_statements_history_current) AS tmp;

CREATE TABLE powa_statements_history_db (
    dbname text,
    coalesce_range tstzrange,
    records powa_statement_history_record[]
);

WITH unnested AS (
    SELECT dbname, coalesce_range, unnest(records) as record
    FROM powa_statements_history
    JOIN powa_statements USING (md5query)
   ),
   aggregated AS (
    SELECT dbname, coalesce_range,
    ROW((record).ts,sum((record).calls),sum((record).total_time),sum((record).rows),sum((record).shared_blks_hit),sum((record).shared_blks_read),
                    sum((record).shared_blks_dirtied),sum((record).shared_blks_written),sum((record).local_blks_hit),sum((record).local_blks_read),
                    sum((record).local_blks_dirtied),sum((record).local_blks_written),sum((record).temp_blks_read),sum((record).temp_blks_written),
                    sum((record).blk_read_time),sum((record).blk_write_time))::powa_statement_history_record as record
    FROM unnested
    GROUP BY dbname, coalesce_range, (record).ts
    )
INSERT INTO powa_statements_history_db
 SELECT dbname, coalesce_range, array_agg(record)
 FROM aggregated
 GROUP BY dbname, coalesce_range;

CREATE INDEX powa_statements_history_db_ts ON powa_statements_history_db USING gist (dbname,coalesce_range);

CREATE TABLE powa_statements_history_current_db (
    dbname text,
    record powa_statement_history_record
);

-- A bit complicated, unnecessarily, just to be kept consistent with the one for coalesced records
WITH last_stats AS (
    SELECT dbname, record
    FROM powa_statements_history_current
    JOIN powa_statements USING (md5query)
   ),
   aggregated AS (
    SELECT dbname,
    ROW((record).ts,sum((record).calls),sum((record).total_time),sum((record).rows),sum((record).shared_blks_hit),sum((record).shared_blks_read),
                    sum((record).shared_blks_dirtied),sum((record).shared_blks_written),sum((record).local_blks_hit),sum((record).local_blks_read),
                    sum((record).local_blks_dirtied),sum((record).local_blks_written),sum((record).temp_blks_read),sum((record).temp_blks_written),
                    sum((record).blk_read_time),sum((record).blk_write_time))::powa_statement_history_record as record
    FROM last_stats
    GROUP BY dbname, (record).ts
    )
INSERT INTO powa_statements_history_current_db
 SELECT dbname, record
 FROM aggregated;

 
ALTER TABLE powa_functions
  ADD COLUMN added_manually boolean default false; -- To put it to false for now
ALTER TABLE powa_functions
  ALTER COLUMN added_manually set default true; -- New entries will be to true

  
-- Mark all of powa's tables as "to be dumped"
SELECT pg_catalog.pg_extension_config_dump('powa_statements','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history_db','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history_current','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history_current_db','');
SELECT pg_catalog.pg_extension_config_dump('powa_functions','WHERE added_manually');


-- Recreate all functions. Pasted from the 1.2 script
-- Drop them before, sometimes the prototype changes...
DROP FUNCTION IF EXISTS powa_take_snapshot();
DROP FUNCTION IF EXISTS powa_take_statements_snapshot();
DROP FUNCTION IF EXISTS powa_statements_purge();
DROP FUNCTION IF EXISTS powa_statements_aggregate();
DROP FUNCTION IF EXISTS powa_getstatdata (IN ts_start timestamptz, IN ts_end timestamptz);
DROP FUNCTION IF EXISTS public.powa_getstatdata_sample(ts_start timestamp with time zone, ts_end timestamp with time zone, pmd5query text, samples integer);
DROP FUNCTION IF EXISTS public.powa_getstatdata_sample_db(ts_start timestamp with time zone, ts_end timestamp with time zone, p_datname text, samples integer);
DROP FUNCTION IF EXISTS public.powa_getstatdata_query(ts_start timestamp with time zone, ts_end timestamp with time zone, pmd5query text);
DROP FUNCTION IF EXISTS public.powa_getstatdata_db(ts_start timestamp with time zone, ts_end timestamp with time zone, pdbname text);
DROP FUNCTION IF EXISTS public.powa_getstatdata_detailed_db(ts_start timestamp with time zone, ts_end timestamp with time zone, pdbname text);
DROP FUNCTION IF EXISTS public.powa_stats_reset();


CREATE OR REPLACE FUNCTION powa_take_snapshot() RETURNS void AS $PROC$
DECLARE
  purgets timestamp with time zone;
  purge_seq bigint;
  funcname text;
  v_state   text;
  v_msg     text;
  v_detail  text;
  v_hint    text;
  v_context text;

BEGIN
    -- For all snapshot functions in the powa_functions table, execute
    FOR funcname IN SELECT function_name
                 FROM powa_functions
                 WHERE operation='snapshot' LOOP
      -- Call all of them, with no parameter
      RAISE debug 'fonction: %',funcname;
      BEGIN
        EXECUTE 'SELECT ' || quote_ident(funcname)||'()';
      EXCEPTION
        WHEN OTHERS THEN
          GET STACKED DIAGNOSTICS
              v_state   = RETURNED_SQLSTATE,
              v_msg     = MESSAGE_TEXT,
              v_detail  = PG_EXCEPTION_DETAIL,
              v_hint    = PG_EXCEPTION_HINT,
              v_context = PG_EXCEPTION_CONTEXT;
          RAISE warning 'powa_take_snapshot(): function "%" failed:
              state  : %
              message: %
              detail : %
              hint   : %
              context: %', funcname, v_state, v_msg, v_detail, v_hint, v_context;

      END;
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
        BEGIN
          EXECUTE 'SELECT ' || quote_ident(funcname)||'()';
        EXCEPTION
          WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_state   = RETURNED_SQLSTATE,
                v_msg     = MESSAGE_TEXT,
                v_detail  = PG_EXCEPTION_DETAIL,
                v_hint    = PG_EXCEPTION_HINT,
                v_context = PG_EXCEPTION_CONTEXT;
            RAISE warning 'powa_take_snapshot(): function "%" failed:
                state  : %
                message: %
                detail : %
                hint   : %
                context: %', funcname, v_state, v_msg, v_detail, v_hint, v_context;

        END;
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
        BEGIN
          EXECUTE 'SELECT ' || quote_ident(funcname)||'()';
        EXCEPTION
          WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_state   = RETURNED_SQLSTATE,
                v_msg     = MESSAGE_TEXT,
                v_detail  = PG_EXCEPTION_DETAIL,
                v_hint    = PG_EXCEPTION_HINT,
                v_context = PG_EXCEPTION_CONTEXT;
            RAISE warning 'powa_take_snapshot(): function "%" failed:
                state  : %
                message: %
                detail : %
                hint   : %
                context: %', funcname, v_state, v_msg, v_detail, v_hint, v_context;

        END;
      END LOOP;
      UPDATE powa_last_purge SET purgets=now();
    END IF;
END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_take_statements_snapshot() RETURNS void AS $PROC$
DECLARE
    result boolean;
    ignore_regexp text:='^[[:space:]]*(DEALLOCATE|BEGIN)'; -- Ignore deallocate or begin at beginning of statement
BEGIN
    -- In this function, we capture statements, and also aggregate counters by database
    -- so that the first screens of powa stay reactive even though there may be thousands
    -- of different statements
    RAISE DEBUG 'running powa_take_statements_snapshot';
    WITH capture AS(
            SELECT rolname, datname, pg_stat_statements.*
            FROM pg_stat_statements
            JOIN pg_authid ON (pg_stat_statements.userid=pg_authid.oid)
            JOIN pg_database ON (pg_stat_statements.dbid=pg_database.oid)
            WHERE pg_stat_statements.query !~* ignore_regexp
         ),
         missing_statements AS(
             INSERT INTO powa_statements (md5query,rolname,dbname,query)
               SELECT DISTINCT md5(rolname||datname||query),rolname,datname,query
               FROM capture c
               WHERE NOT EXISTS (SELECT 1
                                 FROM powa_statements
                                 WHERE powa_statements.md5query = md5(c.rolname||c.datname||c.query))

         ),
         by_query AS (

            INSERT INTO powa_statements_history_current
              SELECT md5(rolname||datname||query),
                     ROW(now(),sum(calls),sum(total_time),sum(rows),sum(shared_blks_hit),sum(shared_blks_read),
                        sum(shared_blks_dirtied),sum(shared_blks_written),sum(local_blks_hit),sum(local_blks_read),
                        sum(local_blks_dirtied),sum(local_blks_written),sum(temp_blks_read),sum(temp_blks_written),
                        sum(blk_read_time),sum(blk_write_time))::powa_statement_history_record AS record
              FROM capture
              GROUP BY md5(rolname||datname||query),now()
         ),
         by_database AS (

            INSERT INTO powa_statements_history_current_db
              SELECT datname,
                     ROW(now(),sum(calls),sum(total_time),sum(rows),sum(shared_blks_hit),sum(shared_blks_read),
                        sum(shared_blks_dirtied),sum(shared_blks_written),sum(local_blks_hit),sum(local_blks_read),
                        sum(local_blks_dirtied),sum(local_blks_written),sum(temp_blks_read),sum(temp_blks_written),
                        sum(blk_read_time),sum(blk_write_time))::powa_statement_history_record AS record
              FROM capture
              GROUP BY datname,now()
        )
        SELECT true::boolean INTO result; -- For now we don't care. What could we do on error except crash anyway?
END;
$PROC$ language plpgsql;

CREATE OR REPLACE FUNCTION powa_statements_purge() RETURNS void AS $PROC$
BEGIN
    RAISE DEBUG 'running powa_statements_purge';
    -- Delete obsolete datas. We only bother with already coalesced data
    DELETE FROM powa_statements_history WHERE upper(coalesce_range)< (now() - current_setting('powa.retention')::interval);
    DELETE FROM powa_statements_history_db WHERE upper(coalesce_range)< (now() - current_setting('powa.retention')::interval);
    -- FIXME maybe we should cleanup the powa_statements table ? But it will take a while: unnest all records...
END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_statements_aggregate() RETURNS void AS $PROC$
BEGIN
    RAISE DEBUG 'running powa_statements_aggregate';
    -- aggregate statements table
    LOCK TABLE powa_statements_history_current IN SHARE MODE; -- prevent any other update
    INSERT INTO powa_statements_history
      SELECT md5query,
           tstzrange(min((record).ts), max((record).ts),'[]'),
           array_agg(record)
      FROM powa_statements_history_current
     GROUP BY md5query;
    TRUNCATE powa_statements_history_current;
    -- aggregate db table
    LOCK TABLE powa_statements_history_current_db IN SHARE MODE; -- prevent any other update
    INSERT INTO powa_statements_history_db
      SELECT dbname,
           tstzrange(min((record).ts), max((record).ts),'[]'),
           array_agg(record)
      FROM powa_statements_history_current_db
     GROUP BY dbname;
    TRUNCATE powa_statements_history_current_db;
 END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_getstatdata (IN ts_start timestamptz, IN ts_end timestamptz)
    RETURNS TABLE (md5query text, query text, dbname text, total_calls numeric, total_runtime double precision,
    total_mesure_interval interval, total_blks_read numeric, total_blks_hit numeric,
    total_blk_read_time double precision, total_blk_write_time double precision)
AS
$$
BEGIN
    RETURN QUERY
    WITH statements_history AS (
        SELECT unnested.md5query,(unnested.records).*
        FROM (
            SELECT psh.md5query, psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history psh
            WHERE coalesce_range && tstzrange(ts_start,ts_end,'[]')
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
        int8larger(lead(shared_blks_hit) over (querygroup) - shared_blks_hit,0) blks_hit,
        float8larger(lead(blk_read_time) over (querygroup) - blk_read_time,0::double precision) blk_read_time,
        float8larger(lead(blk_write_time) over (querygroup) - blk_write_time,0::double precision) blk_write_time
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
    sum(s.blks_hit) AS total_blks_hit,
    sum(s.blk_read_time) AS total_blk_read_time,
    sum(s.blk_write_time) AS total_blk_write_time
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
            AND coalesce_range && tstzrange(ts_start, ts_end,'[]')
        ) AS unnested
        WHERE tstzrange(ts_start, ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT (record).*
        FROM powa_statements_history_current
        WHERE md5query=pmd5query
         AND tstzrange(ts_start, ts_end,'[]') @> (record).ts
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
    WITH statements_history AS (
        SELECT (unnested.records).*
        FROM (
            SELECT psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history_db psh
            WHERE dbname=p_datname
            AND coalesce_range && tstzrange(ts_start, ts_end,'[]')
        ) AS unnested
        WHERE tstzrange(ts_start, ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT (record).*
        FROM powa_statements_history_current_db
        WHERE dbname=p_datname
          AND tstzrange(ts_start, ts_end,'[]') @> (record).ts
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

CREATE OR REPLACE FUNCTION public.powa_getstatdata_query(ts_start timestamp with time zone, ts_end timestamp with time zone, pmd5query text)
 RETURNS TABLE(total_calls bigint, total_runtime numeric, total_blks_read bigint, total_blks_hit bigint, total_blks_dirtied bigint, total_blks_written bigint, total_temp_blks_read bigint, total_temp_blks_written bigint, total_blk_read_time double precision, total_blk_write_time double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH query_history AS (
        SELECT (unnested.records).*
        FROM (
            SELECT sth.md5query, sth.coalesce_range, unnest(records) AS records
            FROM powa_statements_history sth
            WHERE coalesce_range && tstzrange(ts_start,ts_end,'[]')
            AND sth.md5query=pmd5query
        ) AS unnested
        WHERE tstzrange(ts_start,ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT (psc.record).*
        FROM powa_statements_history_current psc
        WHERE tstzrange(ts_start,ts_end,'[]') @> (record).ts
        AND psc.md5query=pmd5query
    )
    SELECT 
    max(calls)-min(calls) AS total_calls,
    round((max(total_time)-min(total_time))::numeric,3) AS total_runtime,
    max(shared_blks_read)-min(shared_blks_read) AS total_blks_read,
    max(shared_blks_hit)-min(shared_blks_hit) AS total_blks_hit,
    max(shared_blks_dirtied)-min(shared_blks_dirtied) AS total_blks_dirtied,
    max(shared_blks_written)-min(shared_blks_written) AS total_blks_written,
    max(temp_blks_read)-min(temp_blks_read) AS total_temp_blks_read,
    max(temp_blks_written)-min(temp_blks_written) AS total_temp_blks_written,
    max(blk_read_time)-min(blk_read_time) AS total_blk_read_time,
    max(blk_write_time)-min(blk_write_time) AS total_blk_write_time
    FROM query_history h
    HAVING (max(calls)-min(calls)) > 0;
END
$function$
;


CREATE OR REPLACE FUNCTION public.powa_getstatdata_db(ts_start timestamp with time zone, ts_end timestamp with time zone, pdbname text)
 RETURNS TABLE(total_calls bigint, total_runtime numeric, total_blks_read bigint, total_blks_hit bigint, total_blks_dirtied bigint, total_blks_written bigint, total_temp_blks_read bigint, total_temp_blks_written bigint, total_blk_read_time double precision, total_blk_write_time double precision)
 LANGUAGE plpgsql
AS $function$
DECLARE min_ts timestamp with time zone;
DECLARE max_ts timestamp with time zone;
BEGIN
    -- To answer this really fast, we need to not unnest everything, but to get the first and last record for this database
    -- It will fail if stats were reset to 0, but preventing against that would be too costly
    SELECT INTO min_ts,max_ts min(lower(coalesce_range)),max(upper(coalesce_range))
    FROM powa_statements_history_db dbh
    WHERE dbh.dbname=pdbname
      AND coalesce_range && tstzrange(ts_start,ts_end,'[]');
    -- Use these two timestamps to only retrieve records which have them
    RETURN QUERY
    WITH db_history AS (
        SELECT (unnested1.records).*
        FROM (
            SELECT dbh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history_db dbh
            WHERE coalesce_range @> min_ts
            AND dbh.dbname=pdbname
        ) AS unnested1
        WHERE tstzrange(ts_start,ts_end,'[]') @> (unnested1.records).ts
        UNION ALL
        SELECT (unnested2.records).*
        FROM (
            SELECT dbh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history_db dbh
            WHERE coalesce_range @> max_ts
            AND dbh.dbname=pdbname
        ) AS unnested2
        WHERE tstzrange(ts_start,ts_end,'[]') @> (unnested2.records).ts
        UNION ALL
        SELECT (dbc.record).*
        FROM powa_statements_history_current_db dbc
        WHERE tstzrange(ts_start,ts_end,'[]') @> (dbc.record).ts
        AND dbc.dbname=pdbname
    )
    SELECT
    max(calls)-min(calls) AS total_calls,
    round((max(total_time)-min(total_time))::numeric,3) AS total_runtime,
    max(shared_blks_read)-min(shared_blks_read) AS total_blks_read,
    max(shared_blks_hit)-min(shared_blks_hit) AS total_blks_hit,
    max(shared_blks_dirtied)-min(shared_blks_dirtied) AS total_blks_dirtied,
    max(shared_blks_written)-min(shared_blks_written) AS total_blks_written,
    max(temp_blks_read)-min(temp_blks_read) AS total_temp_blks_read,
    max(temp_blks_written)-min(temp_blks_written) AS total_temp_blks_written,
    max(blk_read_time)-min(blk_read_time) AS total_blk_read_time,
    max(blk_write_time)-min(blk_write_time) AS total_blk_write_time
    FROM db_history h
    HAVING (max(calls)-min(calls)) > 0;
END
$function$
;

CREATE OR REPLACE FUNCTION public.powa_getstatdata_detailed_db(ts_start timestamp with time zone, ts_end timestamp with time zone, pdbname text)
 RETURNS TABLE(md5query text, query text, dbname text, total_calls bigint, total_runtime numeric, total_blks_read bigint, total_blks_hit bigint, total_blks_dirtied bigint, total_blks_written bigint, total_temp_blks_read bigint, total_temp_blks_written bigint, total_blk_read_time double precision, total_blk_write_time double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH statements_history AS (
        SELECT unnested.md5query,(unnested.records).*
        FROM (
            SELECT psh.md5query, psh.coalesce_range, unnest(records) AS records
            FROM powa_statements_history psh
            WHERE coalesce_range && tstzrange(ts_start,ts_end,'[]')
            AND psh.md5query IN (SELECT powa_statements.md5query FROM powa_statements WHERE powa_statements.dbname=pdbname)
        ) AS unnested
        WHERE tstzrange(ts_start,ts_end,'[]') @> (records).ts
        UNION ALL
        SELECT psc.md5query,(psc.record).*
        FROM powa_statements_history_current psc
        WHERE tstzrange(ts_start,ts_end,'[]') @> (record).ts
        AND psc.md5query IN (SELECT powa_statements.md5query FROM powa_statements WHERE powa_statements.dbname=pdbname)
    )
    SELECT s.md5query,
    s.query,
    s.dbname,
    max(h.calls)-min(h.calls) AS total_calls,
    round((max(h.total_time)-min(h.total_time))::numeric,3) AS total_runtime,
    max(h.shared_blks_read)-min(h.shared_blks_read) AS total_blks_read,
    max(h.shared_blks_hit)-min(h.shared_blks_hit) AS total_blks_hit,
    max(h.shared_blks_dirtied)-min(h.shared_blks_dirtied) AS total_blks_dirtied,
    max(h.shared_blks_written)-min(h.shared_blks_written) AS total_blks_written,
    max(h.temp_blks_read)-min(h.temp_blks_read) AS total_temp_blks_read,
    max(h.temp_blks_written)-min(h.temp_blks_written) AS total_temp_blks_written,
    max(h.blk_read_time)-min(h.blk_read_time) AS total_blk_read_time,
    max(h.blk_write_time)-min(h.blk_write_time) AS total_blk_write_time
    FROM statements_history h
    JOIN powa_statements s USING (md5query)
    WHERE s.dbname=pdbname
    GROUP BY s.md5query, s.query, s.dbname
    HAVING (max(h.calls)-min(h.calls)) > 0;
END
$function$
;CREATE OR REPLACE FUNCTION public.powa_stats_reset()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    TRUNCATE TABLE powa_statements_history;
    TRUNCATE TABLE powa_statements_history_current;
    TRUNCATE TABLE powa_statements_history_db;
    TRUNCATE TABLE powa_statements_history_current_db;
    TRUNCATE TABLE powa_statements;
    RETURN true;
END
$function$
;



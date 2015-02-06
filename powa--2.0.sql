-- complain if script is sourced in psql, rather than via CREATE EXTENSION
--\echo Use "CREATE EXTENSION powa" to load this file. \quit

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
    queryid bigint NOT NULL,
    dbid oid NOT NULL,
    userid oid NOT NULL,
    query text NOT NULL
);

ALTER TABLE ONLY powa_statements
    ADD CONSTRAINT powa_statements_pkey PRIMARY KEY (queryid, dbid, userid);

CREATE INDEX powa_statements_dbid_idx ON powa_statements(dbid);
CREATE INDEX powa_statements_userid_idx ON powa_statements(userid);


CREATE TABLE powa_statements_history (
    queryid bigint NOT NULL,
    dbid oid NOT NULL,
    userid oid NOT NULL,
    coalesce_range tstzrange NOT NULL,
    records powa_statement_history_record[] NOT NULL
);

CREATE INDEX powa_statements_history_query_ts ON powa_statements_history USING gist (queryid, coalesce_range);

CREATE TABLE powa_statements_history_db (
    dbid oid NOT NULL,
    coalesce_range tstzrange NOT NULL,
    records powa_statement_history_record[] NOT NULL
);

CREATE INDEX powa_statements_history_db_ts ON powa_statements_history_db USING gist (dbid, coalesce_range);

CREATE TABLE powa_statements_history_current (
    queryid bigint NOT NULL,
    dbid oid NOT NULL,
    userid oid NOT NULL,
    record powa_statement_history_record NOT NULL
);

CREATE TABLE powa_statements_history_current_db (
    dbid oid NOT NULL,
    record powa_statement_history_record NOT NULL
);

CREATE SEQUENCE powa_coalesce_sequence INCREMENT BY 1
  START WITH 1
  CYCLE;


CREATE TABLE powa_functions (
    module text NOT NULL,
    operation text NOT NULL,
    function_name text NOT NULL,
    added_manually boolean NOT NULL default true,
    CHECK (operation IN ('snapshot','aggregate','purge'))
);

INSERT INTO powa_functions (module, operation, function_name, added_manually) VALUES
    ('pg_stat_statements', 'snapshot', 'powa_statements_snapshot', false),
    ('pg_stat_statements', 'aggregate','powa_statements_aggregate', false),
    ('pg_stat_statements', 'purge', 'powa_statements_purge', false);

/* pg_stat_kcache integration - part 1 */

CREATE TYPE public.kcache_type AS (
    ts timestamptz,
    reads bigint,
    writes bigint,
    user_time double precision,
    system_time double precision
);

CREATE TABLE public.powa_kcache_metrics (
    coalesce_range tstzrange NOT NULL,
    queryid bigint NOT NULL,
    dbid oid NOT NULL,
    userid oid NOT NULL,
    metrics public.kcache_type[] NOT NULL,
    PRIMARY KEY (coalesce_range, queryid, dbid, userid)
);

CREATE INDEX ON public.powa_kcache_metrics (queryid);

CREATE TABLE public.powa_kcache_metrics_db (
    coalesce_range tstzrange NOT NULL,
    dbid oid NOT NULL,
    metrics public.kcache_type[] NOT NULL,
    PRIMARY KEY (coalesce_range, dbid)
);

CREATE TABLE public.powa_kcache_metrics_current (
    queryid bigint NOT NULL,
    dbid oid NOT NULL,
    userid oid NOT NULL,
    metrics kcache_type NULL NULL
);

CREATE TABLE public.powa_kcache_metrics_current_db (
    dbid oid NOT NULL,
    metrics kcache_type NULL NULL
);

/* end of pg_stat_kcache integration - part 1 */

/* pg_qualstats integration - part 1 */
CREATE TYPE public.qual_type AS (
    relid oid,
    attnum integer,
    opno oid,
    eval_type "char"
);

CREATE TYPE public.qual_values AS (
    constants text[],
    count bigint,
    nbfiltered bigint
);

CREATE TYPE powa_qualstats_history_item AS (
  ts timestamptz,
  count bigint,
  nbfiltered bigint
);

CREATE TABLE public.powa_qualstats_quals (
    qualid bigint,
    queryid bigint,
    dbid oid,
    userid oid,
    quals public.qual_type[],
    PRIMARY KEY (qualid, queryid, dbid, userid),
    FOREIGN KEY (queryid, dbid, userid) REFERENCES powa_statements(queryid, dbid, userid)
      MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.powa_qualstats_quals_history (
    qualid bigint,
    queryid bigint,
    dbid oid,
    userid oid,
    coalesce_range tstzrange,
    records powa_qualstats_history_item[],
    FOREIGN KEY (qualid, queryid, dbid, userid) REFERENCES public.powa_qualstats_quals (qualid, queryid, dbid, userid) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.powa_qualstats_quals_history_current (
    qualid bigint,
    queryid bigint,
    dbid oid,
    userid oid,
    ts timestamptz,
    count   bigint,
    nbfiltered bigint,
    FOREIGN KEY (qualid, queryid, dbid, userid) REFERENCES powa_qualstats_quals(qualid, queryid, dbid, userid)
      MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.powa_qualstats_constvalues_history (
    qualid bigint,
    queryid bigint,
    dbid oid,
    userid oid,
    coalesce_range tstzrange,
    most_filtering qual_values[],
    least_filtering qual_values[],
    most_executed qual_values[],
    FOREIGN KEY (qualid, queryid, dbid, userid) REFERENCES public.powa_qualstats_quals (qualid, queryid, dbid, userid) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.powa_qualstats_constvalues_history_current (
    qualid bigint,
    queryid bigint,
    dbid oid,
    userid oid,
    ts timestamptz,
    constvalues text[],
    count bigint,
    nbfiltered bigint,
    FOREIGN KEY (qualid, queryid, dbid, userid) REFERENCES public.powa_qualstats_quals (qualid, queryid, dbid, userid) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX ON powa_qualstats_constvalues_history USING gist (queryid, qualid, coalesce_range);
CREATE INDEX ON powa_qualstats_constvalues_history (qualid, queryid);
CREATE INDEX ON powa_qualstats_quals(queryid);


/* end of pg_qualstats_integration - part 1 */

-- Mark all of powa's tables as "to be dumped"
SELECT pg_catalog.pg_extension_config_dump('powa_statements','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history_db','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history_current','');
SELECT pg_catalog.pg_extension_config_dump('powa_statements_history_current_db','');
SELECT pg_catalog.pg_extension_config_dump('powa_functions','WHERE added_manually');
SELECT pg_catalog.pg_extension_config_dump('powa_kcache_metrics','');
SELECT pg_catalog.pg_extension_config_dump('powa_kcache_metrics_db','');
SELECT pg_catalog.pg_extension_config_dump('powa_kcache_metrics_current','');
SELECT pg_catalog.pg_extension_config_dump('powa_kcache_metrics_current_db','');
SELECT pg_catalog.pg_extension_config_dump('powa_qualstats_quals','');
SELECT pg_catalog.pg_extension_config_dump('powa_qualstats_quals_history','');
SELECT pg_catalog.pg_extension_config_dump('powa_qualstats_quals_history_current','');
SELECT pg_catalog.pg_extension_config_dump('powa_qualstats_constvalues_history','');
SELECT pg_catalog.pg_extension_config_dump('powa_qualstats_constvalues_history_current','');

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

    -- Coalesce datas if needed
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
      UPDATE powa_last_purge SET purgets = now();
    END IF;
END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION powa_statements_snapshot() RETURNS void AS $PROC$
DECLARE
    result boolean;
    ignore_regexp text:='^[[:space:]]*(BEGIN)'; -- Ignore begin at beginning of statement
BEGIN
    -- In this function, we capture statements, and also aggregate counters by database
    -- so that the first screens of powa stay reactive even though there may be thousands
    -- of different statements
    RAISE DEBUG 'running powa_statements_snapshot';
    WITH capture AS(
        SELECT pg_stat_statements.*
        FROM pg_stat_statements
        WHERE pg_stat_statements.query !~* ignore_regexp
    ),

    missing_statements AS(
        INSERT INTO powa_statements (queryid, dbid, userid, query)
            SELECT queryid, dbid, userid, query
            FROM capture c
            WHERE NOT EXISTS (SELECT 1
                              FROM powa_statements ps
                              WHERE ps.queryid = c.queryid
                              AND ps.dbid = c.dbid
                              AND ps.userid = c.userid
            )
    ),

    by_query AS (
        INSERT INTO powa_statements_history_current
            SELECT queryid, dbid, userid,
            ROW(
                now(), calls, total_time, rows, shared_blks_hit, shared_blks_read,
                shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read,
                local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written,
                blk_read_time, blk_write_time
            )::powa_statement_history_record AS record
            FROM capture
    ),

    by_database AS (
        INSERT INTO powa_statements_history_current_db
            SELECT dbid,
            ROW(
                now(), sum(calls), sum(total_time), sum(rows), sum(shared_blks_hit), sum(shared_blks_read),
                sum(shared_blks_dirtied), sum(shared_blks_written), sum(local_blks_hit), sum(local_blks_read),
                sum(local_blks_dirtied), sum(local_blks_written), sum(temp_blks_read), sum(temp_blks_written),
                sum(blk_read_time), sum(blk_write_time)
            )::powa_statement_history_record AS record
            FROM capture
            GROUP BY dbid
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
        SELECT queryid, dbid, userid,
            tstzrange(min((record).ts), max((record).ts),'[]'),
            array_agg(record)
        FROM powa_statements_history_current
        GROUP BY queryid, dbid, userid;

    TRUNCATE powa_statements_history_current;

    -- aggregate db table
    LOCK TABLE powa_statements_history_current_db IN SHARE MODE; -- prevent any other update

    INSERT INTO powa_statements_history_db
        SELECT dbid,
            tstzrange(min((record).ts), max((record).ts),'[]'),
            array_agg(record)
        FROM powa_statements_history_current_db
        GROUP BY dbid;

    TRUNCATE powa_statements_history_current_db;
 END;
$PROC$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.powa_stats_reset()
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
END;
$function$;

/* pg_stat_kcache integration - part 2 */

/*
 * register pg_stat_kcache extension
 */
CREATE OR REPLACE function public.powa_kcache_register() RETURNS bool AS
$_$
DECLARE
    v_func_present bool;
    v_ext_present bool;
BEGIN
    SELECT COUNT(*) = 1 INTO v_ext_present FROM pg_extension WHERE extname = 'pg_stat_kcache';

    IF ( v_ext_present ) THEN
        SELECT COUNT(*) > 0 INTO v_func_present FROM public.powa_functions WHERE module = 'pg_stat_kcache';
        IF ( NOT v_func_present) THEN
            INSERT INTO powa_functions (module, operation, function_name, added_manually)
            VALUES ('pg_stat_kcache', 'snapshot', 'powa_kcache_snapshot', true),
                   ('pg_stat_kcache', 'aggregate', 'powa_kcache_aggregate', true),
                   ('pg_stat_kcache', 'purge', 'powa_kcache_purge', true);
        END IF;
    END IF;

    RETURN true;
END;
$_$
language plpgsql;

/*
 * unregister pg_stat_kcache extension
 */
CREATE OR REPLACE function public.powa_kcache_unregister() RETURNS bool AS
$_$
BEGIN
    DELETE FROM public.powa_functions WHERE module = 'pg_stat_kcache';
    RETURN true;
END;
$_$
language plpgsql;

/*
 * powa_kcache snapshot collection.
 */
CREATE OR REPLACE FUNCTION powa_kcache_snapshot() RETURNS void as $PROC$
DECLARE
  result bool;
BEGIN
    RAISE DEBUG 'running powa_kcache_snapshot';

    WITH capture AS (
        SELECT *
        FROM pg_stat_kcache()
    ),

    by_query AS (
        INSERT INTO powa_kcache_metrics_current (queryid, dbid, userid, metrics)
            SELECT queryid, dbid, userid, (now(), reads, writes, user_time, system_time)::kcache_type
            FROM capture
    ),

    by_database AS (
        INSERT INTO powa_kcache_metrics_current_db (dbid, metrics)
            SELECT dbid, (now(), sum(reads), sum(writes), sum(user_time), sum(system_time))::kcache_type
            FROM capture
            GROUP BY dbid
    )

    SELECT true into result;
END
$PROC$ language plpgsql;

/*
 * powa_kcache aggregation
 */
CREATE OR REPLACE FUNCTION powa_kcache_aggregate() RETURNS void AS $PROC$
DECLARE
  result bool;
BEGIN
    RAISE DEBUG 'running powa_kcache_aggregate';

    -- aggregate metrics table
    LOCK TABLE powa_kcache_metrics_current IN SHARE MODE; -- prevent any other update

    INSERT INTO powa_kcache_metrics (coalesce_range, queryid, dbid, userid, metrics)
        SELECT tstzrange(min((metrics).ts), max((metrics).ts)),
        queryid, dbid, userid, array_agg(metrics)
        FROM powa_kcache_metrics_current
        GROUP BY queryid, dbid, userid;

    TRUNCATE powa_kcache_metrics_current;

    -- aggregate metrics_db table
    LOCK TABLE powa_kcache_metrics_current_db IN SHARE MODE; -- prevent any other update

    INSERT INTO powa_kcache_metrics_db (coalesce_range, dbid, metrics)
        SELECT tstzrange(min((metrics).ts), max((metrics).ts)),
        dbid, array_agg(metrics)
        FROM powa_kcache_metrics_current_db
        GROUP BY dbid;

    TRUNCATE powa_kcache_metrics_current_db;
END
$PROC$ language plpgsql;

/*
 * powa_kcache purge
 */
CREATE OR REPLACE FUNCTION powa_kcache_purge() RETURNS void as $PROC$
BEGIN
    RAISE DEBUG 'running powa_kcache_purge';

    DELETE FROM powa_kcache_metrics WHERE upper(coalesce_range) < (now() - current_setting('powa.retention')::interval);
    DELETE FROM powa_kcache_metrics_db WHERE upper(coalesce_range) < (now() - current_setting('powa.retention')::interval);
END;
$PROC$ language plpgsql;

-- By default, try to register pg_stat_kcache, in case it's alreay here
SELECT * FROM public.powa_kcache_register();

/* end of pg_stat_kcache integration - part 2 */

/* pg_qualstats integration - part 2 */

/*
 * powa_qualstats_register
 */
CREATE OR REPLACE function public.powa_qualstats_register() RETURNS bool AS
$_$
DECLARE
    v_func_present bool;
    v_ext_present bool;
BEGIN
    SELECT COUNT(*) = 1 INTO v_ext_present FROM pg_extension WHERE extname = 'pg_qualstats';

    IF ( v_ext_present) THEN
        SELECT COUNT(*) > 0 INTO v_func_present FROM public.powa_functions WHERE function_name IN ('powa_qualstats_snapshot', 'powa_qualstats_aggregate', 'powa_qualstats_purge');
        IF ( NOT v_func_present) THEN
            INSERT INTO powa_functions (module, operation, function_name, added_manually)
            VALUES ('pg_qualstats', 'snapshot', 'powa_qualstats_snapshot', false),
                   ('pg_qualstats', 'aggregate', 'powa_qualstats_aggregate', false),
                   ('pg_qualstats', 'purge', 'powa_qualstats_purge', false);
        END IF;
    END IF;

    RETURN true;
END;
$_$
language plpgsql;

/*
 * powa_qualstats utility view for aggregating constvalues
 */
CREATE OR REPLACE VIEW powa_qualstats_aggregate_constvalues_current AS
WITH consts AS (
  SELECT qualid, queryid, dbid, userid, min(ts) as mints, max(ts) as maxts, sum(nbfiltered) as nbfiltered,
  sum(count) as count, constvalues
  FROM powa_qualstats_constvalues_history_current
  GROUP BY qualid, queryid, dbid, userid, constvalues
),
groups AS (
  SELECT qualid, queryid, dbid, userid, tstzrange(min(mints), max(maxts))
  FROM consts
  GROUP BY qualid, queryid, dbid, userid
)
SELECT *
FROM groups,
LATERAL (
  SELECT array_agg(constvalues) as mf
  FROM (
    SELECT (constvalues, nbfiltered, count)::qual_values as constvalues
    FROM consts
    WHERE consts.qualid = groups.qualid AND consts.queryid = groups.queryid
    AND consts.dbid = groups.dbid AND consts.userid = groups.userid
    ORDER BY CASE WHEN count = 0 THEN 0 ELSE nbfiltered / count::numeric END DESC
    LIMIT 20
  ) s
) as mf,
LATERAL (
  SELECT array_agg(constvalues) as lf
  FROM (
    SELECT (constvalues, nbfiltered, count)::qual_values as constvalues
    FROM consts
    WHERE consts.qualid = groups.qualid AND consts.queryid = groups.queryid
    AND consts.dbid = groups.dbid AND consts.userid = groups.userid
    ORDER BY CASE WHEN count = 0 THEN 0 ELSE nbfiltered / count::numeric END DESC
    LIMIT 20
  ) s
) as lf,
LATERAL (
  SELECT array_agg(constvalues) as me
  FROM (
    SELECT (constvalues, nbfiltered, count)::qual_values as constvalues
    FROM consts
    WHERE consts.qualid = groups.qualid AND consts.queryid = groups.queryid
    AND consts.dbid = groups.dbid AND consts.userid = groups.userid
    ORDER BY count desc
    LIMIT 20
  ) s
) as me;


CREATE OR REPLACE FUNCTION powa_qualstats_snapshot() RETURNS void as $PROC$
DECLARE
  result bool;
BEGIN
  RAISE DEBUG 'running powa_qualstats_snaphot';
  WITH capture AS (
    SELECT pgqs.*, s.query
    FROM pg_qualstats_by_query pgqs
    JOIN powa_statements s USING(queryid, dbid, userid)
  ),
  missing_quals AS (
      INSERT INTO powa_qualstats_quals (qualid, queryid, dbid, userid, quals)
        SELECT DISTINCT qs.qualnodeid, qs.queryid, qs.dbid, qs.userid, array_agg(DISTINCT q::qual_type)
        FROM capture qs,
        LATERAL (SELECT (unnest(quals)).*) as q
        WHERE NOT EXISTS (
          SELECT 1
          FROM powa_qualstats_quals nh
          WHERE nh.qualid = qs.qualnodeid AND nh.queryid = qs.queryid
            AND nh.dbid = qs.dbid AND nh.userid = qs.userid
        )
        GROUP BY qualnodeid, queryid, dbid, userid
      RETURNING *
  ),
  by_qual AS (
      INSERT INTO powa_qualstats_quals_history_current (qualid, queryid, dbid, userid, ts, count, nbfiltered)
      SELECT qs.qualnodeid, qs.queryid, qs.dbid, qs.userid, now(), sum(count), sum(nbfiltered)
        FROM capture as qs
        GROUP BY qualnodeid, qs.queryid, qs.dbid, qs.userid
      RETURNING *
  ),
  by_qual_with_const AS (
      INSERT INTO powa_qualstats_constvalues_history_current(qualid, queryid, dbid, userid, ts, count, nbfiltered, constvalues)
      SELECT qualnodeid, qs.queryid, qs.dbid, qs.userid, now(), count, nbfiltered, constvalues
      FROM capture as qs
  )
  SELECT true into result;
  PERFORM pg_qualstats_reset();
END
$PROC$ language plpgsql;

/*
 * powa_qualstats aggregate
 */
CREATE OR REPLACE FUNCTION powa_qualstats_aggregate() RETURNS void AS $PROC$
DECLARE
  result bool;
BEGIN
  RAISE DEBUG 'running powa_qualstats_aggregate';
  LOCK TABLE powa_qualstats_constvalues_history_current IN SHARE MODE;
  LOCK TABLE powa_qualstats_quals_history_current IN SHARE MODE;
  INSERT INTO powa_qualstats_constvalues_history (
    qualid, queryid, dbid, userid, coalesce_range, most_filtering, least_filtering, most_executed)
    SELECT * FROM powa_qualstats_aggregate_constvalues_current;
  INSERT INTO powa_qualstats_quals_history (qualid, queryid, dbid, userid, coalesce_range, records)
    SELECT qualid, queryid, dbid, userid, tstzrange(min(ts), max(ts)), array_agg((ts, count, nbfiltered)::powa_qualstats_history_item)
    FROM powa_qualstats_quals_history_current
    GROUP BY qualid, queryid, dbid, userid;
  TRUNCATE powa_qualstats_constvalues_history_current;
  TRUNCATE powa_qualstats_quals_history_current;
END
$PROC$ language plpgsql;

/*
 * powa_qualstats_purge
 */
CREATE OR REPLACE FUNCTION powa_qualstats_purge() RETURNS void as $PROC$
BEGIN
  RAISE DEBUG 'running powa_qualstats_purge';
  DELETE FROM powa_qualstats_constvalues_history WHERE upper(coalesce_range) < (now() - current_setting('powa.retention')::interval);
  DELETE FROM powa_qualstats_quals_history WHERE upper(coalesce_range) < (now() - current_setting('powa.retention')::interval);
END;
$PROC$ language plpgsql;

/*
 * powa_qualstats_unregister
 */
CREATE OR REPLACE function public.powa_qualstats_unregister() RETURNS bool AS
$_$
BEGIN
    DELETE FROM public.powa_functions WHERE function_name IN ('powa_qualstats_snapshot', 'powa_qualstats_aggregate', 'powa_qualstats_purge');
    RETURN true;
END;
$_$
language plpgsql;

SELECT * FROM public.powa_qualstats_register();

/* end of pg_qualstats_integration - part 2 */

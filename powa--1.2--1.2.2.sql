-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION powa UPDATE" to load this file. \quit

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;
SET search_path = public, pg_catalog;

CREATE OR REPLACE FUNCTION powa_take_statements_snapshot() RETURNS void AS $PROC$
DECLARE
    result boolean;
    -- Ignore deallocate, begin or 2PC keywords at beginning of statement
    ignore_regexp text:='^[[:space:]]*(DEALLOCATE|BEGIN|PREPARE TRANSACTION|COMMIT PREPARED|ROLLBACK PREPARED)';
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

#include "postgres.h"

/* For a bgworker */
#include "miscadmin.h"
#include "postmaster/bgworker.h"
#include "storage/ipc.h"
#include "storage/latch.h"
#include "storage/lwlock.h"
#include "storage/proc.h"
#include "storage/shmem.h"

/* Access a database */
#include "access/xact.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "lib/stringinfo.h"
#include "utils/builtins.h"
#include "utils/snapmgr.h"

/* Some catalog elements */
#include "catalog/pg_type.h"
#include "utils/timestamp.h"

/* There is a GUC */
#include "utils/guc.h"

PG_MODULE_MAGIC;

void        _PG_init(void);
void        die_on_too_small_frequency(void);


static bool got_sigterm = false;

static void powa_main(Datum main_arg);
static void powa_sigterm(SIGNAL_ARGS);
static void powa_sighup(SIGNAL_ARGS);

static int  powa_frequency;
static int  min_powa_frequency = 5000;
static int  powa_retention;
static int  powa_coalesce;
static char *powa_database = NULL;

void die_on_too_small_frequency(void)
{
    if (powa_frequency > 0 && powa_frequency < min_powa_frequency)
      {
          elog(LOG, "POWA frequency cannot be smaller than %i milliseconds",
               min_powa_frequency);
          exit(1);
      }
}

void _PG_init(void)
{

    BackgroundWorker worker;

    DefineCustomIntVariable("powa.frequency",
                            "Defines the frequency in seconds of the snapshots",
                            NULL,
                            &powa_frequency,
                            300000,
                            -1,
                            INT_MAX / 1000,
                            PGC_SUSET, GUC_UNIT_MS, NULL, NULL, NULL);

    DefineCustomIntVariable("powa.coalesce",
                            "Defines the amount of records to group together in the table (more compact)",
                            NULL,
                            &powa_coalesce,
                            100, 5, INT_MAX, PGC_SUSET, 0, NULL, NULL, NULL);

    DefineCustomIntVariable("powa.retention",
                            "Automatically purge data older than N minutes",
                            NULL,
                            &powa_retention,
                            HOURS_PER_DAY * MINS_PER_HOUR,
                            0,
                            INT_MAX / SECS_PER_MINUTE,
                            PGC_SUSET, GUC_UNIT_MIN, NULL, NULL, NULL);

    DefineCustomStringVariable("powa.database",
                               "Defines the database of the workload repository",
                               NULL,
                               &powa_database,
                               "powa", PGC_POSTMASTER, 0, NULL, NULL, NULL);
    /*
       Register the worker processes
     */
    worker.bgw_flags =
        BGWORKER_SHMEM_ACCESS | BGWORKER_BACKEND_DATABASE_CONNECTION;
    worker.bgw_start_time = BgWorkerStart_RecoveryFinished;     /* Must write to the database */
    worker.bgw_main = powa_main;
    snprintf(worker.bgw_name, BGW_MAXLEN, "powa");
    worker.bgw_restart_time = 10;
    worker.bgw_main_arg = (Datum) 0;
#if (PG_VERSION_NUM >= 90400)
    worker.bgw_notify_pid = 0;
#endif
    RegisterBackgroundWorker(&worker);
}


static void powa_main(Datum main_arg)
{
    char       *q1 = "SELECT powa_take_snapshot()";
    static char *q2 = "SET application_name = 'POWA collector'";
    instr_time  begin;
    instr_time  end;
    long        time_to_wait;

    die_on_too_small_frequency();
    /*
       Set up signal handlers, then unblock signalsl
     */
    pqsignal(SIGHUP, powa_sighup);
    pqsignal(SIGTERM, powa_sigterm);

    BackgroundWorkerUnblockSignals();

    /*
       We only connect when powa_frequency >0. If not, powa has been deactivated
     */
    if (powa_frequency < 0)
    {
        elog(LOG, "POWA is deactivated (powa.frequency = %i), exiting",
             powa_frequency);
        exit(1);
    }
    // We got here: it means powa_frequency > 0. Let's connect


    /*
       Connect to POWA database
     */
    BackgroundWorkerInitializeConnection(powa_database, NULL);

    elog(LOG, "POWA connected to %s", powa_database);

    StartTransactionCommand();
    SetCurrentStatementStartTimestamp();
    SPI_connect();
    PushActiveSnapshot(GetTransactionSnapshot());
    SPI_execute(q2, false, 0);
    SPI_finish();
    PopActiveSnapshot();
    CommitTransactionCommand();

    /*
       let's store the current time. It will be used to
       calculate a quite stable interval between each measure
     */
    while (!got_sigterm)
    {
        /*
           We can get here with a new value of powa_frequency
           because of a reload. Let's suicide to disconnect
           if this value is <0
         */
        if (powa_frequency < 0)
        {
            elog(LOG, "POWA exits to disconnect from the database now");
            exit(1);
        }
        INSTR_TIME_SET_CURRENT(begin);
        ResetLatch(&MyProc->procLatch);
        SetCurrentStatementStartTimestamp();
        StartTransactionCommand();
        SPI_connect();
        PushActiveSnapshot(GetTransactionSnapshot());
        SPI_execute(q1, false, 0);
        SPI_finish();
        PopActiveSnapshot();
        CommitTransactionCommand();
        INSTR_TIME_SET_CURRENT(end);
        INSTR_TIME_SUBTRACT(end, begin);
        /*
           Wait powa.frequency, compensate for work time of last snapshot
         */
        /*
           If we got off schedule (because of a compact or delete,
           just do another operation right now
         */
        time_to_wait = powa_frequency - INSTR_TIME_GET_MILLISEC(end);
        elog(DEBUG1, "Waiting for %li milliseconds", time_to_wait);
        if (time_to_wait > 0)
        {

            WaitLatch(&MyProc->procLatch,
                      WL_LATCH_SET | WL_TIMEOUT | WL_POSTMASTER_DEATH,
                      time_to_wait);
        }
    }
    proc_exit(0);
}


static void powa_sigterm(SIGNAL_ARGS)
{
    int         save_errno = errno;

    got_sigterm = true;
    if (MyProc)
        SetLatch(&MyProc->procLatch);
    errno = save_errno;
}

static void powa_sighup(SIGNAL_ARGS)
{
    ProcessConfigFile(PGC_SIGHUP);
    die_on_too_small_frequency();
}

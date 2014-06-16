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

void _PG_init(void);

static bool got_sigterm = false;

static void powa_main(Datum main_arg);
static void powa_sigterm(SIGNAL_ARGS);
static void powa_sighup(SIGNAL_ARGS);

static int powa_frequency;
static int powa_retention;
static int powa_coalesce;
static char *powa_database = NULL;

void
_PG_init(void)
{

	BackgroundWorker worker;

        DefineCustomIntVariable("powa.frequency",
          "Defines the frequency in seconds of the snapshots",
                                                        NULL,
                                                        &powa_frequency,
                                                        300000,
                                                        5000,
                                                        INT_MAX/1000,
                                                        PGC_SUSET,
                                                        GUC_UNIT_MS,
                                                        NULL,
                                                        NULL,
                                                        NULL);

        DefineCustomIntVariable("powa.coalesce",
          "Defines the amount of records to group together in the table (more compact)",
                                                        NULL,
                                                        &powa_coalesce,
                                                        100,
                                                        5,
                                                        INT_MAX,
                                                        PGC_SUSET,
                                                        0,
                                                        NULL,
                                                        NULL,
                                                        NULL);

        DefineCustomIntVariable("powa.retention",
          "Automatically purge data older than N minutes",
                                                        NULL,
                                                        &powa_retention,
                                                        HOURS_PER_DAY * MINS_PER_HOUR,
                                                        0,
                                                        INT_MAX / SECS_PER_MINUTE,
                                                        PGC_SUSET,
                                                        GUC_UNIT_MIN,
                                                        NULL,
                                                        NULL,
                                                        NULL);

        DefineCustomStringVariable("powa.database",
          "Defines the database of the workload repository",
                                                        NULL,
                                                        &powa_database,
                                                        "powa",
                                                        PGC_POSTMASTER,
							0,
                                                        NULL,
                                                        NULL,
                                                        NULL);
	
	/* Register the worker processes */
	worker.bgw_flags = BGWORKER_SHMEM_ACCESS|BGWORKER_BACKEND_DATABASE_CONNECTION;
	worker.bgw_start_time = BgWorkerStart_RecoveryFinished; /* Must write to the database */
	worker.bgw_main = powa_main;
	snprintf(worker.bgw_name,BGW_MAXLEN,"powa");
	worker.bgw_restart_time = 10;
	worker.bgw_main_arg = (Datum) 0;
#if (PG_VERSION_NUM >= 90400)
	worker.bgw_notify_pid=0;
#endif
	RegisterBackgroundWorker(&worker);
}


static void
powa_main(Datum main_arg)
{
	char* q1 = "SELECT powa_take_snapshot()";
        static char* q2 = "SET application_name = 'POWA collector'";
	instr_time begin;
	instr_time end;

	/* Set up signal handlers, then unblock signalsl */
	pqsignal(SIGHUP, powa_sighup);
	pqsignal(SIGTERM, powa_sigterm);

	BackgroundWorkerUnblockSignals();

	/* Connect to POWA database */
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

	/* let's store the current time. It will be used to
	   calculate a quite stable interval between each measure */
	while (!got_sigterm)
	{
		INSTR_TIME_SET_CURRENT(begin);
		ResetLatch(&MyProc->procLatch);
		StartTransactionCommand();
		SetCurrentStatementStartTimestamp();
		SPI_connect();
		PushActiveSnapshot(GetTransactionSnapshot());
		SPI_execute(q1, false, 0);
		SPI_finish();
		PopActiveSnapshot();
		CommitTransactionCommand();
		INSTR_TIME_SET_CURRENT(end);
		INSTR_TIME_SUBTRACT(end,begin);
		/* Wait powa.frequency, compensate for work time of last snapshot */
                /* If we got off schedule (because of a compact or delete,
                   just do another operation right now */
                if (powa_frequency-INSTR_TIME_GET_MILLISEC(end) >0)
                {
		     WaitLatch(&MyProc->procLatch,
		                WL_LATCH_SET | WL_TIMEOUT | WL_POSTMASTER_DEATH,
		                powa_frequency-INSTR_TIME_GET_MILLISEC(end));
                }
	}
	proc_exit(0);
}


static void
powa_sigterm(SIGNAL_ARGS)
{
	int save_errno = errno;
	got_sigterm = true;
	if (MyProc)
		SetLatch(&MyProc->procLatch);
	errno = save_errno;
}

static void
powa_sighup(SIGNAL_ARGS)
{
	{
		ProcessConfigFile(PGC_SIGHUP);
	}
}

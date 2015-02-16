.. _install:

PostgreSQL Workload Analyzer detailled installation guide
=========================================================

Read :ref:`the introduction <index>` for further details about PoWA.

PoWA requires PostgreSQL 9.3 or more.

The following documentation describes the detailed installation steps to install PoWA.


Download PoWA from the website
------------------------------

.. code-block:: bash

    wget https://github.com/dalibo/powa/archive/REL_1_2.zip

Unpack the downloaded file
--------------------------

.. code-block:: bash

    cd /usr/src
    unzip powa-REL_1_1.zip

Compile and install the software
--------------------------------

Before proceeding, be sure to have a compiler installed and the appropriate PostgreSQL development packages. Something like

.. code-block:: bash

    apt-get install postgresql-server-dev-9.3

or

.. code-block:: bash

    yum install postgresql93-devel

Then:

.. code-block:: bash

    cd /usr/src/powa-REL_1_2
    make

If everything goes fine, you will have this kind of output :

.. code-block:: bash

    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -g -fpic -I. -I. -I/home/thomas/postgresql/postgresql-9.3.4/include/server -I/home/thomas/postgresql/postgresql-9.3.4/include/internal -D_GNU_SOURCE -I/usr/include/libxml2   -c -o powa.o powa.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -g -fpic -L/home/thomas/postgresql/postgresql-9.3.4/lib -Wl,--as-needed -Wl,-rpath,'/home/thomas/postgresql/postgresql-9.3.4/lib',--enable-new-dtags  -shared -o powa.so powa.o

Install the software :

This step has to be made with the user that has installed PostgreSQL. If you have used a package, it will be certainly be root. If so:

.. code-block:: bash

    sudo make install

Else, sudo into the user that owns your PostgreSQL executables, and

.. code-block:: bash

    make install

It should output something like the following :

.. code-block:: bash

  /bin/mkdir -p '/usr/pgsql-9.3/share/extension'
  /bin/mkdir -p '/usr/pgsql-9.3/share/extension'
  /bin/mkdir -p '/usr/pgsql-9.3/lib'
  /bin/mkdir -p '/usr/pgsql-9.3/share/doc/extension'
  /usr/bin/install -c -m 644 ./powa.control '/usr/pgsql-9.3/share/extension/'
  /usr/bin/install -c -m 644 ./powa--1.0.sql ./powa--1.1.sql ./powa--1.2.sql ./powa--1.1--1.2.sql  '/usr/pgsql-9.3/share/extension/'
  /usr/bin/install -c -m 755  powa.so '/usr/pgsql-9.3/postgresql-9.3.4/lib/'
  /usr/bin/install -c -m 644 ./README.md '/usr/pgsql-9.3/share/doc/extension/'


Create a PoWA database and create required extensions
-----------------------------------------------------

Note: if you are upgrading from a previous PoWA release, please consult the
upgrading section at the end of this file.


First, connect to PostgreSQL as administrator :

.. code-block:: sql

    bash-4.1$ psql
    psql (9.3.5)
    Type "help" for help.
    postgres=# create database powa;
    CREATE DATABASE
    postgres=# \c powa
    You are now connected to database "powa" as user "postgres".
    powa=# create extension pg_stat_statements ;
    CREATE EXTENSION
    powa=# create extension btree_gist ;
    CREATE EXTENSION
    powa=# create extension powa;
    CREATE EXTENSION
    powa=# \dt
                            List of relations
      Schema |              Name               | Type  |  Owner
    --------+---------------------------------+-------+----------
      public | powa_functions                  | table | postgres
      public | powa_last_aggregation           | table | postgres
      public | powa_last_purge                 | table | postgres
      public | powa_statements                 | table | postgres
      public | powa_statements_history         | table | postgres
      public | powa_statements_history_current | table | postgres
    (6 rows)


Modify the configuration files
------------------------------

In `postgresql.conf`:

Change the `shared_preload_libraries` appropriately :

.. code-block:: bash

    shared_preload_libraries = 'powa,pg_stat_statements'# (change requires restart)

If possible (check with pg_test_timing), activate track_io_timing on your instance, in postgresql.conf :

.. code-block:: bash

    track_io_timing = on

Other GUC variables are available. Read :ref:`the main documentation <index>` for further details.

In `pg_hba.conf`:

Add an entry if needed for the PostgreSQL user(s) that need to connect on the GUI.
For instance, assuming a `local connection` on database `powa`, allowing any user:

`host    powa    all     127.0.0.1/32    md5`

Restart PostgreSQL
------------------

As root, run the following command :

.. code-block:: bash

    service postgresql-9.3 restart

PostgreSQL should output the following messages in the log files :

.. code-block:: bash

    2014-07-25 03:48:20 IST LOG:  registering background worker "powa"
    2014-07-25 03:48:20 IST LOG:  loaded library "powa"
    2014-07-25 03:48:20 IST LOG:  loaded library "pg_stat_statements"

Upgrading from a previous version of PoWA
-----------------------------------------

If you already have an older PoWA installation, you can simply upgrade PoWA with the following steps :

First, connect to PostgreSQL as administrator and update the extension :

.. code-block:: bash

    bash-4.1$ psql powa
    psql (9.3.5)
    Type "help" for help.
    powa=# ALTER EXTENSION powa UPDATE ;
    ALTER EXTENSION

Next, you will need to restart PostgreSQL in order to take account of the
updated background worker. As root, run the following command :

.. code-block:: bash

    service postgresql-9.3 restart

Finally, adapt the ui/powa.conf file to suit the new format. For instance,

* if coming from powa 1.1


  .. code-block:: bash

    "database" : {
        "dsn"     : "dbi:Pg:database=powa;host=127.0.0.1;port=5432",
        "options"  : {
            "AutoCommit" : 0,
            "pg_enable_utf8" : 1
        }
    },


must be changed to

  .. code-block:: bash

    "servers" : {
        "main" : {
            "dbname"   : "powa",
            "host"     : "127.0.0.1",
            "port"     : "5432"
        }
    },

* if coming from powa 1.2

  .. code-block:: bash

    "database" : {
        "dbname"   : "powa",
        "host"     : "127.0.0.1",
        "port"     : "5432",
        "options"  : {
            "AutoCommit" : 0,
            "pg_enable_utf8" : 1
        }
    },

must be changed to

  .. code-block:: bash

    "servers" : {
        "main" : {
            "dbname"   : "powa",
            "host"     : "127.0.0.1",
            "port"     : "5432"
        }
    },

Set-up the UI
-------------


Read :ref:`the ui documentation <ui>` for details.


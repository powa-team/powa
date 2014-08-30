PostgreSQL Workload Analyzer detailled installation guide
=========================================================

Read [README.md](https://github.com/dalibo/powa/blob/master/README.md) for further details about PoWA.

PoWA requires PostgreSQL 9.3 or more.

The following documentation describes the detailed installation steps to install PoWA.


Download PoWA from the website
------------------------------

```
wget https://github.com/dalibo/powa/archive/REL_1_1.zip
```

Unpack the downloaded file
--------------------------

```
cd /usr/src
unzip powa-REL_1_1.zip
```

Compile and install the software
--------------------------------

Before proceeding, be sure to have a compiler installed and the appropriate PostgreSQL development packages.

```
cd /usr/src/powa-REL_1_1
make
```

If everything goes fine, you will have this kind of output :
```
gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -g -fpic -I. -I. -I/home/thomas/postgresql/postgresql-9.3.4/include/server -I/home/thomas/postgresql/postgresql-9.3.4/include/internal -D_GNU_SOURCE -I/usr/include/libxml2   -c -o powa.o powa.c
gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -g -fpic -L/home/thomas/postgresql/postgresql-9.3.4/lib -Wl,--as-needed -Wl,-rpath,'/home/thomas/postgresql/postgresql-9.3.4/lib',--enable-new-dtags  -shared -o powa.so powa.o
```

Install the software (need root privileges) :
```
sudo make install
```

It should output something like the following :
```
/bin/mkdir -p '/usr/pgsql-9.3/share/extension'
/bin/mkdir -p '/usr/pgsql-9.3/share/extension'
/bin/mkdir -p '/usr/pgsql-9.3/lib'
/bin/mkdir -p '/usr/pgsql-9.3/share/doc/extension'
/usr/bin/install -c -m 644 ./powa.control '/usr/pgsql-9.3/share/extension/'
/usr/bin/install -c -m 644 ./powa--1.0.sql ./powa--1.1.sql ./powa--1.2.sql ./powa--1.1--1.2.sql  '/usr/pgsql-9.3/share/extension/'
/usr/bin/install -c -m 755  powa.so '/usr/pgsql-9.3/postgresql-9.3.4/lib/'
/usr/bin/install -c -m 644 ./README.md '/usr/pgsql-9.3/share/doc/extension/'
```


Create a PoWA database and create required extensions
-----------------------------------------------------

First, connect to PostgreSQL as administrator :
```
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
```


Modify the configuration files
------------------------------

In `postgresql.conf`:

Change the `shared_preload_libraries` appropriately :
```
shared_preload_libraries = 'powa,pg_stat_statements'# (change requires restart)
```

Other GUC variables are available. Read [README.md](https://github.com/dalibo/powa/blob/master/README.md) for further details.

In `pg_hba.conf`:

Add an entry if needed for the PostgreSQL user(s) that need to connect on the GUI.
For instance, assuming a `local connection` on database `powa`, allowing any user:

`host    powa    all     127.0.0.1/32    md5`

Restart PostgreSQL
------------------

As root, run the following command :
```
service postgresql-9.3 restart
```

PostgreSQL should output the following messages in the log files :
```
2014-07-25 03:48:20 IST LOG:  registering background worker "powa"
2014-07-25 03:48:20 IST LOG:  loaded library "powa"
2014-07-25 03:48:20 IST LOG:  loaded library "pg_stat_statements"
```


Set-up the UI
-------------


Read [ui/README.md](https://github.com/dalibo/powa/blob/master/ui/README.md) for the UI installation details.



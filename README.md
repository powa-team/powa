PostgreSQL Workload Analyzer
============================

PoWA is an extension designed to historize informations given by the
`pg_stat_statements extension`. It provides sql SRF (Set Returning Functions)
to gather useful information on a specified time interval. If possible (verify
with pg_test_timing), also activate track_io_timing in postgresql.conf.

PoWA requires PostgreSQL 9.3 or more.

Connecting on the GUI requires a PostgreSQL user with SUPERUSER and LOGIN privileges.

Installation
--------------

For a detailed installation procedure, please read [INSTALL.md](https://github.com/dalibo/powa/blob/master/INSTALL.md).

Optionally, you can create a dedicated user for PoWA. For instance, connected on PostgreSQL :
`CREATE USER powa SUPERUSER ENCRYPTED PASSWORD 'mypassword'` (don't forget to change the password).

- make install in the main directory
- Make sure you have installed and configured `pg_stat_statements`
- create a dedicated database (powa for instance)
- create extension powa in this databse
- add "powa" in the `shared_preload_libraries` in postgresql.conf (you should already have configured "`pg_stat_statements`")
- configure GUC in postgresql.conf (see the §Configuration below)
- configure connections in pg_hba.conf to allow connection from the server that will run the GUI
- restart instance

Upgrade from previous version:

- make install in the main directory
- restart your PostgreSQL engine to use the new powa library
- ALTER EXTENSION powa UPDATE; -- This will take some time, a lot of things are rewritten as the schema is upgraded
- If you have deadlock messages, it means that the powa extension is trying to update data, while your update is doing conflicting operations. To solve this, put powa.frequency=-1 to deactivate powa temporarily, then do the extension update, and put powa.frequency back to what it was before. Don't forget to reload your configuration each time.

Configuration:
------------------------


Here are the configuration parameters (GUC) available:

* `powa.frequency` : Defines the frequency of the snapshots. Minimum 5s. You can use the usual postgresql time abbreviations. If not specified, the unit is seconds. Defaults to 5 minutes. Setting it to -1 will disable powa (powa will still start, but it won't collect anything anymore, and wont connect to the database).

* `powa.retention` : Automatically purge data older than that. If not specified, the unit is minutes. Defaults to 1 day.

* `powa.database` : Defines the database of the workload repository. Defaults to powa.

* `powa.coalesce` : Defines the amount of records to group together in the table.

The more you coalesce, the more PostgreSQL can compress. But the more it has
to uncompact when queried. Defaults to 100.

If you can afford it, put a rather high work_mem for the database powa. It will help, as the queries used to display the ui are doing lots of sampling, implying lots of sorts.

We use this:
`ALTER DATABASE powa SET work_mem TO '256MB';`

It's only used for the duration of the queries anyway, this is not statically allocated memory.

Reset the stats:
------------------------

`SELECT powa_stats_reset();` (in the powa database of course)

Set up the UI:
------------------------

Read [ui/README.md](https://github.com/dalibo/powa/blob/master/ui/README.md).

Easy install from a Debian package:
--------------------------------------

The package is built and tested on a Debian 7.5 (Wheezy) and should work on later Debian releases.

1- Technical requirements:

	- postgresql-server-dev-9.3 (for the build of PoWA extension)
	- postgresql (>= 9.3)
	- postgresql-contrib (>= 9.3)
	- libdbd-pg-perl (>= 2.19.2-2)
	- libmojolicious-perl (>= 4.63)

The libmojolicious-perl (>= 4.63) is not available in the Wheezy repo. To install it follow these steps :

```
$ wget http://backpan.perl.org/authors/id/S/SR/SRI/Mojolicious-4.63.tar.gz
$ cd Mojolicious-4.63
$ perl Makefile.PL
$ checkinstall -D (install checkinstall if it isn't installed)
```

Note :
In order to create and install correctly libmojolicious-perl, you have to set some package's metadata prompted by checkinstall :
- Set 'Summary' option (1) to "simple, yet powerful, Web Application Framework"
- Set 'Name' option (2) to "libmojolicious-perl"
- Hit ENTER and it is done ;)

Look [here](https://wiki.postgresql.org/wiki/Apt) for more details about installing PostgreSQL 9.3.

2- Download the [PoWA last release](https://github.com/abessifi/powa) and create an upstream tarball:

```
$ git clone https://github.com/abessifi/powa powa_1.2.orig
$ tar czf powa_1.2.orig.tar.gz powa_1.2.orig
```

3- Build the package :

```
$ cd powa_1.2.orig
$ debuild -us -uc
$ cd ..
```

4- Install the package and check the service :

Once created, the powa_1.2-1_*.deb package could be used to install PoWA in other machines (with same system architecture).

```
$ dpkg -i powa_1.2-1_*.deb
```

PoWA is now installed and handled by an initscript. To check if the service is running :

```
$ service status powa
```

If it is running, access the web UI on http://localhost:3000
Otherwise, try to adapt the PoWA's config file /etc/powa/powa.conf and the default service parameters in /etc/default/powa, then restart the service :

```
$ service restart powa
```

5- Setup the stats collector :

This step is well explained in the "Create a PoWA database" and "Modify the configuration files" sections [here](https://github.com/dalibo/powa/blob/master/INSTALL.md).

6- Troubleshooting :

- First check the logs on /var/log/powa/powa.log
- Make sure you've installed the required packages with required versions.
- If powa service couldn't be started, make sure to correctly set the variables DAEMON and PERL5LIB in /etc/default/powa. The command "which morbo" gives you the correct absolute path to the 'morbo' binary.

Impact on performances
---------------------------

Using POWA will have a small negative impact on your PostgreSQL server performances. It is hard to evaluate precisely this impact but we can analyze it in 3 parts :

- First of all, you need to activate the `pg_stat_statements` module. This module itself may slow down your instance, but some benchmarks show that the impact is not that big.

- Second, the POWA collector should have a very low impact, but of course that depends on the frequency at which you collect data. If you do it every 5 seconds, you'll definitely see something. At 5 minutes, the impact should be minimal.

- And finally the POWA GUI will have an impact too if you run it on the PostgreSQL instance, but it really depends on many user will have access to it.

All in all, we strongly feel that the performance impact of POWA is nothing compared to being in the dark and not knowing what is running on your database. And in most cases the impact is lower than setting ``log_min_duration_statement = 0``.

See our own benchmark for more details:
[POWA vs The Badger](https://github.com/dalibo/powa/wiki/POWA-vs-pgBadger)


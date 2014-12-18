PostgreSQL Workload Analyzer
============================

PoWA is an extension designed to historize informations given by the
`pg_stat_statements extension`. It provides sql SRF (Set Returning Functions)
to gather useful information on a specified time interval. If possible (verify
with pg_test_timing), also activate track_io_timing in postgresql.conf.

PoWA requires PostgreSQL 9.3 or more.

Connecting on the GUI requires a PostgreSQL user with SUPERUSER and LOGIN privileges.

Manual installation
-------------------

For a detailed and manual installation procedure, please read [INSTALL.md](https://github.com/dalibo/powa/blob/master/INSTALL.md).

To Set up the UI, read [ui/README.md](https://github.com/dalibo/powa/blob/master/ui/README.md).

Easy install from a Debian package
----------------------------------

The package is built and tested on a `Debian 7.5 (Wheezy)` and should work on later Debian releases.

1- Technical requirements:

```
postgresql (>= 9.3)
postgresql-contrib (>= 9.3)
postgresql-server-dev-9.3 (for the build of PoWA extension)
libdbd-pg-perl (>= 2.19.2-2)
libmojolicious-perl (>= 4.63)
```

Look [here](https://wiki.postgresql.org/wiki/Apt) for more details about installing `PostgreSQL 9.3`.

The `libmojolicious-perl` (>= 4.63) is not available in the Wheezy repo. To install it follow these steps :

```
$ cd /tmp
$ wget http://backpan.perl.org/authors/id/S/SR/SRI/Mojolicious-4.63.tar.gz
$ tar xzf Mojolicious-4.63.tar.gz
$ cd Mojolicious-4.63
$ perl Makefile.PL
$ checkinstall -D (install checkinstall if it isn't installed)
```

Note :
In order to create and install correctly `libmojolicious-perl`, you have to set some package's metadata prompted by checkinstall :
- Answer 'N' to the question "Should I create a default set of package docs?"
- Set 'Summary' option (1) to "simple, yet powerful, Web Application Framework"
- Set 'Name' option (2) to "libmojolicious-perl"
- Hit ENTER and it is done ;)

2- Download the [PoWA last release](https://github.com/abessifi/powa) and create an upstream tarball:

```
$ git clone https://github.com/abessifi/powa powa_1.2.orig
$ tar czf powa_1.2.orig.tar.gz powa_1.2.orig
```

To get a specific version :

```
$ git tag --list
$ git checkout <tag_name> (E.g : powa_1.2-1.deb)
```

3- Build the package :

```
$ cd powa_1.2.orig
$ debuild -us -uc
$ cd ..
```

4- Install and configure the service :

Once created, the `powa_1.2-1_*.deb` package could be used to install PoWA in other machines (with same system architecture).

```
$ dpkg -i powa_1.2-1_*.deb
```

Note :
- Upgrade from a previous version will take some time, a lot of things are rewritten as the schema is upgraded.
- The `powa` database and the required extensions will be created automatically.
- If a `powa` database exists already, `debconf` will ask you to keep/purge it. Purging will fail if the DB is used by other users/procs (eventually powa collector, which is a PostgreSQL backend worker).
- To purge the database, edit `postgresql.conf` and remove `powa,pg_stat_statements` from `shared_preload_libraries` (you can comment the entire line too) then restart PostgreSQL. Now you can purge the `powa` database.
- Connecting to the GUI requires a PostgreSQL user with SUPERUSER and LOGIN privileges. Default username is `'powa'`. You'll be asked by `debconf` to setup a new password.

PoWA is now installed and handled by an initscript. To check if the service is running :

```
$ service powa status
```

If it is running, access the web UI on `http://localhost:3000`.
Otherwise, try to adapt the PoWA's config file `/etc/powa/powa.conf` and the default service parameters in `/etc/default/powa`, then restart the service :

```
$ service restart powa
```

Last step, edit `postgresql.conf`. Change the `shared_preload_libraries` appropriately :

```
shared_preload_libraries = 'powa,pg_stat_statements'# (change requires restart)
```

If possible (check with pg_test_timing), activate track_io_timing on your instance, in postgresql.conf :

```
track_io_timing = on
```

5- Troubleshooting :

- First, check the logs on `/var/log/powa/powa.log`.
- For more details, enable the debug level (MOJO_LOG_LEVEL="debug") in `/etc/default/powa` and restart the service.
- Make sure you've installed the required packages with required versions.
- If powa service couldn't be started, make sure to correctly set the variables `DAEMON` and `PERL5LIB` in `/etc/default/powa`. The command "which hypnotoad" gives you the correct absolute path to the `hypnotoad` binary.
- If DB removal fails, make sure that it not busy.
- If you uninstalled powa, change the `shared_preload_libraries` properly in `postgresql.conf` and restart PostgreSQL.

Advanced configuration and tuning
----------------------------------

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

Reset the stats
----------------

`SELECT powa_stats_reset();` (in the powa database of course)

Impact on performances
----------------------

Using POWA will have a small negative impact on your PostgreSQL server performances. It is hard to evaluate precisely this impact but we can analyze it in 3 parts :

- First of all, you need to activate the `pg_stat_statements` module. This module itself may slow down your instance, but some benchmarks show that the impact is not that big.

- Second, the POWA collector should have a very low impact, but of course that depends on the frequency at which you collect data. If you do it every 5 seconds, you'll definitely see something. At 5 minutes, the impact should be minimal.

- And finally the POWA GUI will have an impact too if you run it on the PostgreSQL instance, but it really depends on many user will have access to it.

All in all, we strongly feel that the performance impact of POWA is nothing compared to being in the dark and not knowing what is running on your database. And in most cases the impact is lower than setting ``log_min_duration_statement = 0``.

See our own benchmark for more details:
[POWA vs The Badger](https://github.com/dalibo/powa/wiki/POWA-vs-pgBadger)


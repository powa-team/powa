.. _quickstart:

Quickstart
==========

.. warning::

  The current version of PoWA is designed for PostgreSQL 9.4 and newer. If you
  want to use PoWA on PostgreSQL < 9.4, please use the `1.x series
  <https://powa.readthedocs.io/en/rel_1_stable/>`_

The following describes the installation of the two main modules of PoWA:
  * powa-archivist with the PGDG packages (Red Hat/Rocky Linux,
    Debian/Ubuntu) or from the sources
  * powa-web from the PGDG packages (Red Hat/CentOS/Rocky Linux, Debian/Ubuntu)
    or with python pip

.. note::

    This page shows how to configure a **local PoWA setup**.  If you're
    interested in configuring PoWA for **multiple servers**, and/or for
    **standby servers**, please also refer to the :ref:`remote_setup` page to
    see additional steps for such a remote setup.


Install PoWA from packages (Red Hat/Rocky Linux/Debian/Ubuntu)
**************************************************************

Prerequisites
-------------

PoWA must be installed on the PostgreSQL instance that you are monitoring.

.. note::

    All extensions except **hypopg** only need to be installed once, in the
    **powa** database (or another database configured by the configuration
    option **powa.database**).

    hypopg must be installed in every database on which you want to be able to
    get automatic index suggestion, including the powa database if needed.

    powa-web must be configured to connect on the database where you
    installed all the extensions.

We suppose that you are using the packages from the PostgreSQL Development
Group (https://yum.postgresql.org/ or https://apt.postgresql.org/). For example
for PostgreSQL 14 on Rocky Linux 8 a cluster is installed with the following
commands, following `the official
instructions <https://www.postgresql.org/download/linux/redhat/>`_):

.. code-block:: bash

    # Install the repository RPM:
    sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

    # Disable the built-in PostgreSQL module:
    sudo dnf -qy module disable postgresql

    # Install PostgreSQL:
    sudo dnf install -y postgresql14-server

    # Optionally initialize the database and enable automatic start:
    sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
    sudo systemctl enable postgresql-14
    sudo systemctl start postgresql-14


You will also need the PostgreSQL contrib package to provide the
`pg_stat_statements` extension:

.. code-block:: bash

    sudo dnf install postgresql14-contrib

On `Debian / Ubuntu <https://wiki.postgresql.org/wiki/Apt>_`, that would be:

.. code-block:: bash

    sudo apt install curl ca-certificates gnupg
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt update
    sudo apt install postgresql-14 postgresql-client-14 postgresql-contrib-14

In these examples and the following ones, replace 14 according to your version
(13, 10, 9.5...).


Installation of the PostgreSQL extensions
-----------------------------------------

You can simply install the packages provided by the PGDG
repository according to your PostgreSQL version. For example on
Red Hat/Rocky Linux for PostgreSQL 14:

.. code-block:: bash

    sudo dnf install powa_14 pg_qualstats_14 pg_stat_kcache_14 hypopg_14

On Debian, this will be:

.. code-block:: bash

   apt-get install postgresql-14-powa postgresql-14-pg-qualstats postgresql-14-pg-stat-kcache postgresql-14-hypopg

On other systems, or to test newer unpackaged version,
you will have to compile some extensions manually :ref:`as described in
the next section<powa-archivist-from-the-sources>`:

.. code-block:: bash

   apt-get install postgresql-14-powa


Once all extensions are installed or compiled, add the required modules to
`shared_preload_libraries` in the `postgresql.conf` of your instance:

.. code-block:: ini

    shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

.. note::

    If you also installed the pg_wait_sampling extension, don't forget to add
    it to ``shared_preload_libraries`` too.

Now restart PostgreSQL. Under RHEL/Rocky Linux (as root):

.. code-block:: bash

    /etc/init.d/postgresql-14 restart

Under RHEL/Rocky Linux:

.. code-block:: bash

    systemctl restart postgresql-14

On Debian:

.. code-block:: bash

    pg_ctlcluster 14 main restart

Log in to your PostgreSQL as a superuser and create a `powa` database:

.. code-block:: sql

    CREATE DATABASE powa ;

Create the required extensions in this new database:

.. code-block:: psql

    \c powa
    CREATE EXTENSION pg_stat_statements;
    CREATE EXTENSION btree_gist;
    CREATE EXTENSION powa;
    CREATE EXTENSION pg_qualstats;
    CREATE EXTENSION pg_stat_kcache;

.. note::

    If you also installed the pg_wait_sampling extension, don't forget to
    create the extension too.

PoWA needs the `hypopg` extension in all databases of the cluster in order to
check that the suggested indexes are efficient:

.. code-block:: sql

    CREATE EXTENSION hypopg;

One last step is to create a role that has superuser privileges and is able to
login to the cluster (use your own credentials):

.. code-block:: sql

    CREATE ROLE powa SUPERUSER LOGIN PASSWORD 'astrongpassword' ;

The Web UI requires you to log in with a PostgreSQL role that has superuser
privileges as only a superuser can access to the query text in PostgreSQL. PoWA
follows the same principle.

PoWA is now up and running on the PostgreSQL-side. You still need to set up the
web interface in order to access your history.  By default
powa-archivist stores history for 1 day and takes a snapshot every 5 minutes.
These default settings can be easily changed afterwards.

Install the Web UI
------------------

The RPM packages should work for currently supported Red Hat/Rocky Linux and
Debian / Ubuntu. For unsupported platforms, see :ref:`the installation through
pip<powa-web-from-pip>` or :ref:`the full manual installation
guide<powa-web-manual-installation>`.

You can install the web client on any server you like. The only requirement is
that the web client can connect to the previously set up PostgreSQL cluster.

If you're setting up PoWA on another server, you have to install the PGDG repo
package again. This is required to install the `powa_14-web` package and some
dependencies.

Again, for example for PostgreSQL 14 on Rocky Linux 8, install the
`powa_14-web` RPM package with its dependencies using:

.. code-block:: bash

    sudo dnf install powa_14-web

And on Debian / Ubuntu:

.. code-block:: bash

    sudo apt install powa-web

Create the `/etc/powa-web.conf` config-file to tell the UI how to connect to
your freshly installed PoWA database. Of course, change the given cookie to
something from your own. For example to connect to the local instance on
`localhost`:

.. code-block::

    servers={
      'main': {
        'host': 'localhost',
        'port': '5432',
        'database': 'powa'
      }
    }
    cookie_secret="SUPERSECRET_THAT_YOU_SHOULD_CHANGE"

Don't forget to allow the web server to connect to the PostgreSQL cluster, and
edit your `pg_hba.conf` accordingly.

Then, run powa-web:

.. code-block:: bash

  powa-web

The Web UI is now available on port 8888,
for example on http://localhost:8888/.
You may have to configure your firewall to open the access to the outside.
Use the role created earlier in PostgreSQL to connect to the UI.


.. _powa-archivist-from-the-sources:

Build and install powa-archivist from the sources
*************************************************


Prerequisites
-------------

You will need a compiler, the appropriate PostgreSQL development packages, and
some contrib modules.

While on most installation, the contrib modules are installed with a
postgresql-contrib package, if you wish to install them from source, you should
note that only the following modules are required:

  * btree_gist
  * pg_stat_statements

On Red Hat/Rocky Linux:

.. code-block:: bash

  sudo dng install postgresql14-devel postgresql14-contrib

On Debian/Ubuntu:

.. code-block:: bash

  apt-get install postgresql-server-dev-14 postgresql-contrib-14

Installation
------------

Download powa-archivist latest release:

.. parsed-literal::
  wget |download_link|

Convenience scripts are offered to build every project that PoWA can take
advantage of.

First, the install_all.sql file:

.. code-block:: psql

    CREATE DATABASE IF NOT EXISTS powa;
    \c powa
    CREATE EXTENSION IF NOT EXISTS btree_gist;
    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
    CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;
    CREATE EXTENSION IF NOT EXISTS pg_qualstats;
    CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
    CREATE EXTENSION IF NOT EXISTS pg_track_settings;
    CREATE EXTENSION IF NOT EXISTS powa;

And the main build script:

.. parsed-literal::

  #!/bin/bash
  # This script is meant to install every PostgreSQL extension compatible with
  # PoWA.
  wget |pg_qualstats_download| -O pg_qualstats-|pg_qualstats_release|.tar.gz
  tar zxvf pg_qualstats-|pg_qualstats_release|.tar.gz
  cd pg_qualstats-|pg_qualstats_release|
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  rm pg_qualstats-|pg_qualstats_release|.tar.gz
  rm pg_qualstats-|pg_qualstats_release| -rf
  wget |pg_stat_kcache_download| -O pg_stat_kcache-|pg_stat_kcache_release|.tar.gz
  tar zxvf pg_stat_kcache-|pg_stat_kcache_release|.tar.gz
  cd pg_stat_kcache-|pg_stat_kcache_release|
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  rm pg_stat_kcache-|pg_stat_kcache_release|.tar.gz
  rm pg_stat_kcache-|pg_stat_kcache_release| -rf
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  wget |pg_wait_sampling_download| -O pg_wait_sampling-|pg_wait_sampling_release|.tar.gz
  tar zxvf pg_wait_sampling-|pg_wait_sampling_release|.tar.gz
  cd pg_wait_sampling-|pg_wait_sampling_release|
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  rm pg_wait_sampling-|pg_wait_sampling_release|.tar.gz
  rm pg_wait_sampling-|pg_wait_sampling_release| -rf
  wget |pg_track_settings_download| -O pg_track_settings-|pg_track_settings_release|.tar.gz
  tar zxvf pg_track_settings-|pg_track_settings_release|.tar.gz
  cd pg_track_settings-|pg_track_settings_release|
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  rm pg_track_settings-|pg_track_settings_release|.tar.gz
  rm pg_track_settings-|pg_track_settings_release| -rf
  echo ""
  echo "You should add the following line to your postgresql.conf:"
  echo ''
  echo "shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats,pg_wait_sampling'"
  echo ""
  echo "Once done, restart your postgresql server and run the install_all.sql file"
  echo "with a superuser, for example: "
  echo "  psql -U postgres -f install_all.sql"


This script will ask for your super user password, provided the sudo command
is available, and install powa, pg_qualstats, pg_stat_kcache and
pg_wait_sampling for you.

.. warning::

  This script is not intended to be run on a production server, as it
  compiles all the extensions.  You should prefer to install packages on your
  production servers.


Once done, you should modify your PostgreSQL configuration as mentioned by the
script, putting the following line in your `postgresql.conf` file:

.. code-block:: ini

  shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats,pg_wait_sampling'

Optionally, you can install the hypopg extension the same way from
https://github.com/hypopg/hypopg/releases.

And restart your server, according to your distribution's preferred way of doing
so, for example:

Init scripts:

.. code-block:: bash

    /etc/init.d/postgresql-14 restart

Debian pg_ctlcluster wrapper:

.. code-block:: bash

    pg_ctlcluster 14 main restart

Systemd:

.. code-block:: bash

    systemctl restart postgresql

The last step is to create a database dedicated to the PoWA repository, and
create every extension in it. The install_all.sql file performs this task:

.. code-block:: bash

  psql -U postgres -f install_all.sql
  CREATE DATABASE
  You are now connected to database "powa" as user "postgres".
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION

.. _powa-web-from-pip:

Install powa-web anywhere
*************************

You do not have to install the GUI on the same machine your instance is running.

Prerequisites
-------------

* The Python language, either 2.6, 2.7 or > 3
* The Python language headers, either 2.6, 2.7 or > 3
* The pip installer for Python. It is usually packaged as "python-pip", for example:


Debian:

.. code-block:: bash

  sudo apt-get install python-pip python-dev

Red Hat/Rocky Linux:

.. code-block:: bash

  sudo yum install python-pip python-devel


Installation
------------

To install powa-web, just issue the following comamnd:

.. code-block:: bash

  sudo pip install powa-web

Then you'll have to configure a config file somewhere, in one of those location:

* /etc/powa-web.conf
* ~/.config/powa-web.conf
* ~/.powa-web.conf
* ./powa-web.conf

The configuration file is a simple tornado config file. Copy the following
content to one of the above locations and modify it according to your setup:

.. code-block::

    servers={
      'main': {
        'host': 'localhost',
        'port': '5432',
        'database': 'powa'
      }
    }
    cookie_secret="SUPERSECRET_THAT_YOU_SHOULD_CHANGE"

The servers key define a list of server available for connection by PoWA-web.
You should ensure that the pg_hba.conf file is properly configured.

The cookie_secret is used as a key to crypt cookies between the client and the
server. You should DEFINITELY not keep the default if you value your security.

Other options are described in
:ref:`the full manual installation guide<powa-web-manual-installation>`.

Then, run powa-web:

.. code-block:: bash

  powa-web

The UI is now available on the 8888 port (eg. http://localhost:8888). Login
with the credentials of the `powa` PostgreSQL user.

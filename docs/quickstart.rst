.. _quickstart:

Quickstart
==========

.. warning::

  The current version of PoWA is designed for PostgreSQL 9.4 and later. If you want to use PoWA on PostgreSQL < 9.4, please use the `1.x series <http://powa.readthedocs.io/en/rel_1_stable/>`_

The following describes the installation of the two modules of PoWA:
  * powa-archivist with the PGDG packages (RedHat/CentOS 6/7, Debian) or from the sources
  * powa-web from the PGDG packages (RedHat/CentOS 7) or with python pip
 


Install PoWA from packages on RHEL/CentOS
*****************************************

Prerequisites
-------------

PoWA must be installed on the PostgreSQL instance that you are monitoring. 

We suppose that you are using the packages from the PostgreSQL Development 
Group (https://yum.postgresql.org/ or https://apt.postgresql.org/). For example
for PostgreSQL 9.6 on CentOS 7 a cluster is installed with the following commands:

.. code-block:: bash

    yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
    yum install postgresql96 postgresql96-server
    /usr/pgsql-9.6/bin/postgresql96-setup initdb 
    systemctl start postgresql-9.6

You will also need the PostgreSQL contrib package to provide the `pg_stat_statements` extension:

.. code-block:: bash

    yum install postgresql96-contrib

On Debian, that would be:

.. code-block:: bash

   apt-get install postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6



Installation of the PostgreSQL extensions
-----------------------------------------

On RedHat/CentOS, you can simply install the packages provided by the PGDG 
repository according to your PostgreSQL version. For example for PostgreSQL 9.6:

.. code-block:: bash

    yum install powa_96 pg_qualstats96 pg_stat_kcache96 hypopg_96

On Debian the PoWA package exists but pg_qualstats, pg_stat_kcache and hypopg
are not packaged and you will have to compile them manually :ref:`as described in 
the next section<powa-archivist-from-the-sources>`:

.. code-block:: bash

   apt-get install postgresql-9.6-powa 


Once all extensions are installed or compiled, add the required modules to 
`shared_preload_libraries` in the `postgresql.conf` of your instance:

.. code-block:: ini

    shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

Now restart PostgreSQL. Under RHEL/CentOS 6:

.. code-block:: bash

    /etc/init.d/postgresql-9.6 restart

Under RHEL/CentOS 7:

.. code-block:: bash

    systemctl restart postgresql-9.6

On Debian:

.. code-block:: bash

    pg_ctlcluster 9.6 main restart

Log in to your PostgreSQL as a superuser and create a `powa` database:

.. code-block:: sql

    CREATE DATABASE powa ;

Create the required extensions in this new database:

.. code-block:: sql

    \c powa
    CREATE EXTENSION pg_stat_statements;
    CREATE EXTENSION btree_gist;
    CREATE EXTENSION powa;
    CREATE EXTENSION pg_qualstats;
    CREATE EXTENSION pg_stat_kcache;

PoWA needs the `hypopg` extension in all databases of the cluster in order to 
check that the suggested indexes are efficient:

.. code-block:: sql

    CREATE EXTENSION hypopg;

One last step is to create a role that has superuser privileges and is able to
login to the cluster (use your own credentials):

.. code-block:: sql

    CREATE ROLE powa SUPERUSER LOGIN PASSWORD 'astrongpassword' ;

The Web UI requires you to log in with a PostgreSQL role that has superuser
privileges as only a superuser can access to the query text in PostgreSQL, PoWA
follows the same principle.

PoWA is now up and running on the PostgreSQL-side. You still need to set up the
Web interface in order to access your history.  By default
powa-archivist stores history for 1 day and takes a snapshot every 5 minutes.
This default settings can be changed easily afterwards.

Install the Web UI 
------------------

The RPM packages work for now only on RedHat/CentOS 7. For RedHat/CentOS 6 or Debian, 
see :ref:`the installation through pip<powa-web-from-pip>` or 
:ref:`the full manual installation guide<powa-web-manual-installation>`.

You can install the web-client on any server you like. The only requirement is
that the web-client can connect to the previously set-up PostgreSQL cluster.

If you're setting up PoWA on another server, you have to install the PGDG repo
package again. This is required to install the `powa_96-web` package and some
dependencies.

Again, for example for PostgreSQL 9.6 on CentOS 7:

.. code-block:: bash

    yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm

.. useless until a solution for installing rpms on rh6 is found 
   For RHEL/CentOS 6, you may need to install the EPEL repository too.
   code-block:: bash
    yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

Install the `powa_96-web` RPM package with its dependencies:

.. code-block:: bash

    yum install powa_96-web

Create the `/etc/powa-web.conf` config-file to tell the UI how to connect to
your freshly installed PoWA database. Of course, change the given cookie to
something from your own. For example to connect to the local instance on 
`localhost`:

.. code-block:: json

  servers={
    'main': {
      'host': 'localhost',
      'port': '5432',
      'database': 'powa'
    }
  }
  cookie_secret="SUPERSECRET_THAT_YOU_SHOULD_CHANGE"

Don't forget to allow the web server to connect to the PostgreSQL cluster, and edit your
`pg_hba.conf` accordingly.

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

On RedHat/CentOS:

.. code-block:: bash

  yum install postgresql96-devel postgresql96-contrib

On Debian:

.. code-block:: bash

  apt-get install postgresql-server-dev-9.6 postgresql-contrib-9.6

Installation
------------

Download powa-archivist latest release:

.. parsed-literal::
  wget |download_link|

A convenience script is offered to build every project that PoWA can take
advantage of:

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
  echo ""
  echo "You should add the following line to your postgresql.conf:"
  echo ''
  echo "shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'"
  echo ""
  echo "Once done, restart your postgresql server and run the install_all.sql file"
  echo "with a superuser, for example: "
  echo "  psql -U postgres -f install_all.sql"


This script will ask for your super user password, provided the sudo command
is available, and install powa, pg_qualstats and pg_stat_kcache for you.

.. warning::

  This script is not intended to be run on a production server, as it will
  install the development version of each extension and not the latest stable
  release. It has been removed since the 2.0.1 release of PoWA.


Once done, you should modify your PostgreSQL configuration as mentioned by the
script, putting the following line in your `postgresql.conf` file:

.. code-block:: ini

  shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

Optionally, you can install the hypopg extension the same way from https://github.com/dalibo/hypopg/releases.

And restart your server, according to your distribution's preferred way of doing
so, for example:

Init scripts:

.. code-block:: bash

    /etc/init.d/postgresql-9.6 restart

Debian pg_ctlcluster wrapper:

.. code-block:: bash

    pg_ctlcluster 9.6 main restart

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

RedHat/CentOS:

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

The configuration file is a simple JSON one. Copy the following content to one
of the above locations:

.. code-block:: json

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
server. You should DEFINETLY not keep the default if you value your security.

Other options are described in the full documentation.

Then, run powa-web:

.. code-block:: bash

  powa-web

The UI is now available on the 8888 port. Login with the credentials of the `powa` PostgreSQL user. 

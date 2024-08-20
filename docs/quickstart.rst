.. _quickstart:

Quickstart
==========

.. warning::

  The current version of PoWA is designed for PostgreSQL 9.4 and newer. If you
  want to use PoWA on PostgreSQL < 9.4, please use the `1.x series
  <https://powa.readthedocs.io/en/rel_1_stable/>`_

The following describes the installation of the two main modules of PoWA:
  * powa-archivist (and all other supported extensions) using the PGDG packages
    (Red Hat/Rocky Linux, Debian/Ubuntu)
  * powa-web from the PGDG packages (Red Hat/CentOS/Rocky Linux, Debian/Ubuntu)
    or with python pip

.. note::

    This page shows how to configure a **local PoWA setup**.  If you're
    interested in configuring PoWA for **multiple servers**, and/or for
    **standby servers**, please also refer to the :ref:`remote_setup` page to
    see additional steps for such a remote setup.


Install PoWA related packages
*****************************

Prerequirements
---------------

PoWA must be installed on the PostgreSQL instance that you are monitoring.

.. note::

    All extensions except **hypopg** only need to be installed once, in the
    dedicated **powa** database (or another database name that you want to use).

    hypopg must be installed in every database on which you want to be able to
    get automatic index suggestion, including the powa database if needed.

    powa-web must be configured to connect on the database where you
    installed all the extensions.

In these examples, you simply need to replace **14** according to your actual
PostgreSQL major version (13, 10, 9.5...).

What should be installed
------------------------

PoWA is a modular tool and let you choose which datasource(s) (backed by
extensions) you want to add, depending on your needs.  In the following
examples we install all the supported extensions.  You can skip any of them if
you want, as long as you install the mandatory ones, which are:

  - pg_stat_statements
  - btree_gist
  - powa-archivist

The PGDG package extension documentation also contain the necessary
instructions to install and bootstrap a PostgreSQL instance.  If you already
have one you should skip this part and only use the documentation on how to add
the additional extensions.

Setup the PGDG repository and install the pacakges
--------------------------------------------------

We suppose that you are using the packages from the PostgreSQL Development
Group (https://yum.postgresql.org/ or https://apt.postgresql.org/).

The following examples show how to install a PostgreSQL 14 cluser on Rocky
Linux 8, following `the official YUM instructions
<https://www.postgresql.org/download/linux/redhat/>`_, and any Debian / Ubuntu
server, following `the official APT instructions
<https://wiki.postgresql.org/wiki/Apt>`_:

.. tabs::

  .. code-tab:: bash RHEL / Rocky

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

  .. code-tab:: bash Debian / Ubuntu

    sudo apt install curl ca-certificates gnupg
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt update
    sudo apt install postgresql-14 postgresql-client-14

You will also need the PostgreSQL contrib package to provide the
**pg_stat_statements** extension:

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo dnf install postgresql14-contrib

  .. code-tab:: bash Debian / Ubuntu

    sudo apt install postgresql-contrib-14

And the various powa extensions:

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo dnf install powa_14 pg_qualstats_14 pg_stat_kcache_14 hypopg_14 pg_wait_sampling_14 pg_track_settings_14

  .. code-tab:: bash Debian / Ubuntu

   apt-get install postgresql-14-powa postgresql-14-pg-qualstats postgresql-14-pg-stat-kcache postgresql-14-hypopg postgresql-14-pg-wait-sampling postgresql-14-pg-track-settings

On other systems, or to test newer unpackaged version, you will have to either
rely on container images or compile the necessary extensions manually.  Both
approaches are :ref:`described in the dedicated
section<powa-archivist-from-the-sources>`:

Configure the PostgreSQL instance
---------------------------------

Once all extensions are installed or compiled, add the required modules to
`shared_preload_libraries` in the `postgresql.conf` of your instance:

.. code-block:: ini

    shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats,pg_wait_sampling'

Now restart PostgreSQL:

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo systemctl restart postgresql-14

  .. code-tab:: bash Debian / Ubuntu

    sudo pg_ctlcluster 14 main restart

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
    CREATE EXTENSION pg_wait_sampling;
    CREATE EXTENSION pg_track_settings;

PoWA needs the `hypopg` extension in all databases of the cluster in order to
check that the suggested indexes are efficient:

.. code-block:: sql

    CREATE EXTENSION hypopg;

One last step is to create a role that has superuser privileges and is able to
login to the cluster (use your own credentials):

.. code-block:: sql

    CREATE ROLE powa SUPERUSER LOGIN PASSWORD 'astrongpassword' ;

.. note::

    This command is just an example. We strongly advise you to look at the
    `authentication documentation
    <https://www.postgresql.org/docs/current/client-authentication.html>`_
    and to properly setup this role and the other roles in a secure way.

The Web UI requires you to log in with a PostgreSQL role that has superuser
privileges as only a superuser can access to the query text in PostgreSQL. PoWA
follows the same principle.

PoWA is now up and running on the PostgreSQL-side. You still need to set up the
web interface in order to access your history.  By default
powa-archivist stores history for 1 day and takes a snapshot every 5 minutes.
These default settings can be easily changed afterwards.

Install the Web UI
******************

Install from the packages
-------------------------

The PGDG packages should work for currently supported Red Hat/Rocky Linux and
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

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo dnf install powa_14-web

  .. code-tab:: bash Debian / Ubuntu

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


.. _powa-web-from-pip:

Install powa-web from pip
-------------------------

You do not have to install the GUI on the same machine your instance is running.

Prerequisites
-------------

* The Python language, either 2.6, 2.7 or > 3
* The Python language headers, either 2.6, 2.7 or > 3
* The pip installer for Python. It is usually packaged as **python-pip**, for
  example:

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo dnf install python-pip python-devel

  .. code-tab:: bash Debian / Ubuntu

    sudo apt-get install python-pip python-dev

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

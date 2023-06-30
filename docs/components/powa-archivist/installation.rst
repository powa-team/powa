.. _powa-archivist_installation:

Installation
************

Introduction
------------

PoWA-archivist is the core component of the PoWA project. It is composed of 2
elements:

* an extension named "powa" containing management functions
* a module name "powa" that optionally runs a background worker to collect the
  performance data on the local instance


Prerequisites
-------------

* PostgreSQL >= 9.4
* PostgreSQL contrib modules (pg_stat_statements and btree_gist)
* PostgreSQL server headers (if compiling from sources)

Installation
------------

The recommended way to install PoWA-archivist is to use the packaged version
available in the PGDG repositories, which available for GNU/Linux distributions
based on Debian/Ubuntu or RHEL/Rocky/Fedora.  If you're using a distribution
where no PGDG repository or prepackaged version is available, we document
installation from source code.

Installation from PGDG repository
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

On Debian/Ubuntu, please refer to the `APT PGDG repository documentation
<https://apt.postgresql.org>` for the initial setup (which should already be
done if you have PostgreSQL installed), and simply install
``postgresql-XY-powa``.  For instance, if you're using PostgreSQL 15:

.. code-block:: bash

  sudo apt-get install postgresql-15-powa

On RHEL/Rock/Fedora, please refer to the `YUM PGDG repository documentation
<https://yum.postgresql.org>` for the iniial setup (which should already be
done if you have PostgreSQL installed), and simply install
``powa_XY``.  For instance, if you're using PostgreSQL 15:

.. code-block:: bash

  sudo dnf install powa_15

.. note::

    Package names for older PostgreSQL version may vary and not contain an
    ``_`` between the package name and the PostgreSQL major version.

Installation from sources
^^^^^^^^^^^^^^^^^^^^^^^^^

On Debian, the PostgreSQL server headers are installed via the
``postgresql-server-dev-XY`` package:

.. code-block:: bash

  sudo apt-get install postgresql-server-dev-15 postgresql-contrib-15

On RPM-based distros:

.. code-block:: bash

  sudo dnf install postgresql15-devel postgresql15-contrib

You also need a C compiler and other standard development tools.

On Debian, these can be installed via the ``build-essential`` package:

.. code-block:: bash

  apt-get install build-essential

On RPM-based distros, the "Development Tools" can be used:

.. code-block:: bash

  yum groupinstall "Development Tools"

Grab the latest release, and install it:

.. parsed-literal::

  wget |download_link| -O powa-archivist-|rel_tag_name|.tar.gz
  tar zxvf powa-archivist-|rel_tag_name|.tar.gz
  cd powa-archivist-|rel_tag_name|


Compile and install it:

.. code-block:: bash

  make
  sudo make install

.. note::

    Make sure that ``sudo`` refers to the same PostgreSQL headers.  Using
    ``pg_config`` and ``sudo pg_config`` should produce the same output.

It should output something like the following :

.. code-block:: bash

  /bin/mkdir -p '/usr/share/postgresql-15/extension'
  /bin/mkdir -p '/usr/share/postgresql-15/extension'
  /bin/mkdir -p '/usr/lib64/postgresql-15/lib64'
  /bin/mkdir -p '/usr/share/doc/postgresql-15/extension'
  /usr/bin/install -c -m 644 powa.control '/usr/share/postgresql-15/extension/'
  /usr/bin/install -c -m 644 powa--2.0.sql '/usr/share/postgresql-15/extension/'
  /usr/bin/install -c -m 644 README.md '/usr/share/doc/postgresql-15/extension/'
  /usr/bin/install -c -m 755  powa.so '/usr/lib64/postgresql-15/lib64/'

PostgreSQL installation
-----------------------

Create the PoWA database and create the required extensions, with the following
statements:

.. code-block:: sql

  CREATE EXTENSION pg_stat_statements;
  CREATE EXTENSION btree_gist;
  CREATE EXTENSION powa;


Example:

.. code-block:: bash

  bash-4.1$ psql
  psql (15.2)
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

As PoWA-archivist can provide a background worker, the library must be loaded
at server start time if local metric collection is wanted.

For this, modify the ``postgresql.conf`` configuration file, and add powa and
pg_stat_statements to the ``shared_preload_libraries`` parameter:

.. code-block:: ini

  shared_preload_libraries = 'pg_stat_statements,powa'

If possible, activate ``track_io_timing`` too:


.. code-block:: ini

  track_io_timing = on

PostgreSQL should then be restarted.

.. warning::

    Since PoWA 4, you need to specify **powa** in the
    `shared_preload_libraries` configuration **ONLY** if you want to store the
    performance data locally.  For remote storage, please see the
    :ref:`remote_setup` documentation.
    The :ref:`pg_stat_statements_doc` extension (as all other
    :ref:`stat_extensions`) still required to be configured in the
    `shared_preload_libraries` setting.

    If you're setting up a repository database for a remote server, you can
    also entirely skip the :ref:`pg_stat_statements_doc` configuration and the
    restart.

Major PostgreSQL Upgrade
------------------------

.. warning::

    There is a known issue with all PostgreSQL versions when using pg_upgrade
    on a instance having custom background workers, like PoWA in local setup
    mode: PostgreSQL doesn't prevent the background workers from doing their
    usual activity during pg_upgrade.  It means that if the background worker
    performs some write when pg_upgrade expects that no write would happen, the
    resulting cluster can be corrupted.  It's unfortunately not something that
    can be fixed from PoWA itself.

    If you want to perform a pg_upgrade of any instance having PoWA setup in
    local mode, you need to disable it before doing the pg_upgrade, and
    re-enable it once the upgrade is finished.

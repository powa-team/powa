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
* PostgreSQL server headers

On Debian, the PostgreSQL server headers are installed via the
``postgresql-server-dev-X.Y`` package:

.. code-block:: bash

  apt-get install postgresql-server-dev-9.4 postgresql-contrib-9.4

On RPM-based distros:

.. code-block:: bash

  yum install postgresql94-devel postgresql94-contrib

You also need a C compiler and other standard development tools.

On Debian, these can be installed via the ``build-essential`` package:

.. code-block:: bash

  apt-get install build-essential

On RPM-based distros, the "Development Tools" can be used:

.. code-block:: bash

  yum groupinstall "Development Tools"

Installation
------------


Grab the latest release, and install it:

.. parsed-literal::

  wget |download_link| -O powa-archivist-|rel_tag_name|.tar.gz
  tar zxvf powa-archivist-|rel_tag_name|.tar.gz
  cd powa-archivist-|rel_tag_name|


Compile and install it:

.. code-block:: bash

  make
  sudo make install

It should output something like the following :

.. code-block:: bash

  /bin/mkdir -p '/usr/share/postgresql-9.4/extension'
  /bin/mkdir -p '/usr/share/postgresql-9.4/extension'
  /bin/mkdir -p '/usr/lib64/postgresql-9.4/lib64'
  /bin/mkdir -p '/usr/share/doc/postgresql-9.4/extension'
  /usr/bin/install -c -m 644 powa.control '/usr/share/postgresql-9.4/extension/'
  /usr/bin/install -c -m 644 powa--2.0.sql '/usr/share/postgresql-9.4/extension/'
  /usr/bin/install -c -m 644 README.md '/usr/share/doc/postgresql-9.4/extension/'
  /usr/bin/install -c -m 755  powa.so '/usr/lib64/postgresql-9.4/lib64/'

Create the PoWA database and create the required extensions, with the following
statements:

.. code-block:: sql

  CREATE EXTENSION pg_stat_statements;
  CREATE EXTENSION btree_gist;
  CREATE EXTENSION powa;


Example:

.. code-block:: bash

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

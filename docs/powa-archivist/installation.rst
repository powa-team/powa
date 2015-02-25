.. _powa-archivist_installation:

Installation
************

Prerequisites
-------------

* PostgreSQL >= 9.4
* PostgreSQL server headers

On Debian, the PostgreSQL server headers are installed via the
``postgresql-server-dev-X.Y`` package:

.. code-block:: bash

  apt-get install postgresql-server-dev-9.4

On RPM-based distros:

.. code-block:: bash

  yum install postgresql94-devel

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


As PoWA-archivist is implemented as a background worker, the library must be
loaded at server start time.

For this, modify the ``postgresql.conf`` configuration file, and add powa and
pg_stat_statements to the ``shared_preload_libraries`` parameter:

.. code-block:: ini

  shared_preload_libraries = 'pg_stat_statements,powa'

If possible, activate ``track_io_timing`` too:


.. code-block:: ini

  track_io_timing = on

PostgreSQL should then be restarted.

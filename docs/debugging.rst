.. _powa-archivist-from-the-sources:

Unsupported OS and alternative use cases
========================================

In some cases you may want or need to rely on compiling one of various
components of PoWA.  For instance if you want to contribute a feature, need to
test a specific bugfix or if you're using a operating system where no packages
are available.

This section gives a short introduction on the various container images:

- `released version of
  PoWA <#released-versions-for-distro-where-no-packages-are-available>`_
- `git version of PoWA <#git-versions-of-powa>`_
- `PoWA development-oriented images <#development-oriented-images>`_

And how to compile the various components from source or rely on the various
container images that we provide.

Using the container images
**************************

.. warning::

  We **strongly** recomment you to follow the previous section and install the
  various packages from the PGDG repositories.
  This section is only meant as a documentation of the available container
  images, which are not recommended for production usage.

The `powa-podman <https://github.com/powa-team/powa-podman>`_ repository
contains various container images (and compose files) that can be used for
various purposes.  We assume here that you are familiar enough with **podman**
or any alternative container management tool build the images and deploy them,
and will only describe the various images provided.

Released versions for distro where no packages are available
------------------------------------------------------------

The `powa-archivist directory
<https://github.com/powa-team/powa-podman/tree/master/powa-archivist>`_
contains a Containerfile per supported major PostgreSQL version.  It contains
all the extensions (see the :ref:`components` section for the full
list) supported by PoWA.  Those images can be used as-is for either a
repository or remote server in case of a :ref:`remote_setup` or a standalone
installation.

Then a **powa-web** user interface image can also be built using the files
under the `powa-web directory
<https://github.com/powa-team/powa-podman/tree/master/powa-web>`_.

Finally, in case of a :ref:`remote_setup`, you will also need to run the
:ref:`powa_collector` daemon.  A container file is available for that in the
`powa-collector directory
<https://github.com/powa-team/powa-podman/tree/master/powa-collector>`_.

Additionally, the `compose directory
<https://github.com/powa-team/powa-podman/tree/master/compose>`_ contains a few
compose files that can be used to setup a fully working environment in either
the **local mode** or the **remote mode** (see the :ref:`architecture page for
more details page<architecture>`).  Those are only provided as reference and
are not intended for production use.  Feel free to adapt them to you own need
instead.

GIT versions of PoWA
--------------------

The `powa-podman repository
<https://github.com/powa-team/powa-podman/tree/master>`_ provides 3 directories
suffixed with **-git**:

- powa-archivist-git
- powa-web-git
- powa-collector-git

They provide the same components as the ones described in the previous section,
but instead of providing a specific version of the underlying tools, they
provide the current development version as-is.  This can be useful to test a
bugfix that hasn't been released yet.  The exact version that those images
provide depends on the time that they were built.  If you want to ensure that
you get the latest upstream commit, you should build them locally.

Development-oriented images
---------------------------

Finally, the `dev directory
<https://github.com/powa-team/powa-podman/tree/master/dev>`_ contain images and
compose files that are intended to help working on either the **powa-web** or
the **powa-collector** project without manually setting up a fully working
environment.  The idea is that the various compose file will setup the
environment, but using a **bind-mount** of the local version of the
**powa-web** and **powa-collector** tools, so that any change made to them can
be tested very easily.  Please refer to the `documentation
<https://github.com/powa-team/powa-podman/tree/master/dev/README>`_ for more
details about it.

Compile and install PoWA related extensions from the sources
************************************************************

.. warning::

  We **strongly** recomment you to follow the previous section and install the
  various packages from the PGDG repositories.
  This section is only meant as a documentation of how to compile the various
  extensions for very specific needs, like testing a current development
  version, and is **NOT** the recommended way of installation.

Prerequisites
-------------

You will need a compiler, the appropriate PostgreSQL development packages, and
some contrib modules.

While on most installation, the contrib modules are installed with a
postgresql-contrib package, if you wish to install them from source, you should
note that only the following modules are required:

  * btree_gist
  * pg_stat_statements

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo dnf install postgresql14-devel postgresql14-contrib

  .. code-tab:: bash Debian / Ubuntu

    sudo apt install postgresql-server-dev-14 postgresql-contrib-14

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

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    sudo systemctl restart postgresql

  .. code-tab:: bash Debian / Ubuntu

    sudo pg_ctlcluster 14 main restart

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

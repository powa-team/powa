.. _powa-web-manual-installation:

Installation
************

Introduction
------------

PoWA-web is the dedicated user interface of the PoWA project.  It produces
graphs, grids and suggest various kind of optimisations based on the data
stored on the PoWA repository server.

Prerequisites
-------------

* python >= 3.6
* psycopg2
* tornado >= 2.0

Installation
------------

The recommended way to install **powa-web** is to use the packaged version
available in the PGDG repositories for GNU/Linux distributions
based on Debian/Ubuntu.

For other platforms, or if you need a different version from the one provided
by the PGDG repositories, you can either:

* use the `provided container images
  <https://hub.docker.com/r/powateam/powa-web>`_,
* install it from `pypi <https://pypi.org/project/powa-web/>`_,
* install it manually.

We only document the package and manual installation here, as the other
methods don't have anything specific step.

Installation from Debian/Ubuntu PGDG repository
***********************************************

Please refer to the `APT PGDG repository documentation
<https://apt.postgresql.org>` for the initial setup (which should already be
done if you have PostgreSQL installed), and simply install
``powa-web``.  For instance:

.. code-block:: bash

  sudo apt-get install powa-web

Then, jump on the :ref:`next section<powa-web-config>` to configure powa-web.


Manual installation
*******************

You'll need the following dependencies:

    * `python >= 3.6 <https://www.python.org/>`_
    * `psycopg2 <https://www.psycopg.org/>`_
    * `tornado >= 2.0 <https://www.tornadoweb.org/>`_

.. tabs::

  .. code-tab:: bash RHEL / Rocky

    # Enable the EPEL repository
    sudo dnf install -y epel-release
    crb enable

    # install the dependencies
    sudo dnf install -y python3 python3-psycopg2 python3-tornado

  .. code-tab:: bash Debian / Ubuntu

    sudo apt install -y python3 python3-psycopg2 python3-tornado

  .. code-tab:: bash Archlinux

    pacman -S python python-psycopg2 python-tornado


Then, download the latest release on `pypi
<https://pypi.org/project/powa-web/>`_,  uncompress it, and copy the sample
configuration file:

.. parsed-literal::

  wget |powa_web_download_link|
  tar -zxvf powa-web-|powa_web_release|.tar.gz
  cd powa-web-|powa_web_release|
  cp ./powa-web.conf-dist ./powa-web.conf
  ./powa-web

Then, jump on the :ref:`next section<powa-web-config>` to configure powa-web.

.. _powa-web-config:

Configuration
*************

The powa-web configuration is stored as a simple python file.
Powa-web will search its configuration in either of these files, in this order:

* /etc/powa-web.conf
* ~/.config/powa-web.conf
* ~/.powa-web.conf
* ./powa-web.conf

You'll then be notified of the address and port on which the UI is available.
The default is 0.0.0.0:8888, as indicated in this message:

  .. code-block::

    [I 161105 20:27:39 powa-web:12] Starting powa-web on 0.0.0.0:8888

The following options are required:

servers (dict):
  A dictionary mapping PoWA repository server names to their connection
  information.

  .. code-block:: python

    servers={
      'main': {
        'host': 'localhost',
        'port': '5432',
        'database': 'powa'
      }
    }

.. warning::

  If any of your databases is not in **utf8** encoding, you should specify a
  client_encoding option as shown below. This requires at least psycopg2 version
  2.4.3

 .. code-block:: python

    servers={
      'main': {
        'host': 'localhost',
        'port': '5432',
        'database': 'powa',
        'query': {'client_encoding': 'utf8'}
      }
    }

.. note::

  You can set a username and password to allow logging into powa-web without
  providing credentials.  In this case, the powa-web.conf file must be modified
  like this:

 .. code-block:: python

    servers={
      'main': {
        'host': 'localhost',
        'port': '5432',
        'database': 'powa',
        'username' : 'pg_username',
        'password' : 'the password',
        'query': {'client_encoding': 'utf8'}
      }
    }


cookie_secret (str):
  A secret key used to secure cookies transiting between the web browser and the
  server.

  .. code-block:: python

    cookie_secret="SECRET_STRING"

The following options are optional:

port (int):
  The port on which the UI will be available (default 8888)


address (str):
  The IP address on which the UI will be available (default 0.0.0.0)

certfile (str):
  Path to certificate file, to allow HTTPS traffic (keyfile is also required)

keyfile (str)/
  Path to certificate private key file, to allow HTTPS traffic (certfile is
  also required)

url_prefix (str):
  Custom URL prefix the UI should be available on

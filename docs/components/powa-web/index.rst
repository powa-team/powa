.. _powa_web:

PoWA-web
========

.. _powa-web-manual-installation:

Install
*******

You can install PoWA-web either using `pip <https://pypi.org/>`_ or
manually.

Install with pip
----------------

On Centos 6, you can avoid installing the header files for Python and PostgreSQL
by using the package for psycopg2:


.. code-block:: bash

  yum install python-pip python-psycopg2
  pip install powa-web


Install on Red Hat / CentOS / Fedora / Rocky Linux
--------------------------------------------------

The RPM package is available on the PostgreSQL YUM Repository. Follow the 
installation guidelines below to add this repository to your system:

https://www.postgresql.org/download/linux/redhat/

Then install the package with:

.. code-block:: bash
    yum install powa_13-web

Replace `13` by the major version number of the PostgreSQL instance.


Manual install
**************

You'll need the following dependencies:

    * `python 2.6, 2.7 or > 3 <https://www.python.org/>`_
    * `psycopg2 <https://www.psycopg.org/>`_
    * `sqlalchemy > 0.9.8 <https://www.sqlalchemy.org/>`_
    * `tornado >= 2.0 <https://www.tornadoweb.org/>`_

.. admonition:: debian

  .. code-block:: bash

    apt-get install python python-psycopg2 python-sqlalchemy python-tornado


.. admonition:: archlinux

  .. code-block:: bash

    pacman -S python python-psycopg2 python-sqlalchemy python-tornado




.. admonition:: fedora

  .. code-block:: bash

    TODO


Then, download the latest release on `pypi <https://pypi.org/project/powa-web/>`_,  uncompress it, and copy the sample configuration file:

.. parsed-literal::

  wget |powa_web_download_link|
  tar -zxvf powa-web-|powa_web_release|.tar.gz
  cd powa-web-|powa_web_release|
  cp ./powa-web.conf-dist ./powa-web.conf
  ./powa-web

Then, jump on the next section to configure powa-web.

.. note::

    If you need to install `powa-web` on CentOS 6, here's a workaround to
    install sqlalchemy 0.8:

    * An RPM can be found at `this address
      <https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/Packages/p/python-sqlalchemy0.8-0.8.2-4.el6.x86_64.rpm>`_
    * After installing the RPM, it's required to perform

      .. code-block:: bash

          ln -s /usr/lib64/python2.6/site-packages/SQLAlchemy-0.8.2-py2.6-linux-x86_64.egg/sqlalchemy /usr/lib64/python2.6/site-packages/



Configuration
*************

The powa-web configuration is stored as a simple python file.
Powa-web will search its config as either of these files, in this order:

* /etc/powa-web.conf
* ~/.config/powa-web.conf
* ~/.powa-web.conf
* ./powa-web.conf

You'll then be noticed of the address and port on which the UI is available.
The default is 0.0.0.0:8888, as indicated in this message:

* [I 161105 20:27:39 powa-web:12] Starting powa-web on 0.0.0.0:8888

The following options are required:

servers (dict):
  A dictionary mapping server names to connection information.

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

See also:

.. toctree::
  :maxdepth: 1

  deployment.rst
  development.rst

PoWA-web
========


Installation
************

You can install PoWA-web either using `pip <http://pypi.python.org>`_ or
manually.

On Centos 6, you can avoid installing the header files for Python and PostgreSQL
by using the package for psycopg2:


.. code-block:: bash

  yum install python-pip python-psycopg2
  pip install powa-web


Manual install
--------------

You'll need the following dependencies:

    * `python <http://www.python.org>`_
    * `psycopg2 <http://initd.org/psycopg/>`_
    * `sqlalchemy >= 0.7.2 <http://sqlalchemy.org>`_
    * `tornado >= 2.0 <http://tornadoweb.org>`_


.. admonition:: debian

  .. code-block:: bash

    apt-get install python python-psycopg2 python-sqlalchemy python-tornado


.. admonition:: archlinux

  .. code-block:: bash

    pacman -S python python-psycopg2 python-sqlalchemy python-tornado




.. admonition:: fedora

  .. code-block:: bash

    TODO


Then, download the latest release on `pypi <https://pypi.python.org/pypi/powa-web/>`_,  uncompress it, and copy the sample configuration file:

.. parsed-literal::

  wget |powa_web_download_link|
  tar -zxvf powa-web-|powa_web_release|
  cd powa-web-|powa_web_release|
  cp ./powa-web.conf-dist ./powa-web.conf
  ./powa-web

Then, jump on the next section to configure powa-web.



Configuration
*************

The powa-web configuration is stored as a simple python file.
Powa-web will search its config as either of these files, in this order:

* /etc/powa-web.conf
* ~/.config/powa-web.conf
* ~/.powa-web.conf
* ./powa-web.conf

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
cookie_secret (str):
  A secret key used to secure cookies transiting between the web browser and the
  server.

  .. code-block:: python

    cookie_secret="SECRET_STRING"


See also:

.. toctree::
  :maxdepth: 1

  deployment.rst
  development.rst

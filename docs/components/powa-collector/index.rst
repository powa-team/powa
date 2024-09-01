.. _powa_collector:

powa-collector
==============

.. _powa-collector-manual-installation:

Install
************

You can install PoWA Collector either using `pip <https://pypi.org/>`_, RPM 
packages or manually.

Install with pip
--------------------

On Centos 6, you can avoid installing the header files for Python and
PostgreSQL by using the package for psycopg2:


.. code-block:: bash

    yum install python-pip python-psycopg2
    pip install powa-collector


Install on Red Hat / CentOS / Fedora / Rocky Linux
-----------------------------------------------------

The RPM package is available on the PostgreSQL YUM Repository. Follow the
installation guidelines below to add this repository to your system:

https://www.postgresql.org/download/linux/redhat/

Then install the package with:

.. code-block:: bash

    yum install powa_collector


Manual install
--------------

You'll need the following dependencies:

    * `python 2.6, 2.7 or > 3 <https://www.python.org/>`_
    * `psycopg2 <https://www.psycopg.org/>`_

.. admonition:: debian

  .. code-block:: bash

    apt-get install python python-psycopg2


.. admonition:: archlinux

  .. code-block:: bash

    pacman -S python python-psycopg2




.. admonition:: fedora

  .. code-block:: bash

    TODO


Then, download the latest release on `pypi
<https://pypi.python.org/pypi/powa-collector/>`_,  uncompress it, and copy the
sample configuration file:

.. parsed-literal::

  wget |powa_collector_download_link|
  tar -zxvf powa-collector-|powa_collector_release|.tar.gz
  cd powa-collector-|powa_collector_release|
  cp ./powa-collector.conf-dist ./powa-collector.conf
  ./powa-collector

Then, jump on the next section to configure powa-collector.


Configuration
*************

The powa-collector configuration is stored as a simple JSON file.
Powa-collector will search its config as either of these files, in this order:

* /etc/powa-collector.conf
* ~/.config/powa-collector.conf
* ~/.powa-collector.conf
* ./powa-collector.conf

The following options are required:

repository.dsn (string):
  An URI to tell powa-collector how to connect on the dedicated repository powa
  database where to store data for all remote instances.

The following options are optional:

debug (boolean):
  A boolean to specify whether powa-collector should be launched in debug mode,
  providing a more verbose output, useful for debug purpose.


Example configuration file:

.. code-block:: python

    {
        "repository": {
            "dsn": "postgresql://powa_user@localhost:5432/powa"
        },
        "debug": false
    }

.. warning::

    The collector needs to be able to connect on the **repository server** and
    all the declared **remote servers**.

Usage
*****

To start the program, simply run the powa-collector.py program.  A ``SIGTERM``
or a ``Keyboard Interrupt`` on the program will cleanly stop all the thread and
exit the program.  A ``SIGHUP`` will reload the configuration.


See also:

.. toctree::
  :maxdepth: 1

  protocol.rst

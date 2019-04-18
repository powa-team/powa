.. _stat_extensions:

Stats Extensions
================

The PoWA-archivist collects data from various stats extensions. To be used in
PoWA, a stat extensions has to expose a number of PL/pgSQL functions as stated
in :ref:`integration_with_powa`.

Currently, the list of supported stat extensions is as follows:

.. toctree::
  :maxdepth: 1

  pg_stat_statements.rst
  pg_qualstats.rst
  pg_stat_kcache.rst
  pg_wait_sampling.rst
  pg_track_settings.rst

All those extensions have to be installed on the dedicated powa database of the
monitored server.

.. note::

    pg_track_settings has to be also be installed on the dedicated repository
    server if :ref:`remote_setup` configuration is used.

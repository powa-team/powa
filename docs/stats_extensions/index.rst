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

Impact on performances
================================

Using PoWA will have a small negative impact on your PostgreSQL server performances. It is hard to evaluate precisely this impact but we can analyze it in 3 parts :

* First of all, you need to activate the `pg_stat_statements <http://www.postgresql.org/docs/current/static/pgstatstatements.html>`_ module. This module itself may slow down your instance, but some benchmarks show that the impact is not that big.

* Second, the PoWA collector should have a very low impact, but of course that depends on the frequency at which you collect data. If you do it every 5 seconds, you'll definitely see something. At 5 minutes, the impact should be minimal.

* And finally the POWA GUI will have an impact too if you run it on the PostgreSQL instance, but it really depends on many user will have access to it.


All in all, we strongly feel that the performance impact of POWA is nothing compared to being in the dark and not knowing what is running on your database. And in most cases the impact is lower than setting ``log_min_duration_statement = 0``.

See our own benchmark for more details:

* `PoWA vs The Badger <https://github.com/dalibo/powa/wiki/POWA-vs-pgBadger>`_

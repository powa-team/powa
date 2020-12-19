Impact on performances
======================

Using PoWA can have a small negative impact on your PostgreSQL server
performances. It is hard to evaluate precisely this impact, as it can come from
different parts.

First of all, you need to activate at least `pg_stat_statements
<https://www.postgresql.org/docs/current/pgstatstatements.html>`_
extension, and possibly the other supported :ref:`stat_extensions` of your choice.
Those extensions can slow down your instance, depending on how you
configure them.

If you don't use the :ref:`remote_setup` mode, the data will be stored locally
on a regular basis.  Depending on the snapshot frequency, the overhead could be
important.  You also have to consider disk usage, which will impact at least
the backups.

Using the UI will also run queries on your databases.  With the
:ref:`remote_setup` mode, there should be very few queries run on the target
databases though.

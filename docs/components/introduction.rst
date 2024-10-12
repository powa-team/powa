.. _components_intro:

Introduction to the PoWA components
===================================

PoWA is a highly extensible tool.  PostgreSQL needs and usage vary for
everyone, so not a single set of metrics is ideal for all usecases.  In order
to provide the best experience for everyone, all the metrics (or datasources)
can be configured to suits your specific needs, choosing the one you want or do
not want and even adding your own.

Different kind of metrics
-------------------------

PoWA supports 3 kind of metrics, that each correspond to a different way of
retrieving data from your instance:

- **stat extensions**: those provide the most useful and low-level information,
  and require installing extensions, either from the contrib or from the list
  of community provided extensions.
- **modules**: those provide access to instance wide catalog information
- **database modules**: those provide access to database-local catalog
  information

The definition and configuration for all those metrics are stored in powa
catalogs, and can be enabled or disabled at any time, and can even be
dynamically extended with user-defined information so that PoWA retrieves your
specific data, without any modification to PoWA itself.

The list of known components, whether they're enabled or not and the rest of
the associated details is available in the powa-web UI, in the **configuration
page** for each remote server.

Stat extensions
---------------

Those are the most wildly used components, as they can provide really useful
and low level performance information.  They usually store metrics on all the
databases in shared memory, and expose all the counters from a place.  The most
famous stat extension (and the only mandatory one) is
:ref:`pg_stat_statements_doc`, but a lot more are supported.  You can find the
list of supported stat extensions at :ref:`stat_extensions`.

If you wrote you own extension, and want to retrieves metrics for another
extension that isn't supported, you can look at :ref:`integration_with_powa`
documentation for more details.

They are available in either the **local mode** or the **remote mode** (see the
:ref:`local_vs_remote` page for more details).

Modules
-------

Those are a bit similar to the stat extensions.  They provide access to
information that is not specific to a single database but for either all of
them, or the instance itself.  The main difference is that they are fully
defined in plain SQL.

Some example of modules are metrics for the **pg_stat_xxx** system views (e.g.
**pg_stat_archiver**, **pg_stat_bgwriter** or **pg_stat_replication**).  The
shared catalog caching (**pg_database** and **pg_role**) also rely on this
infrastructure.

They are only available in the **remote mode** (see the :ref:`local_vs_remote`
page for more details).

Database modules
----------------

Those are mostly the same as plain modules, except that they can will be
collected on the wanted subset of database(s) that you define.  As a
consequence, they can access database-local metrics that are not accessible for
the other kind of metic source.  They are also defined in plain SQL, and also
have builtin support for multiple major PostgreSQL versions so that you can
write different queries for the various major PostgreSQL version to ease
backward compatibility.

Some example of database modules are **pg_stat_all_indexes**,
**pg_stat_all_tables** and **pg_stat_user_functions** system views.
Database-local catalogs (e.g. **pg_class**, **pg_attribute**, ...) also rely on
this infrastructure.

They are only available in the **remote mode** (see the :ref:`local_vs_remote`
page for more details).

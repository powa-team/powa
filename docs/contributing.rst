Contributing
============

POWA is an open project available under the PostgreSQL License. Any
contribution to build a better tool is welcome.


Talk
----

If you have ideas or feature requests, please post them to our general bug
tracker: https://github.com/powa-team/powa/issues

You can also join the **#powa** IRC channel on the `IRC libera server
<https://libera.chat/>`_.

Test
----

If you've found a bug, please refer to :ref:`support` page to see how to report
it.

Code
----

PoWA is composed of multiples tools:

* a background worker, see :ref:`powa_archivist`
* a collector daemon, see :ref:`powa_collector`
* stats extensions, see :ref:`stat_extensions`
* a UI, see :ref:`powa_web`
* external extensions:

    * :ref:`hypopg_doc`
    * :ref:`pg_wait_sampling_doc`
    * :ref:`pg_track_settings_doc`

Documentation
-------------

To build the documentation in HTML format, run:

::

    (.venv) $ make -C docs html

and open ``docs/_build/html/index.html`` to browse the result.

Alternatively, keep the following command running:

::

    (.venv) $ make -C docs serve

to get the documentation rebuilt and along with a live-reloaded Web browser.

Security
==============

.. warning::


  **You need to be careful about the security of your PostgreSQL instance when installing PoWA.**

We designed POWA so that the user interface will only communicate with PostgreSQL via prepared statements. This will prevent the risk of `SQL injection <http://xkcd.com/327/>`_.

However to connect to the PoWA User Interface, you will use the login and password of a PostgreSQL user. If you don't protect your communications, an attacker placed between the GUI and PostgreSQL, or between you and the GUI, could gain your user rights to your database server.

Therefore we **strongly** recommend the following precautions:

* `Read the Great PostgreSQL Documentation <http://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html>`_
* Check your *pg_hba.conf* file
* Do not allow users to access PoWA from the Internet
* Do not allow users to access PostgreSQL from the Internet
* Run PoWA on a HTTPS server and disable HTTP access
* Use SSL to protect the connection between the GUI and PostgreSQL
* Reject unprotected connections between the GUI and PostgreSQL (*hostnossl .... reject*)
* Check your *pg_hba.conf* file again

Please also note that you need to manually authorize the roles to see the data
in the powa database. For instance, you might run:

.. code-block:: sql

  powa=# GRANT SELECT ON ALL TABLES IN SCHEMA public TO ui_user;
  powa=# GRANT SELECT ON pg_statistic TO ui_user;

User objects
------------

powa-web will connect to the databases you select to help you optimize them.

Therefore, for each postgres roles using powa, you also need to:

  * grant **SELECT** privilege on the pg\_statistic and the user tables (don't
    forget tables that aren't in the public schema).
  * give **CONNECT** privilege on the databases.

If you don't, some useful parts of the UI won't work as intended.

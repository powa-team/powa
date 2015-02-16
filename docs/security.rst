Security
==============


**You need to be careful about the security of your PostgreSQL instance when installing PoWA.**

We designed POWA so that the user interface will only communicate with PostgreSQL via prepared statements. This will prevent the risk of `SQL injection <http://xkcd.com/327/>`_.

However to connect to the PoWA User Interface, you will use the login and password of a postgeSQL superuser. If you don't protect your communications, an attacker placed between the GUI and PostgreSQL, or between you and the GUI, could gain superuser rights to your database server.

Therefore we **strongly** recommend the following precautions:

* `Read the Great PostgreSQL Documentation <http://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html>`_
* Check your *pg_hba.conf* file
* Do not allow users to access PoWA from the Internet
* Do not allow users to access PostgreSQL from the Internet
* Run PoWA on a HTTPS server and disable HTTP access
* Use SSL to protect the connection between the GUI and PostgreSQL
* Reject unprotected connections between the GUI and PostgreSQL (*hostnossl .... reject*)
* Check your *pg_hba.conf* file again



PostgreSQL Workload Analyzer User Interface
============================================

Overview
--------

/!\ WARNING /!\
-------------------------

__You need to be careful about the security of your PostgreSQL server when installing POWA.__

We designed POWA so that the user interface will only communicate with PostgreSQL via prepared statements. This will prevent the risk of [SQL injection](http://xkcd.com/327/).

However to connect to the POWA User Interface, you will use the login and password of a postgeSQL superuser (see [README.md](https://github.com/dalibo/powa/blob/master/README.md) for more details). If you don't protect your communications, an attacker placed between the GUI and PostgreSQL, or between you and the GUI, could gain superuser rights to your database server. 

Therefore we **strongly** recommend the following precautions :

* [Read the Great PostgreSQL Documentation](http://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html)
* Check your ``pg_hba.conf`` file
* Do not allow users to access POWA from the Internet 
* Do not allow users to access PostgreSQL from the Internet
* Run POWA on a HTTPS server and disable HTTP access 
* Use SSL to protect the connection between the GUI and PostgreSQL
* Reject unprotected connections between the GUI and PostgreSQL (``hostnossl .... reject``)
* Check your ``pg_hba.conf`` file again


Prerequisites
-------------

The versions showed have been tested, it may work with older versions

* Perl 5.10
* Mojolicious 4.75
* PostgreSQL 9.3
* A CGI/Perl webserver

Install
-------

Install powa extension and configure it as seen it main README.powa file.


Install other prerequisites: Mojolicious is available on CPAN and
sometimes packages, for example the package in Debian is
`libmojolicious-perl`

If the needed version is not available anymore on you distribution, you can
download Mojolicious 4.75 [here](http://backpan.perl.org/authors/id/S/SR/SRI/Mojolicious-4.75.tar.gz).

Copy `powa.conf-dist` to `powa.conf` and edit it.

To quickly run the UI, do not activate `rewrite` in the config (this
is Apache rewrite rules when run as a CGI) and start the morbo
webserver inside the source directory:

    morbo script/powa

It will output what is printed to STDOUT/STDOUT in the code in the
term. The web pages are available on http://localhost:3000/

To run the UI with Apache, here is an example using CGI:

    <VirtualHost *:80>
        ServerAdmin webmaster@example.com
        ServerName powa.example.com
        DocumentRoot /var/www/powa/public/

        <Directory /var/www/powa/public/>
            AllowOverride None
            Order allow,deny
            allow from all
            IndexIgnore *

            RewriteEngine On
            RewriteBase /
            RewriteRule ^$ powa.cgi [L]
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^(.*)$ powa.cgi/$1 [L]
        </Directory>

        ScriptAlias /powa.cgi /var/www/powa/script/powa
        <Directory /var/www/powa/script/>
            AddHandler cgi-script .cgi
            Options +ExecCGI
            AllowOverride None
            Order allow,deny
            allow from all
            SetEnv MOJO_MODE production
            SetEnv MOJO_MAX_MESSAGE_SIZE 4294967296
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/powa.log
        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}/powa.log combined
    </VirtualHost>

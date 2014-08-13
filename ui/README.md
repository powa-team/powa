PostgreSQL Workload Analyszer User Interface
============================================

Overview
--------


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

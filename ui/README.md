PostgreSQL Workload Analyzer User Interface
============================================

Overview
--------

You can run the POWA User Interface in various ways : as Perl webservice (Morbo), as a CGI with Apache or with Nginx (as a reverse proxy in front of Hypnotoad).

But first let's talk about safety:

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
* Perl DBI and DBD-Pg modules
* PostgreSQL 9.3
* A CGI/Perl webserver

Install
-------

Install powa extension and configure it as seen it main README.md file.


Install other prerequisites: Mojolicious is available on CPAN and
sometimes packages, for example the package in Debian is
`libmojolicious-perl`

If the needed version is not available anymore on your distribution, you can
download Mojolicious 4.75 [here](http://backpan.perl.org/authors/id/S/SR/SRI/Mojolicious-4.75.tar.gz).

As you are then not using a package, you may not want to install Mojolicious globally on your system. So here is how to install it locally (let's say you installed powa in /path/to/powa):

    perl Makefile.PL PREFIX=/path/to/powa/mojo
    make install

Check that make tells you the files have been copied to /path/to/powa/mojo.

Now, you'll just have to tell perl that there is an extension in /path/to/powa/mojo (we'll see that with the morbo command below).

Copy `powa.conf-dist` to `powa.conf` and edit it.

If you have multiple PostgreSQL servers with PoWA installed, you can configure them in the `powa.conf` file, in the **servers** section. Each entry is of the form **"name": { info... }**, and must be coma separated.

For instance, if you have a production server listening on 10.0.0.1, port 5432 and a development server listening on 10.0.0.2, port 5433, the **servers** section should look like :
```
    ...
    "servers" : {
        "production" : {
            "dbname"   : "powa",
            "host"     : "10.0.0.1",
            "port"     : "5432"
        },
        "development" : {
            "dbname"   : "powa",
            "host"     : "10.0.0.2",
            "port"     : "5433"
        }
    },
    ...
```

**CAREFUL:** If upgrading from PoWA 1.1 or PoWA 1.2, you need to change the format of the
database section. See INSTALL.md in PoWA main directory for more details.

Run With Morbo
-------------------

To quickly run the UI, do not activate `rewrite` in the config (this
is Apache rewrite rules when run as a CGI) and start the morbo
webserver inside the source directory:

    morbo script/powa

If you have installed Mojolicious locally, you'll have to do this command instead (the paths may vary depending on where you run this command from):

    PERL5LIB=/path/to/powa/mojo/share/perl5/site_perl mojo/bin/site_perl/morbo ui/script/powa

Of course, putting PERL5LIB and PATH in your .bashrc file wouldn't be a bad idea...

It will output what is printed to STDOUT/STDOUT in the code in the
term. The web pages are available on http://localhost:3000/

Run With Apache
-------------------------------

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

Run with Nginx
-------------------

If you want ot use Nginx, the best solution is probably to run Hypnotoad behind a reverse proxy:

More details here : http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Nginx

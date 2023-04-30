Deployment Options
==================


PoWA can be deployed easily using multiple methods.

First you have to install and configure PoWA and `powa-web` like in the
`quickstart` section.  Check that the powa-web executable works before
proceeding.

Powa-web script
---------------

The easiest option is to rely only on the provided `powa-web` script.  You can
configure it to serve HTTPS traffic, however it's not recommended to expose it
directly but instead configure a reverse proxy like NGINX.

NGINX
-----

You can use NGINX as a reverse proxy to `powa-web`. It makes it possible to
bind it to system ports (lower than 1024), and add HTTPS.

Just add a new site to your configuration. Depending on your distribution, it will be
somewhere like /etc/nginx/sites (RedHat derivatives), /etc/nginx/sites-available
(Debian derivatives, you'll have to then do a symlink to /etc/nginx/sites-enabled to enable this site).

Put this, for example, in the configuration file (if you just want HTTPS proxying, and no virtualhost):

.. code-block:: nginx

    server {
      listen 0.0.0.0:443 http2 ssl default_server;
      server_name _;

      ssl_certificate /etc/pki/tls/certs/self-signed.pem;
      ssl_certificate_key /etc/pki/tls/certs/self-signed.key;

      access_log /var/log/nginx/access.log upstream;
      error_log /var/log/nginx/error.log;

      client_max_body_size 15M;

      location / {
        proxy_pass http://127.0.0.1:8888;
      }
    }

You'll obviously need to produce certificates, which is out of scope of this documentation.

If you just need HTTP, just change listen to 0.0.0.0:80, and remove ssl. Something like this:

.. code-block:: nginx

    server {
      listen 0.0.0.0:80 http2 default_server;
      server_name _;

      ssl_certificate /etc/pki/tls/certs/self-signed.pem;
      ssl_certificate_key /etc/pki/tls/certs/self-signed.key;

      access_log /var/log/nginx/access.log upstream;
      error_log /var/log/nginx/error.log;

      client_max_body_size 15M;

      location / {
        proxy_pass http://127.0.0.1:8888;
      }
    }

Apache
------

.. note::

    The wsgi compatibility has been removed from tornado 6.1.0 and is not a
    recommended way to deploy powa-web anymore.

PoWA can also easily be deployed using Apache mod_wsgi module.

In your apache configuration file, you should:

 - load the mod_wsgi module
 - configure it.

The various python3.4 version in the paths below should be set your actual
python version:

.. code-block:: apache

  LoadModule wsgi_module modules/mod_wsgi.so
  <VirtualHost *:80>
    ServerName myserver.example.com

    DocumentRoot /var/www/

    ErrorLog /var/log/httpd/powa.error.log
    CustomLog /var/log/httpd/powa.access.log combined

    WSGIScriptAlias / /usr/lib/python3.4/site-packages/powa/powa.wsgi

    Alias /static /usr/lib/python3.4/site-packages/powa/static/
  </VirtualHost>

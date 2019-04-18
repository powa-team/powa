Deployment Options
==================


Apache
------

PoWA can easily be deployed using Apache mod_wsgi module.

First you have to install and configure Powa like in the `quickstart` section.
Check that the powa-web executable works before proceeding.



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

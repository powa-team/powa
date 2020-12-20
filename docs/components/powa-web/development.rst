Development
===========

This page acts as a central hub for resources useful for PoWA developers.



PoWA-Web
--------

This section only covers the most simple changes one would want to make to PoWA.
For more comprehensive documentation, see the Powa-Web project documentation
itself.

Clone the repository:

.. code:: bash

  git clone https://github.com/powa-team/powa-web/
  cd powa/
  make && sudo make install

To run the application, use run_powa.py, which will run powa in debug mode.
That means the javascript files will not be minified, and will not be compiled
into one giant source file.


CSS files are generated using `sass <https://sass-lang.com/>`.
Javascript files are splitted into AMD modules, which are managed by `requirejs
<https://requirejs.org/>` and compiled using `grunt <https://gruntjs.com/>`.

These projects depend on NodeJS, and NPM, its package manager, so make sure you are able to install them on your
distribution.

Install the development dependencies:

.. code:: bash

  npm install -g grunt-cli
  npm install .

Then, you can run ``grunt`` to update only the css files, or regenerate optimized
javascript builds with ``grunt dist``.

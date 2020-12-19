PoWA Documentation
=========================


See https://powa.readthedocs.io/

[![Documentation Status](https://readthedocs.org/projects/powa/badge/?version=latest)](https://powa.readthedocs.io/en/latest/?badge=latest)


Compile the doc
-----------------------------------

* Install Sphinx : ``apt-get install python-sphinx``

* Build : ``make html``

Sphinx Theme
------------------------------------------------------------

Install the [Read The Doc theme](https://github.com/snide/sphinx_rtd_theme):

``
        pip install sphinx_rtd_theme
``

And then add the following lines to the ``conf.py`` file:

``
	import sphinx_rtd_theme
	html_theme = "sphinx_rtd_theme"
	html_theme_path = [sphinx_rtd_theme.get_html_theme_path()]
``


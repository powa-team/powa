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
  cd powa-web/

Then, create a Python3 virtualenv and install the project dependencies:

.. code:: bash

  python3 -m venv .venv --upgrade-deps
  . .venv/bin/activate
  pip install -r requirements.txt

In case you want to contribute on the styles, first install the NodeJS dev dependencies:

.. code:: bash

  npm ci

After installing the dependencies, you can start the ViteJS development server with:

.. code:: bash

  npm run dev

This command launches a local server at http://localhost:5173 with hot module replacement,
enabling real-time updates as you modify the project files.

To run the application, use ``run_powa.py`` in the PoWA-Web project root, which will run PoWa in debug mode.

.. code:: bash

  cd powa-web/
  ./run_powa.py 
  [I 240718 09:13:07 run_powa:11] Starting powa-web on http://127.0.0.1:8888/

If you don't already have a running instance of PoWA, you can easily deploy an environment
for PoWa web development using `powa-podman <https://github.com/powa-team/powa-podman/tree/master/dev>`_.
This project provides container images and compose files in its dev directory.

Once you have cloned it, you can start the PoWA stack and specify your PoWA-Web development location.

PoWA-Web uses `ViteJS` and `Vue 3` for a more integrated and performant 
front-end development experience.
  
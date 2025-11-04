Welcome to @PROJECT_NAME@ Documentation
========================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   getting_started
   api_reference
   examples

Getting Started
---------------

This is a C++ project built with CMake and Conan.

Building the Project
^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Install dependencies
   conan install . --profile=release --build=missing

   # Configure
   cmake --preset=conan-release

   # Build
   cmake --build --preset=conan-release

API Reference
-------------

Core Components
^^^^^^^^^^^^^^^

.. doxygenclass:: Calculator
   :members:
   :protected-members:
   :private-members:

.. doxygennamespace:: core
   :members:
   :undoc-members:

Examples
--------

Basic Usage
^^^^^^^^^^^

.. code-block:: cpp

   #include <myproject/calculator.hpp>

   int main() {
       Calculator calc;
       auto result = calc.add(2, 3);
       return 0;
   }

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

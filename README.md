<h1>Load Tuner Library</h1>

This is a locally installable verion of the python Focus Load Tuner Library

<h3>Revision History</h3>

Created by Scott Schafer in July 2012.

Updated to Python 3, PEP 8 Style and for Windows 10 by Devon Donahue Nov 2018

Updated for CCMT-1808 iTuner by Devon Donahue August 2021
Class renamed; tuneto, loadfreq, functions added, communication with ituner changed

Activate the virtual environment using:

. venv/activate/bin
. venv/Scripts/activate

You need to have the project packaged to be able to run it in a test mode. the commands are:

python3 -m pip install build
python3 -m build --wheel
pip3 install dist/focustuner-0.1.0-py3-none-any.whl

python -m pip install build
python -m build --wheel
pip install dist/focustuner-0.1.0-py3-none-any.whl

and using:

python3 -m unittest discover

python -m unittest discover

to test the code

<h2> Library Creation </h2>
This library was created using instructions form https://medium.com/analytics-vidhya/how-to-create-a-python-library-7d5aea80cc3f
Frankly it was started more than once so there is a high probability there are unnecessary components. It was a valiant effort though. 

try number 2
https://medium.com/@tushar_datascience/creating-a-python-library-a-step-by-step-guide-with-a-simple-example-c87b653b9a4e

python setup.py sdist bdist_wheel
twine upload dist/*

this seems to do it

<h2> Start virtual environment </h2>

python -m venv venv
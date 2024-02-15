<h1>Load Tuner Library</h1>

This is a locally installable verion of the python Focus Load Tuner Library

<h3>Revision History</h3>

Created by Scott Schafer in July 2012.

Updated to Python 3, PEP 8 Style and for Windows 10 by Devon Donahue Nov 2018

Updated for CCMT-1808 iTuner by Devon Donahue August 2021
Class renamed; tuneto, loadfreq, funtions added, communication with ituner changed

You need to have the project packaged to be able to run it in a test mode. the commands are:

python3 -m pip install build
python3 -m build --wheel
pip3 install dist/loadtuner-0.1.0-py3-none-any.whl

and using:

python3 -m unittest discover

to test the code

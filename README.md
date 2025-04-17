Heimdallr is a package for simplifying instrument control. It is designed to build
off of libraries like [pyvisa](https://github.com/pyvisa/pyvisa) and [pyvisa-py](https://github.com/pyvisa/pyvisa-py)
and provide a complete ecosystem for instrument automation. As a brief example of
what this can look like in its simplest form, here's an example script which 
connects to an instrument, resets it, then adjusts and reads some basic settings:

subsixtest is a base repository for testing using the Sub-6 test bench. To perform tests using this system, it is recommended that the respository is forked. This repository is not editable directly for testing. There are two test code enviorments: python and matlab. All post-processing plotting is done in matlab. Two python libraries that were developed in our group were used are used:[focustuner](https://pypi.org/project/focustuner/).   and [Heimdallr](https://pypi.org/project/Heimdallr/).   

# Hardware Set-up and Calibration procedure 

This will be documented when I have time to organize my hectic note taking. eta Sept. 2025

# Installation

To for do this:

Idk ask grant or Google

# TODO

### Technical detail: Category system and Drivers

- literally everything.

### Start virtual environment ###

For repo testing, a virtual enviorment was set up. This means all  required libraries can be found in... I am pretty sure there is a file

```
python -m venv venv
```

Activate for windows:

```
. venv\Scripts\activate
```

Activate for Mac:

```
. venv/bin/activate
```

# Operating Procedure #
Make sure system is cal'd both power and sparam (s first) and RF is off and driver is on. Double check connections. 


# Required packages #

```
pip install -r requirements.txt -y
```
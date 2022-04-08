# API_Arduino_IOPort

Code to access [Arduino](https://www.arduino.cc/) interface between MATLAB using [Psychtoobox](http://psychtoolbox.org/) **IOPort** function.

# Requirements
- MATLAB : probalby version superior to R2012b, due to class properties type.
- Psychtoolbox : http://psychtoolbox.org/

# Install
Clone or download this repo, and add it to MATLAB's path.

# Test / Demo script
Check this script:
- [test_adc](test_adc.m) for ADC => upload "arduino_adc.ino"
- [test_pp](test_pp.m) for Parallel Port => upload "arduino_pp.ino"

# Important
Arduino cannot work with both mods simultaniously : you have to choose (and upload) 1 program between "adc" and "pp"(parallel port)

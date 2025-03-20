# HDL_LAB Course Project
This HDL Lab focuses on the practical application of Verilog in designing and simulating the digital components of a pulse oximeter—a
widely used medical device for non-invasive measurement of blood oxygen saturation and pulse rate. The lab emphasizes the
integration of digital design with an analog frontend, simulated in Cadence Virtuoso, to model the interaction between the LEDs,
photodiodes, and the associated signal-processing circuitry.

This project has five main parts: 
  1. ADC design
  2. digital controller (FSM)
  3. FIR low-pass filter
  4. Synthesize and SDF back annotation (to meet timing constraints)
  5. Place & Route using Tcl

# ADC
The ADC is ideal and written in verilog-A language.

# FSM controller
The finite state controller is used to control the behavior of the two LED lights in the finger_clip model. It should be programmed to:
  1. In the first phase, adjust paras to best suit patients' condition （find DC compensation and PGA Gain）
  2. Once paras are found, enter the LED switching phase to measure the blood-oxygen level
  3. the measured data are then sent to two digital FIR filters

# FIR low-pass filter
Two FIR filters are designed, one for red light and one for infra-red. 

# Synthesize and SDF back annotation
Big pain.

# Place & Route using Tcl

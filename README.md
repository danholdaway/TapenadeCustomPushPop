# Custom interface for the Tapenade inline automatic differentiation software

By default Tapenade recomuptes the reference state trajectory to linearize around, but this can be slow in iterative models which linearize around the same reference state, such as in data assimilation.

This tool demonstrates the use of a custom interface to the Tapenade push/pop routines that can limit recomputation for an iterative model. The tool is demonstrated by using a simple quasi-linear one dimensional advection. The iterations are represented by calling the model multiple times with the same reference state initial conditions. The initial perturbations are also fixed, whereas in reality would change with each iteration; this doens't matter for the purposes of demonstration.

### This custom interface provides the following functionality:
* Hold checkpoints in a static array so that forward sweep of code can be tuned off after a few itations
* Compile time choice of precision
* 

## Getting Started

Compile the Tapenade/adBuffer.f and Tapenade/adStack.c following the instuctions issued by Inria Tapenade.

To compile the advection scheme, edit the compile.csh file with appropriate definition of intel and or gfortran compiler and issue ./compile.csh int or ./compile.csh gcc

Run the code with ./adv_1d.x

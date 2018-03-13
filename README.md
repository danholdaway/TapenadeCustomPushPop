# Custom interface for the Tapenade inline automatic differentiation software.

By default Tapenade recomuptes the reference state trajectory to linearize around, but this can be slow in iterative models, such as data assimilation.

## Getting Started

To compile, edit the compile.csh file with appropriate definition of intel and or gfortran compiler and issue ./compile.csh int or ./compile.csh gcc

Run the code with ./adv_1d.x

### Functionality

This custom interface provides the following functionality:

 - Hold checkpoints in a static array so that forward sweep of code can be tuned off after a few itations
 - 



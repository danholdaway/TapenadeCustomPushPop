## Custom interface for the Tapenade inline automatic differentiation software

By default Tapenade recomuptes the reference state trajectory to linearize around, acheived either in a single subroutine or seperately as a forward and then backward sweep. In iterative models which linearize around the same reference state repeatedly, such as in data assimilation, this leads to superfluous work being done. In data assimilation speed is of the essence and the recomputation can be too expensive. Conversely saving the reference state calculations requires more memory.

The enclosed software demonstrates the use of a custom interface to the Tapenade push/pop routines that can limit recomputation for an iterative model. The tool is demonstrated by using a simple one dimensional advection. The iterations are represented by calling the model multiple times with the same reference state initial conditions. The initial perturbations are also fixed, whereas in reality would change with each iteration; this doens't matter for the purposes of demonstration.

### This custom interface provides the following functionality:
* Hold checkpoints in a static array so that the forward sweep of code can be tuned off after three itations.
* Allows for compile time choice of precision of real variables. Tapenade typically requires this choice to be made before being generated.
* Can check whether a particular push/pop was actually necessary as thus reduce the overall memory footprint. This helps make the code useable in different applications. Such as in operational applications where large number of processors are used, versus research applications where fewer processors are avaialble.
* User can specify the amount of memory avaialble and the tool will revert to the usual Tapenade approach if exceeded.
* We plan to add the ability to profile particular subroutines memory footprint and number of calls to push/pop.

### Getting Started

Compile the Tapenade/adBuffer.f and Tapenade/adStack.c following the instuctions issued by Inria Tapenade.

To compile the advection scheme, edit the compile.csh file with appropriate definition of intel and or gfortran compiler and issue ./compile.csh int or ./compile.csh gcc

Run the code with ./adv_1d.x

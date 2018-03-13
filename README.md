# Project Title

Custom interface for the Tapenade inline automatic differentiation software.

By default Tapenade recomuptes the reference state trajectory to linearize around, but this can be slow in iterative models, such as data assimilation.

This custom interface provides the following functionality:

 - Hold checkpoints in a static array so that forward sweep of code can be tuned off after a few itations
 - 



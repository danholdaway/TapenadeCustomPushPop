
Custom interface for the Tapenade inline automatic differentiation software.

By default Tapenade recomuptes the reference state trajectory to linearize around, but this can be slow in iterative models, such as data assimilation.

This custom interface allows one to save the reference state in memory and eliminate the forward code sweep.



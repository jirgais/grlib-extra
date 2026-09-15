## LEON3/GRLIB

This is a mirror of LEON3/GRLIB from Gaisler with extra features added.
The development is done in the __extra-b4300__ branch, to simplify rebasing
to newer versions of grlib in the future.

## List of additional features

* Support for the [NVC simulator](https://github.com/nickg/nvc)

Use `make nvc` and `make nvc-run` to compile and simulate with NVC.

* IRIS Open-source FPU for LEON3

The IRIS open-source FPU implements single- and double-precision
floating-point operations according to the IEEE-754 standard. All four
rounding modes and sub-normal operands are fully supported. The FPU
implements all SP and DP FPU operations defined in the SPARC V8 standard,
including FSMULD. Compared to the GRFPU-Lite, IRIS is both smaller and
somewhat faster. The IRIS FPU is enabled in the xconfig menu for leon3
floating point units.


* [Uber DDR3 memory controller](https://github.com/AngeloJacobo/UberDDR3) for Xilinx FPGAs

The Uber DDR3 memory controller has been ported into GRLIB and can be used for Xilinx FPGAs.
The leon3-digilent-arty-a7 template design has been updated to use this controller. Uber DDR3
is both smaller and faster than the Xilinx DDR3 MIG, and fully open-source. 


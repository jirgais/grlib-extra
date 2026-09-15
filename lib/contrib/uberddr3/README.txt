
Uber DDR3 controller
--------------------

This is a slightly modifed version of the open-source Uber DDR3 memory
controller. The modifications consist of conversion of some modules to
VHDL and the addition of a AMBA AHB-2.0 interface.

The original source code can be found at:

    https://github.com/AngeloJacobo/UberDDR3

To use the IP in a template design, and the following to the Makefile:

  DIRADD = uberddr3 vivado
  DIRSKIP = ise

To simulate the design, do:

  make distclean
  make install-unisim-vivado
  make vsim

Some simulators cannot simulate the verilog controller properly, these
include NVC and Modelsim-2024. Simulators know top work are Vivado XSim,
Questasim-2023 and some earlier Modelsim versions with the -novopt switch.

The leon3-arty-a7 template design uses the UberDDR3 controller and can
be used as reference.

Jiri Gaisler, 2026.

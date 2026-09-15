---------------------------------------
IRIS open-source floating-point unit
---------------------------------------
Version 1.0, Jiri Gaisler, 2026
---------------------------------------

The IRIS open-source FPU implements single- and double-precision
floating-point operations according to the IEEE-754 standard. All four
rounding modes and sub-normal operands are fully supported. The FPU
implements all SP and DP FPU operations defined in the SPARC V8 standard,
including FSMULD.

The FPU is functionally compatible with the Meiko FPU used in
Sun microsparc processors. The individual instruction timings
might vary slightly between IRIS and Meiko, but the calculated values
are identical for any type of operation and inputs. IRIS also supports
the FSMULD instruction which Meiko does not.

The IRIS FPU consists of three files:

  iris_mul.vhd     -- multiplier
  iris_div.vhd     -- divider
  irifpu.vhd       -- main datapath and top-level unit

  grlfpu_iris.vhd  -- wrapper to emulate grfpu-lite (not used)

  iris_manual.pdf  -- design manual

A leon3 floating-point controller for IRIS is provided in
lib/gaisler/leon3v3/irisfpc.vhd . This controller intefaces IRIS to the
leon3 pipeline and also implements the SPARC FPU registers %fsr, %fq and
%f0 - %f31.

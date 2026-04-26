
IRIS open-source FPU testbench
Version 1.0, Jiri Gaisler, 2025
---------------------------------------

The IRIS open-source FPU is functionally compatible with the Meiko FPU
used in Sun microsparc processors. The individual instruction timings
might vary slightly between IRIS and Meiko, but the calculated values
are identical for any type of operation and inputs.

A testbench to validate the operation of the IRIS is provided here.
To run the two pre-compiled test vector files aocs.txt and paranoia.txt, do:

    make nvc
    make tests

This will compile the IRIS FPU and testbench with nvc and run the two tests.

This testbench can also generate testfloat vectors. This requires that
the binary 'testfloat_gen' is in the executable path. Do:

    make testfloat

to generate 4 testfloat mixes: tfmix_near.txt, tfmix_zero.txt, tfmix_up.txt
and tfmix_down.txt . Make sure you are using release 3 of testfloat.

To simulate the testfloat mixes, do:

    make simtestfloat

It will take about 10 minutes to run all four tests. Do 'make clean' to remove
all generated tests.

You can also start the testbench interactively with vsim:

    make vsim
    vsim testbench -do wave.do


Good luck, Jiri.

include .config

GRLIB=../..
TOP=irisfpu
BOARD=gr-xc6s
include $(GRLIB)/boards/$(BOARD)/Makefile.inc
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
#UCF=$(GRLIB)/boards/$(BOARD)/$(TOP).ucf
UCF=leon3mp.ucf
QSF=$(GRLIB)/boards/$(BOARD)/$(TOP).qsf
EFFORT=high
ISEMAPOPT=-timing
XSTOPT=
SYNPOPT="set_option -pipe 0; set_option -retiming 0; set_option -write_apr_constraint 0"
VHDLSYNFILES=
VHDLSIMFILES=testbench.vhd
SIMTOP=testbench
#SDCFILE=$(GRLIB)/boards/$(BOARD)/default.sdc
SDCFILE=default.sdc
BITGEN=$(GRLIB)/boards/$(BOARD)/default.ut
CLEAN=soft-clean
VCOMOPT=-explicit +acc
TECHLIBS=umc18

NVCRUNOPT += --ieee-warnings=off -H 1g

LIBADD = contrib
DIRADD = irisfpu
LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip hynix cypress ihp gsi fmf spansion swp eth
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest ddr \
	leon4v0 l2cache/v2 l2cache/v3 l2cache/str gr1553b iommu ascs slink pwm \
	ge_1000baseX canfd \
	leon5v0 leon5v0/blockred grfpu5 noelv noelv/subsys riscv leon3v3 \
  greth jtag debug sim net irqmp srmmu leon5v0
FILESKIP = grcan.vhd adapters/sgmii.vhd \
	sf2apbslv_wrapper.vhd sf2ficmst_wrapper.vhd sf2ficslv_wrapper.vhd \
	sf2mddr_wrapper.vhd pfmddr_wrapper.vhd

include $(GRLIB)/bin/Makefile
include $(GRLIB)/software/leon3/Makefile

NVCXTRA = --work=work:nvc/work -L nvc -e -j -g

##################  project specific targets ##########################

paranoia:
	nvc $(NVCRUNOPT) $(NVCXTRA) filename=paranoia.txt $(SIMTOP) -r

aocs:
	nvc $(NVCRUNOPT) $(NVCXTRA) filename=aocs.txt $(SIMTOP) -r

near:
	nvc $(NVCRUNOPT) $(NVCXTRA) filename=tfmix_near.txt $(SIMTOP) -r

zero:
	nvc $(NVCRUNOPT) $(NVCXTRA) filename=tfmix_zero.txt $(SIMTOP) -r

up:
	nvc $(NVCRUNOPT) $(NVCXTRA) filename=tfmix_up.txt $(SIMTOP) -r

down:
	nvc $(NVCRUNOPT) $(NVCXTRA) filename=tfmix_down.txt $(SIMTOP) -r

testfloat:
	-mkdir testfloat
	cp scripts/* testfloat
	make -C testfloat all

simtestfloat:
	make near zero up down

all tests:
	make paranoia aocs

clean:
	-rm -rf testfloat tfmix_*.txt

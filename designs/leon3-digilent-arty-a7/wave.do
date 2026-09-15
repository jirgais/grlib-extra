onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/d3/rstn
add wave -noupdate /testbench/d3/clk333
add wave -noupdate /testbench/d3/eth_ref_clki
add wave -noupdate /testbench/d3/rstnraw
add wave -noupdate /testbench/d3/reset_button
add wave -noupdate /testbench/d3/lock
add wave -noupdate /testbench/d3/clkinmig
add wave -noupdate /testbench/d3/clkref
add wave -noupdate /testbench/d3/calib_done
add wave -noupdate /testbench/d3/migrstn
add wave -noupdate /testbench/d3/pll_locked
add wave -noupdate /testbench/d3/clkm
add wave -noupdate /testbench/d3/uber0/ddrc/calib_done
add wave -noupdate /testbench/d3/uber0/ddrc/calib_done_i
add wave -noupdate /testbench/d3/uber0/ddrc/l_wb_stb
add wave -noupdate /testbench/d3/uber0/ddrc/i_wb_cyc
add wave -noupdate /testbench/d3/uber0/ddrc/i_wb_stb
add wave -noupdate /testbench/d3/uber0/ddrc/i_wb_we
add wave -noupdate -radix hexadecimal /testbench/d3/uber0/ddrc/o_wb_data
add wave -noupdate -radix hexadecimal /testbench/d3/uber0/ddrc/i_wb_data
add wave -noupdate -radix hexadecimal /testbench/d3/uber0/ddrc/i_wb_addr
add wave -noupdate /testbench/d3/uber0/ddrc/i_wb_sel
add wave -noupdate /testbench/d3/uber0/ddrc/o_wb_ack
add wave -noupdate /testbench/d3/uber0/ddrc/o_wb_stall
add wave -noupdate -radix hexadecimal -childformat {{/testbench/d3/uber0/ddrc/r.bstate -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hready -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hsel -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hwrite -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.htrans -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hburst -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hsize -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hrdata -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hrdata2 -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.hwdata -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.haddr -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.wb_addr -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.wb_we -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.wb_sel -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.wcnt -radix hexadecimal} {/testbench/d3/uber0/ddrc/r.d1rdy -radix hexadecimal}} -expand -subitemconfig {/testbench/d3/uber0/ddrc/r.bstate {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hready {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hsel {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hwrite {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.htrans {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hburst {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hsize {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hrdata {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hrdata2 {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.hwdata {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.haddr {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.wb_addr {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.wb_we {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.wb_sel {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.wcnt {-height 32 -radix hexadecimal} /testbench/d3/uber0/ddrc/r.d1rdy {-height 31 -radix hexadecimal}} /testbench/d3/uber0/ddrc/r
add wave -noupdate /testbench/d3/uber_rst
add wave -noupdate -radix hexadecimal -childformat {{/testbench/d3/ddr3_dq(15) -radix hexadecimal} {/testbench/d3/ddr3_dq(14) -radix hexadecimal} {/testbench/d3/ddr3_dq(13) -radix hexadecimal} {/testbench/d3/ddr3_dq(12) -radix hexadecimal} {/testbench/d3/ddr3_dq(11) -radix hexadecimal} {/testbench/d3/ddr3_dq(10) -radix hexadecimal} {/testbench/d3/ddr3_dq(9) -radix hexadecimal} {/testbench/d3/ddr3_dq(8) -radix hexadecimal} {/testbench/d3/ddr3_dq(7) -radix hexadecimal} {/testbench/d3/ddr3_dq(6) -radix hexadecimal} {/testbench/d3/ddr3_dq(5) -radix hexadecimal} {/testbench/d3/ddr3_dq(4) -radix hexadecimal} {/testbench/d3/ddr3_dq(3) -radix hexadecimal} {/testbench/d3/ddr3_dq(2) -radix hexadecimal} {/testbench/d3/ddr3_dq(1) -radix hexadecimal} {/testbench/d3/ddr3_dq(0) -radix hexadecimal}} -subitemconfig {/testbench/d3/ddr3_dq(15) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(14) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(13) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(12) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(11) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(10) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(9) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(8) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(7) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(6) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(5) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(4) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(3) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(2) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(1) {-height 31 -radix hexadecimal} /testbench/d3/ddr3_dq(0) {-height 31 -radix hexadecimal}} /testbench/d3/ddr3_dq
add wave -noupdate /testbench/d3/ddr3_dqs_p
add wave -noupdate /testbench/d3/ddr3_dqs_n
add wave -noupdate -radix hexadecimal /testbench/d3/ddr3_addr
add wave -noupdate -radix hexadecimal /testbench/d3/ddr3_ba
add wave -noupdate /testbench/d3/ddr3_ras_n
add wave -noupdate /testbench/d3/ddr3_cas_n
add wave -noupdate /testbench/d3/ddr3_we_n
add wave -noupdate /testbench/d3/ddr3_reset_n
add wave -noupdate -expand /testbench/d3/ddr3_ck_p
add wave -noupdate /testbench/d3/ddr3_ck_n
add wave -noupdate /testbench/d3/ddr3_cke
add wave -noupdate /testbench/d3/ddr3_cs_n
add wave -noupdate -expand /testbench/d3/ddr3_dm
add wave -noupdate /testbench/d3/ddr3_odt
add wave -noupdate /testbench/d3/rstn
add wave -noupdate /testbench/led
add wave -noupdate -divider {CPU 1}
add wave -noupdate /testbench/d3/clkm
add wave -noupdate -radix hexadecimal /testbench/d3/apbi
add wave -noupdate -radix hexadecimal /testbench/d3/apbo
add wave -noupdate -radix hexadecimal -childformat {{/testbench/d3/ahbsi.hsel -radix hexadecimal} {/testbench/d3/ahbsi.haddr -radix hexadecimal} {/testbench/d3/ahbsi.hwrite -radix hexadecimal} {/testbench/d3/ahbsi.htrans -radix hexadecimal} {/testbench/d3/ahbsi.hsize -radix hexadecimal} {/testbench/d3/ahbsi.hburst -radix hexadecimal} {/testbench/d3/ahbsi.hwdata -radix hexadecimal} {/testbench/d3/ahbsi.hprot -radix hexadecimal} {/testbench/d3/ahbsi.hready -radix hexadecimal} {/testbench/d3/ahbsi.hmaster -radix hexadecimal} {/testbench/d3/ahbsi.hmastlock -radix hexadecimal} {/testbench/d3/ahbsi.hmbsel -radix hexadecimal} {/testbench/d3/ahbsi.hirq -radix hexadecimal} {/testbench/d3/ahbsi.testen -radix hexadecimal} {/testbench/d3/ahbsi.testrst -radix hexadecimal} {/testbench/d3/ahbsi.scanen -radix hexadecimal} {/testbench/d3/ahbsi.testoen -radix hexadecimal} {/testbench/d3/ahbsi.testin -radix hexadecimal} {/testbench/d3/ahbsi.endian -radix hexadecimal}} -expand -subitemconfig {/testbench/d3/ahbsi.hsel {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.haddr {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hwrite {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.htrans {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hsize {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hburst {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hwdata {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hprot {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hready {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hmaster {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hmastlock {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hmbsel {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.hirq {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.testen {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.testrst {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.scanen {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.testoen {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.testin {-height 32 -radix hexadecimal} /testbench/d3/ahbsi.endian {-height 32 -radix hexadecimal}} /testbench/d3/ahbsi
add wave -noupdate -radix hexadecimal /testbench/d3/ahbso
add wave -noupdate -radix hexadecimal -childformat {{/testbench/d3/ahbmi.hgrant -radix hexadecimal} {/testbench/d3/ahbmi.hready -radix hexadecimal} {/testbench/d3/ahbmi.hresp -radix hexadecimal} {/testbench/d3/ahbmi.hrdata -radix hexadecimal} {/testbench/d3/ahbmi.hirq -radix hexadecimal} {/testbench/d3/ahbmi.testen -radix hexadecimal} {/testbench/d3/ahbmi.testrst -radix hexadecimal} {/testbench/d3/ahbmi.scanen -radix hexadecimal} {/testbench/d3/ahbmi.testoen -radix hexadecimal} {/testbench/d3/ahbmi.testin -radix hexadecimal} {/testbench/d3/ahbmi.endian -radix hexadecimal}} -expand -subitemconfig {/testbench/d3/ahbmi.hgrant {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.hready {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.hresp {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.hrdata {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.hirq {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.testen {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.testrst {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.scanen {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.testoen {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.testin {-height 32 -radix hexadecimal} /testbench/d3/ahbmi.endian {-height 32 -radix hexadecimal}} /testbench/d3/ahbmi
add wave -noupdate -radix hexadecimal -childformat {{/testbench/d3/ahbmo(15) -radix hexadecimal} {/testbench/d3/ahbmo(14) -radix hexadecimal} {/testbench/d3/ahbmo(13) -radix hexadecimal} {/testbench/d3/ahbmo(12) -radix hexadecimal} {/testbench/d3/ahbmo(11) -radix hexadecimal} {/testbench/d3/ahbmo(10) -radix hexadecimal} {/testbench/d3/ahbmo(9) -radix hexadecimal} {/testbench/d3/ahbmo(8) -radix hexadecimal} {/testbench/d3/ahbmo(7) -radix hexadecimal} {/testbench/d3/ahbmo(6) -radix hexadecimal} {/testbench/d3/ahbmo(5) -radix hexadecimal} {/testbench/d3/ahbmo(4) -radix hexadecimal} {/testbench/d3/ahbmo(3) -radix hexadecimal} {/testbench/d3/ahbmo(2) -radix hexadecimal} {/testbench/d3/ahbmo(1) -radix hexadecimal} {/testbench/d3/ahbmo(0) -radix hexadecimal -childformat {{/testbench/d3/ahbmo(0).hbusreq -radix hexadecimal} {/testbench/d3/ahbmo(0).hlock -radix hexadecimal} {/testbench/d3/ahbmo(0).htrans -radix hexadecimal} {/testbench/d3/ahbmo(0).haddr -radix hexadecimal} {/testbench/d3/ahbmo(0).hwrite -radix hexadecimal} {/testbench/d3/ahbmo(0).hsize -radix hexadecimal} {/testbench/d3/ahbmo(0).hburst -radix hexadecimal} {/testbench/d3/ahbmo(0).hprot -radix hexadecimal} {/testbench/d3/ahbmo(0).hwdata -radix hexadecimal} {/testbench/d3/ahbmo(0).hirq -radix hexadecimal} {/testbench/d3/ahbmo(0).hconfig -radix hexadecimal} {/testbench/d3/ahbmo(0).hindex -radix hexadecimal}}}} -subitemconfig {/testbench/d3/ahbmo(15) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(14) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(13) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(12) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(11) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(10) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(9) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(8) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(7) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(6) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(5) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(4) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(3) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(2) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(1) {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0) {-height 32 -radix hexadecimal -childformat {{/testbench/d3/ahbmo(0).hbusreq -radix hexadecimal} {/testbench/d3/ahbmo(0).hlock -radix hexadecimal} {/testbench/d3/ahbmo(0).htrans -radix hexadecimal} {/testbench/d3/ahbmo(0).haddr -radix hexadecimal} {/testbench/d3/ahbmo(0).hwrite -radix hexadecimal} {/testbench/d3/ahbmo(0).hsize -radix hexadecimal} {/testbench/d3/ahbmo(0).hburst -radix hexadecimal} {/testbench/d3/ahbmo(0).hprot -radix hexadecimal} {/testbench/d3/ahbmo(0).hwdata -radix hexadecimal} {/testbench/d3/ahbmo(0).hirq -radix hexadecimal} {/testbench/d3/ahbmo(0).hconfig -radix hexadecimal} {/testbench/d3/ahbmo(0).hindex -radix hexadecimal}} -expand} /testbench/d3/ahbmo(0).hbusreq {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hlock {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).htrans {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).haddr {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hwrite {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hsize {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hburst {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hprot {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hwdata {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hirq {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hconfig {-height 32 -radix hexadecimal} /testbench/d3/ahbmo(0).hindex {-height 32 -radix hexadecimal}} /testbench/d3/ahbmo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {36588100 ps} 0} {{Cursor 3} {658465789 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 340
configure wave -valuecolwidth 329
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {63 us}

------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2026, Jiri Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; version 2.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-------------------------------------------------------------------------------
-- Package:     uber_ddr3_comp
-- File:        uber_ddr3_comp.vhd
-- Author:      Jiri Gaisler
--
--  Uber DDR3 controller components
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
use grlib.amba.all;

package uber_ddr3_comp is

  component ahb2uber is
  generic(
    hindex     : integer := 0;
    haddr      : integer := 0;
    hmask      : integer := 16#f00#;
    pindex     : integer := 0;
    paddr      : integer := 0;
    pmask      : integer := 16#fff#;
    litend     : integer := 0;
    CONTROLLER_CLK_PERIOD :integer := 12000; -- ps, clock period of the controller interface
    DDR3_CLK_PERIOD :integer := 3000; -- ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD)
    ROW_BITS : integer := 14; -- width of row address
    COL_BITS :integer := 10; -- width of column address
    BA_BITS : integer := 3; -- width of bank address
    BYTE_LANES : integer := 2; -- number of byte lanes of DDR3 RAM
    DUAL_RANK_DIMM : integer := 0; -- enable dual rank DIMM (1 =  enable, 0 = disable)
    SPEED_BIN : integer := 3; -- 0 = Use top-level parameters , 1 = DDR3-1066 (7-7-7) , 2 = DR3-1333 (9-9-9) , 3 = DDR3-1600 (11-11-11)
    SDRAM_CAPACITY : integer := 5; -- 0 = 256Mb, 1 = 512Mb, 2 = 1Gb, 3 = 2Gb, 4 = 4Gb, 5 = 8Gb, 6 = 16Gb
    MICRON_SIM : integer := 0; --enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
    ODELAY_SUPPORTED : integer := 0; --set to 1 when ODELAYE2 is supported
    SELF_REFRESH : integer := 0; -- 0 = use i_user_self_refresh input, 1 = Self-refresh mode is enabled after 64 controller clock cycles of no requests, 2 = 128 cycles, 3 = 256 cycles
    -- The next parameters act more like a localparam (since user does not have to set this manually) but was added here to simplify port declaration
    DQ_BITS : integer := 8 --device width (fixed to 8, if DDR3 is x16 then BYTE_LANES will be 2 while )
  );
  port(
    clk_amba    : in std_logic;
    rst_n_syn   : in std_logic;
    ahbso       : out ahb_slv_out_type;
    ahbsi       : in  ahb_slv_in_type;
    apbi   	    : in  apb_slv_in_type;
    apbo   	    : out apb_slv_out_type;
    -- DDR3
    ddr3_rst    : in std_logic;
    ddr3_clk    : in std_logic;
    ref_clk     : in std_logic;
    ddr3_clk_90 : in std_logic;
    ddr3_dq     : inout std_logic_vector((DQ_BITS*BYTE_LANES)-1 downto 0);
    ddr3_dqs_p  : inout std_logic_vector((DQ_BITS*BYTE_LANES)/8-1 downto 0);
    ddr3_dqs_n  : inout std_logic_vector((DQ_BITS*BYTE_LANES)/8-1 downto 0);
    ddr3_addr   : out   std_logic_vector(ROW_BITS-1 downto 0);
    ddr3_ba     : out   std_logic_vector(BA_BITS-1 downto 0);
    ddr3_ras_n  : out   std_logic;
    ddr3_cas_n  : out   std_logic;
    ddr3_we_n   : out   std_logic;
    ddr3_reset_n: out   std_logic;
    ddr3_ck_p   : out   std_logic_vector(DUAL_RANK_DIMM downto 0);
    ddr3_ck_n   : out   std_logic_vector(DUAL_RANK_DIMM downto 0);
    ddr3_cke    : out   std_logic_vector(DUAL_RANK_DIMM downto 0);
    ddr3_cs_n   : out   std_logic_vector(DUAL_RANK_DIMM downto 0);
    ddr3_dm     : out   std_logic_vector(BYTE_LANES-1 downto 0);
    ddr3_odt    : out   std_logic_vector(DUAL_RANK_DIMM downto 0);
    calib_done  : out std_logic

   );
  end component ;

  component uber_ddr3_phy_unisim is
  generic(
    CONTROLLER_CLK_PERIOD   : integer := 10000; -- ctrl clock period in ps
    DDR3_CLK_PERIOD         : integer := 2500;  -- ddr clock period
    ROW_BITS                : integer := 14;
    BA_BITS                 : integer := 3;
    DQ_BITS                 : integer := 8;
    LANES                   : integer := 8;
    DUAL_RANK_DIMM          : integer := 0; -- 1 enable, 0 disable
    ODELAY_SUPPORTED        : integer := 1; -- 1 if ODELAYE2 is available
    USE_IO_TERMINATION      : integer := 0; -- 1 to use IOBUF_DCIEN
    NO_IOSERDES_LOOPBACK    : integer := 1; -- 1 don't use IOSERDES loopback
    serdes_ratio            : integer := 4  -- fixed to 4:1
  );
  port(
    i_controller_clk        : in  std_logic;
    i_ddr3_clk              : in  std_logic;
    i_ref_clk               : in  std_logic;
    i_ddr3_clk_90           : in  std_logic; -- used when ODELAY_SUPPORTED=0
    i_rst_n                 : in  std_logic;

    i_controller_reset      : in  std_logic;
    i_controller_cmd        : in  std_logic_vector((7 + BA_BITS + ROW_BITS + 2*DUAL_RANK_DIMM)*serdes_ratio -1 downto 0);
    i_controller_dqs_tri_control : in std_logic;
    i_controller_dq_tri_control  : in std_logic;
    i_controller_toggle_dqs  : in std_logic;
    i_controller_data : in  std_logic_vector(DQ_BITS*LANES*serdes_ratio*2-1 downto 0);
    i_controller_dm : in  std_logic_vector(DQ_BITS*LANES*serdes_ratio/4-1 downto 0);
    i_controller_odelay_data_cntvaluein : in std_logic_vector(4 downto 0);
    i_controller_odelay_dqs_cntvaluein : in std_logic_vector(4 downto 0);
    i_controller_idelay_data_cntvaluein : in std_logic_vector(4 downto 0);
    i_controller_idelay_dqs_cntvaluein : in std_logic_vector(4 downto 0);
    i_controller_odelay_data_ld : in std_logic_vector(LANES-1 downto 0);
    i_controller_odelay_dqs_ld : in std_logic_vector(LANES-1 downto 0);
    i_controller_idelay_data_ld : in std_logic_vector(LANES-1 downto 0);
    i_controller_idelay_dqs_ld : in std_logic_vector(LANES-1 downto 0);
    i_controller_bitslip : in std_logic_vector(LANES-1 downto 0);
    i_controller_write_leveling_calib : in std_logic;
    o_controller_iserdes_data : out std_logic_vector(DQ_BITS*LANES*8-1 downto 0);
    o_controller_iserdes_dqs : out std_logic_vector(LANES*8-1 downto 0);
    o_controller_iserdes_bitslip_reference : out std_logic_vector(LANES*8-1 downto 0);
    o_controller_idelayctrl_rdy : out std_logic;

    o_ddr3_clk_p, o_ddr3_clk_n : out std_logic_vector(DUAL_RANK_DIMM downto 0);
    o_ddr3_reset_n          : out std_logic;
    o_ddr3_cke, o_ddr3_cs_n : out std_logic_vector(DUAL_RANK_DIMM downto 0);
    o_ddr3_ras_n            : out std_logic;
    o_ddr3_cas_n            : out std_logic;
    o_ddr3_we_n             : out std_logic;
    o_ddr3_addr             : out std_logic_vector(ROW_BITS-1 downto 0);
    o_ddr3_ba_addr          : out std_logic_vector(BA_BITS-1 downto 0);
    io_ddr3_dq    : inout std_logic_vector((DQ_BITS*LANES)-1 downto 0);
    io_ddr3_dqs   : inout std_logic_vector((DQ_BITS*LANES)/8-1 downto 0);
    io_ddr3_dqs_n : inout std_logic_vector((DQ_BITS*LANES)/8-1 downto 0);
    o_ddr3_dm : out std_logic_vector(LANES-1 downto 0);
    o_ddr3_odt              : out std_logic_vector(DUAL_RANK_DIMM downto 0);
    o_ddr3_debug_read_dqs_p : out std_logic_vector((DQ_BITS*LANES)/8-1 downto 0);
    o_ddr3_debug_read_dqs_n : out std_logic_vector((DQ_BITS*LANES)/8-1 downto 0)
    );
  end component;

  component ahb2wb4
  generic(
    hindex     : integer := 0;
    haddr      : integer := 0;
    hmask      : integer := 16#f00#;
    pindex     : integer := 0;
    paddr      : integer := 0;
    pmask      : integer := 16#fff#;
    litend     : integer := 0
  );
  port(
    clk_amba    : in std_logic;
    rst_n_syn   : in std_logic;
    ahbso       : out ahb_slv_out_type;
    ahbsi       : in  ahb_slv_in_type;
    apbi   	    : in  apb_slv_in_type;
    apbo   	    : out apb_slv_out_type;

    i_wb_cyc    : out std_logic;
    i_wb_stb    : out std_logic;
    i_wb_we     : out std_logic;
    o_wb_data   : in std_logic_vector(127 downto 0);
    i_wb_data   : out std_logic_vector(127 downto 0);
    i_wb_addr   : out std_logic_vector(23 downto 0);
    i_wb_sel    : out std_logic_vector(15 downto 0);
    o_wb_ack    : in std_logic;
    o_wb_stall  : in std_logic;
    debug       : out std_logic_vector(27 downto 0)
   );
  end component;


  component uber_ddr3_top is
  generic (
    CONTROLLER_CLK_PERIOD :integer := 12000; -- ps, clock period of the controller interface
    DDR3_CLK_PERIOD :integer := 3000; -- ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD)
    ROW_BITS : integer := 14; -- width of row address
    COL_BITS :integer := 10; -- width of column address
    BA_BITS : integer := 3; -- width of bank address
    BYTE_LANES : integer := 2; -- number of byte lanes of DDR3 RAM
    AUX_WIDTH : integer := 4; -- width of aux line (must be >= 4)
    WB2_ADDR_BITS : integer := 7; -- width of 2nd wishbone address bus
    WB2_DATA_BITS : integer := 32; -- width of 2nd wishbone data bus
    DUAL_RANK_DIMM : integer := 0; -- enable dual rank DIMM (1 =  enable, 0 = disable)
    -- DDR3 timing parameter values
    SPEED_BIN : integer := 3; -- 0 = Use top-level parameters , 1 = DDR3-1066 (7-7-7) , 2 = DR3-1333 (9-9-9) , 3 = DDR3-1600 (11-11-11)
    SDRAM_CAPACITY : integer := 5; -- 0 = 256Mb, 1 = 512Mb, 2 = 1Gb, 3 = 2Gb, 4 = 4Gb, 5 = 8Gb, 6 = 16Gb
    TRCD : integer := 13750; -- ps Active to Read/Write command time (only used if SPEED_BIN = 0)
    TRP : integer := 13750; -- ps Precharge command period (only used if SPEED_BIN = 0)
    TRAS : integer := 35000; -- ps ACT to PRE command period (only used if SPEED_BIN = 0)
    MICRON_SIM : integer := 0; --enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
    ODELAY_SUPPORTED : integer := 0; --set to 1 when ODELAYE2 is supported
    SECOND_WISHBONE : integer := 0; --set to 1 if 2nd wishbone for debugging is needed
    DLL_OFF : integer := 0; -- 1 = DLL off for low frequency ddr3 clock (< 125MHz)
    WB_ERROR : integer := 0; -- set to 1 to support Wishbone error (asserts at ECC double bit error)
    BIST_MODE : integer := 1; -- 0 = No BIST, 1 = run through all address space ONCE , 2 = run through all address space for every test (burst w/r, random w/r, alternating r/w)
    BIST_TEST_DATAMASK : integer := 1; -- 1 = include per-byte DM writes in BIST, 0 = all-byte writes only
    ECC_ENABLE : integer := 0; -- set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC )
    DIC : integer := 0; --Output Driver Impedance Control (2'b00 = RZQ/6, 2'b01 = RZQ/7, RZQ = 240ohms) (only change when you know what you are doing)
    RTT_NOM : integer := 3; --RTT Nominal (3'b000 = disabled, 3'b001 = RZQ/4, 3'b010 = RZQ/2 , 3'b011 = RZQ/6, RZQ = 240ohms)  (only change when you know what you are doing)
    SELF_REFRESH : integer := 0; -- 0 = use i_user_self_refresh input, 1 = Self-refresh mode is enabled after 64 controller clock cycles of no requests, 2 = 128 cycles, 3 = 256 cycles
    -- The next parameters act more like a localparam (since user does not have to set this manually) but was added here to simplify port declaration
    DQ_BITS : integer := 8; --device width (fixed to 8, if DDR3 is x16 then BYTE_LANES will be 2 while )
    serdes_ratio : integer := 4 -- this controller is fixed as a 4:1 memory controller (CONTROLLER_CLK_PERIOD/DDR3_CLK_PERIOD = 4)
--    wb_addr_bits : integer := ROW_BITS + COL_BITS + BA_BITS - log2(serdes_ratio*2) + DUAL_RANK_DIMM;
--    wb_data_bits : integer := DQ_BITS*BYTE_LANES*serdes_ratio*2;
--    wb_sel_bits : integer := wb_data_bits / 8;
--    wb2_sel_bits : integer := WB2_DATA_BITS / 8;
    -- 4 is the width of a single ddr3 command {cs_n, ras_n, cas_n, we_n} plus 3 (ck_en, odt, reset_n) plus bank bits plus row bits
--    cmd_len : integer := 4 + 3 + BA_BITS + ROW_BITS + 2*DUAL_RANK_DIMM
    );
  port(
    -- i_controller_clk = CONTROLLER_CLK_PERIOD, i_ddr3_clk = DDR3_CLK_PERIOD, i_ref_clk = 200MHz
    i_controller_clk, i_ddr3_clk, i_ref_clk : in std_logic;
    i_ddr3_clk_90 : in std_logic; -- required only when ODELAY_SUPPORTED is zero
    i_rst_n : in std_logic;
    i_wb_cyc : in std_logic; -- bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    i_wb_stb : in std_logic; -- request a transfer
    i_wb_we : in std_logic; -- write-enable (1 = write, 0 = read)
    i_wb_addr : in std_logic_vector(ROW_BITS + COL_BITS + BA_BITS - log2(serdes_ratio*2) + DUAL_RANK_DIMM -1 downto 0); -- burst-addressable {row,bank,col}
    i_wb_data : in std_logic_vector(DQ_BITS*BYTE_LANES*serdes_ratio*2-1 downto 0); -- write data, for a 4:1 controller data width is 8 times the number of pins on the device
    i_wb_sel : in std_logic_vector((DQ_BITS*BYTE_LANES*serdes_ratio*2 / 8) - 1 downto 0); -- byte strobe for write (1 = write the byte)
    i_aux : in std_logic_vector(AUX_WIDTH - 1 downto 0); -- for AXI-interface compatibility (given upon strobe)
    -- Wishbone outputs
    o_wb_stall : out std_logic; --1 = busy, cannot accept requests
    o_wb_ack : out std_logic; --1 = read/write request has completed
    o_wb_err : out std_logic; --1 = Error due to ECC double bit error (fixed to 0 if WB_ERROR = 0)
    o_wb_data : out std_logic_vector(DQ_BITS*BYTE_LANES*serdes_ratio*2 - 1 downto 0); -- read data, for a 4:1 controller data width is 8 times the number of pins on the device
    o_aux : out std_logic_vector(AUX_WIDTH - 1 downto 0); --  o_aux, --for AXI-interface compatibility (given upon strobe)
            -- Wishbone 2 (PHY) inputs
    i_wb2_cyc : in std_logic; --bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    i_wb2_stb : in std_logic; --request a transfer
    i_wb2_we : in std_logic; --write-enable (1 = write, 0 = read)
    i_wb2_addr : in std_logic_vector(WB2_ADDR_BITS - 1 downto 0); -- memory-mapped register to be accessed
    i_wb2_data : in std_logic_vector(WB2_DATA_BITS - 1 downto 0); --write data
    i_wb2_sel : in std_logic_vector(WB2_DATA_BITS/8 - 1 downto 0); --byte strobe for write (1 = write the byte)
        -- Wishbone 2 (Controller) outputs
    o_wb2_stall : out std_logic; --1 = busy, cannot accept requests
    o_wb2_ack : out std_logic; --1 = read/write request has completed
    o_wb2_data : out std_logic_vector(WB2_DATA_BITS - 1 downto 0); --read data
        --
        -- DDR3 I/O Interface
    o_ddr3_clk_p, o_ddr3_clk_n : out std_logic_vector(DUAL_RANK_DIMM downto 0);
    o_ddr3_reset_n          : out std_logic;
    o_ddr3_cke, o_ddr3_cs_n : out std_logic_vector(DUAL_RANK_DIMM downto 0);
    o_ddr3_ras_n            : out std_logic;
    o_ddr3_cas_n            : out std_logic;
    o_ddr3_we_n             : out std_logic;
    o_ddr3_addr             : out std_logic_vector(ROW_BITS-1 downto 0);
    o_ddr3_ba_addr          : out std_logic_vector(BA_BITS-1 downto 0);
    io_ddr3_dq    : inout std_logic_vector((DQ_BITS*BYTE_LANES)-1 downto 0);
    io_ddr3_dqs   : inout std_logic_vector((DQ_BITS*BYTE_LANES)/8-1 downto 0);
    io_ddr3_dqs_n : inout std_logic_vector((DQ_BITS*BYTE_LANES)/8-1 downto 0);
    o_ddr3_dm : out std_logic_vector(BYTE_LANES-1 downto 0);
    o_ddr3_odt              : out std_logic_vector(DUAL_RANK_DIMM downto 0);

        -- Done Calibration pin
    o_calib_complete : out std_logic;
        -- Debug outputs
    o_debug1 : out std_logic_vector(31 downto 0);
        -- User enabled self-refresh
    i_user_self_refresh : in std_logic;
    uart_tx : out std_logic
    );
  end component;

  component uber_ddr3_controller is
  generic (
    CONTROLLER_CLK_PERIOD :integer := 10000; -- ps, clock period of the controller interface
    DDR3_CLK_PERIOD :integer := 2500; -- ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD)
    ROW_BITS : integer := 14; -- width of row address
    COL_BITS :integer := 10; -- width of column address
    BA_BITS : integer := 3; -- width of bank address
    DQ_BITS : integer := 3;
    LANES : integer := 8; -- number of byte lanes of DDR3 RAM
    AUX_WIDTH : integer := 16; -- width of aux line (must be >= 4)
    WB2_ADDR_BITS : integer := 7; -- width of 2nd wishbone address bus
    WB2_DATA_BITS : integer := 32; -- width of 2nd wishbone data bus
    DUAL_RANK_DIMM : integer := 0; -- enable dual rank DIMM (1 =  enable, 0 = disable)
    -- DDR3 timing parameter values
    SPEED_BIN : integer := 3; -- 0 = Use top-level parameters , 1 = DDR3-1066 (7-7-7) , 2 = DR3-1333 (9-9-9) , 3 = DDR3-1600 (11-11-11)
    SDRAM_CAPACITY : integer := 5; -- 0 = 256Mb, 1 = 512Mb, 2 = 1Gb, 3 = 2Gb, 4 = 4Gb, 5 = 8Gb, 6 = 16Gb
    TRCD : integer := 13750; -- ps Active to Read/Write command time (only used if SPEED_BIN = 0)
    TRP : integer := 13750; -- ps Precharge command period (only used if SPEED_BIN = 0)
    TRAS : integer := 35000; -- ps ACT to PRE command period (only used if SPEED_BIN = 0)
    MICRON_SIM : integer := 0; --enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
    ODELAY_SUPPORTED : integer := 1; --set to 1 when ODELAYE2 is supported
    SECOND_WISHBONE : integer := 0; --set to 1 if 2nd wishbone for debugging is needed
    DLL_OFF : integer := 0; -- 1 = DLL off for low frequency ddr3 clock (< 125MHz)
    WB_ERROR : integer := 0; -- set to 1 to support Wishbone error (asserts at ECC double bit error)
    BIST_MODE : integer := 2; -- 0 = No BIST, 1 = run through all address space ONCE , 2 = run through all address space for every test (burst w/r, random w/r, alternating r/w)
    BIST_TEST_DATAMASK : integer := 1; -- 1 = include per-byte DM writes in BIST, 0 = all-byte writes only
    ECC_ENABLE : integer := 0; -- set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC )
    DIC : integer := 0; --Output Driver Impedance Control (2'b00 = RZQ/6, 2'b01 = RZQ/7, RZQ = 240ohms) (only change when you know what you are doing)
    RTT_NOM : integer := 3; --RTT Nominal (3'b000 = disabled, 3'b001 = RZQ/4, 3'b010 = RZQ/2 , 3'b011 = RZQ/6, RZQ = 240ohms)  (only change when you know what you are doing)
    serdes_ratio : integer := 4 -- this controller is fixed as a 4:1 memory controller (CONTROLLER_CLK_PERIOD/DDR3_CLK_PERIOD = 4)
--    wb_addr_bits : integer := ROW_BITS + COL_BITS + BA_BITS - log2(serdes_ratio*2) + DUAL_RANK_DIMM;
--    wb_data_bits : integer := DQ_BITS*BYTE_LANES*serdes_ratio*2;
--    wb_sel_bits : integer := wb_data_bits / 8;
--    wb2_sel_bits : integer := WB2_DATA_BITS / 8;
    -- 4 is the width of a single ddr3 command {cs_n, ras_n, cas_n, we_n} plus 3 (ck_en, odt, reset_n) plus bank bits plus row bits
--    cmd_len : integer := 4 + 3 + BA_BITS + ROW_BITS + 2*DUAL_RANK_DIMM
    );
  port(
    i_controller_clk : in std_logic;
    i_rst_n : in std_logic;
    i_wb_cyc : in std_logic; -- bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    i_wb_stb : in std_logic; -- request a transfer
    i_wb_we : in std_logic; -- write-enable (1 = write, 0 = read)
    i_wb_addr : in std_logic_vector(ROW_BITS + COL_BITS + BA_BITS - log2(serdes_ratio*2) + DUAL_RANK_DIMM -1 downto 0); -- burst-addressable {row,bank,col}
    i_wb_data : in std_logic_vector(DQ_BITS*LANES*serdes_ratio*2-1 downto 0); -- write data, for a 4:1 controller data width is 8 times the number of pins on the device
    i_wb_sel : in std_logic_vector((DQ_BITS*LANES*serdes_ratio*2 / 8) - 1 downto 0); -- byte strobe for write (1 = write the byte)
    i_aux : in std_logic_vector(AUX_WIDTH - 1 downto 0); -- for AXI-interface compatibility (given upon strobe)
    -- Wishbone outputs
    o_wb_stall : out std_logic; --1 = busy, cannot accept requests
    o_wb_ack : out std_logic; --1 = read/write request has completed
    o_wb_err : out std_logic; --1 = Error due to ECC double bit error (fixed to 0 if WB_ERROR = 0)
    o_wb_data : out std_logic_vector(DQ_BITS*LANES*serdes_ratio*2 - 1 downto 0); -- read data, for a 4:1 controller data width is 8 times the number of pins on the device
    o_aux : out std_logic_vector(AUX_WIDTH - 1 downto 0); --  o_aux, --for AXI-interface compatibility (given upon strobe)
            -- Wishbone 2 (PHY) inputs
    i_wb2_cyc : in std_logic; --bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    i_wb2_stb : in std_logic; --request a transfer
    i_wb2_we : in std_logic; --write-enable (1 = write, 0 = read)
    i_wb2_addr : in std_logic_vector(WB2_ADDR_BITS - 1 downto 0); -- memory-mapped register to be accessed
    i_wb2_sel : in std_logic_vector(WB2_DATA_BITS/8 - 1 downto 0); --byte strobe for write (1 = write the byte)
    i_wb2_data : in std_logic_vector(WB2_DATA_BITS - 1 downto 0); --write data
        -- Wishbone 2 (Controller) outputs
    o_wb2_stall : out std_logic; --1 = busy, cannot accept requests
    o_wb2_ack : out std_logic; --1 = read/write request has completed
    o_wb2_data : out std_logic_vector(WB2_DATA_BITS - 1 downto 0); --read data
        --
        -- DDR3 PHY Interface
    i_phy_iserdes_data : in std_logic_vector((DQ_BITS*LANES*8)-1 downto 0);
    i_phy_iserdes_dqs : in std_logic_vector((LANES*serdes_ratio*2)-1 downto 0);
    i_phy_iserdes_bitslip_reference : in std_logic_vector((LANES*serdes_ratio*2)-1 downto 0);
    i_phy_idelayctrl_rdy    : in std_logic;
    o_phy_cmd : out std_logic_vector((4 + 3 + BA_BITS + ROW_BITS + 2*DUAL_RANK_DIMM)*serdes_ratio-1 downto 0);
    o_phy_dqs_tri_control, o_phy_dq_tri_control : out std_logic;
    o_phy_toggle_dqs : out std_logic;
    o_phy_data : out std_logic_vector(DQ_BITS*LANES*serdes_ratio*2-1 downto 0);
    o_phy_dm : out std_logic_vector(DQ_BITS*LANES*serdes_ratio/4-1 downto 0);
    o_phy_odelay_data_cntvaluein, o_phy_odelay_dqs_cntvaluein : out std_logic_vector(4 downto 0);
    o_phy_idelay_data_cntvaluein : out std_logic_vector(4 downto 0);
    o_phy_idelay_dqs_cntvaluein : out std_logic_vector(4 downto 0);
    o_phy_odelay_data_ld, o_phy_odelay_dqs_ld : out std_logic_vector(LANES-1 downto 0);
    o_phy_idelay_data_ld : out std_logic_vector(LANES-1 downto 0);
    o_phy_idelay_dqs_ld : out std_logic_vector(LANES-1 downto 0);
    o_phy_bitslip : out std_logic_vector(LANES-1 downto 0);
    o_phy_write_leveling_calib : out std_logic;
    o_phy_reset : out std_logic;
        -- Done Calibration pin
    o_calib_complete : out std_logic;
        -- Debug outputs
    o_debug1 : out std_logic_vector(31 downto 0);
        -- User enabled self-refresh
    i_user_self_refresh : in std_logic;
    uart_tx : out std_logic
    );
  end component;

end package;

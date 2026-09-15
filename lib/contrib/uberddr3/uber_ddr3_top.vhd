--------------------------------------------------------------------------------
--
-- Filename: ddr3_top.v
-- Project: UberDDR3 - An Open Source DDR3 Controller
--
-- Purpose: Top module which instantiates the ddr3_controller and ddr3_phy modules
-- Use this as top module for instantiating UberDDR3 with Wishbone Interface.
--
-- Engineer: Angelo C. Jacobo
--
--------------------------------------------------------------------------------
--
-- Copyright (C) 2023-2025  Angelo Jacobo
--
--     This program is free software: you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation, either version 3 of the License, or
--     (at your option) any later version.
--
--     This program is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
--
--     You should have received a copy of the GNU General Public License
--     along with this program.  If not, see <https:--www.gnu.org/licenses/>.
--
--------------------------------------------------------------------------------

-- Converted to VHDL by Jiri Gaisler, 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library grlib;
use grlib.stdlib.all;

library techmap;

use work.uber_ddr3_comp.all;

entity uber_ddr3_top is
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
end;

architecture rtl of uber_ddr3_top is

  constant wb_addr_bits : integer := ROW_BITS + COL_BITS + BA_BITS - log2(serdes_ratio*2) + DUAL_RANK_DIMM;
  constant wb_data_bits : integer := DQ_BITS*BYTE_LANES*serdes_ratio*2;
  constant wb_sel_bits  : integer := wb_data_bits / 8;
  constant wb2_sel_bits : integer := WB2_DATA_BITS / 8;
                --4 is the width of a single ddr3 command {cs_n, ras_n, cas_n, we_n} plus 3 (ck_en, odt, reset_n) plus bank bits plus row bits
  constant cmd_len : integer := 4 + 3 + BA_BITS + ROW_BITS + 2*DUAL_RANK_DIMM;

    -- Wire connections between controller and phy
  signal cmd : std_logic_vector(cmd_len*serdes_ratio-1 downto 0);
  signal dqs_tri_control, dq_tri_control : std_logic;
  signal toggle_dqs : std_logic;
  signal data : std_logic_vector(wb_data_bits-1 downto 0);
  signal dm : std_logic_vector(wb_sel_bits-1 downto 0);
  signal bitslip : std_logic_vector(BYTE_LANES-1 downto 0);
  signal iserdes_data : std_logic_vector(DQ_BITS*BYTE_LANES*8-1 downto 0);
  signal iserdes_dqs : std_logic_vector(BYTE_LANES*8-1 downto 0);
  signal iserdes_bitslip_reference : std_logic_vector(BYTE_LANES*8-1 downto 0);
  signal idelayctrl_rdy : std_logic;
  signal odelay_data_cntvaluein, odelay_dqs_cntvaluein : std_logic_vector(4 downto 0);
  signal idelay_data_cntvaluein, idelay_dqs_cntvaluein : std_logic_vector(4 downto 0);
  signal odelay_data_ld, odelay_dqs_ld : std_logic_vector(BYTE_LANES-1 downto 0);
  signal idelay_data_ld, idelay_dqs_ld : std_logic_vector(BYTE_LANES-1 downto 0);
  signal write_leveling_calib : std_logic;
  signal reset : std_logic;
  signal o_wb_stall_i : std_logic; --1 = busy, cannot accept requests
    -- logic for self-refresh
  signal refresh_counter : std_logic_vector(8 downto 0);
  signal user_self_refresh : std_logic;

begin
    o_wb_stall <= o_wb_stall_i;
    -- refresh counter
    p1 : process(i_controller_clk)
    begin
      if rising_edge(i_controller_clk) then
        if (i_wb_stb and i_wb_cyc) = '1' then -- if there is Wishbone request, then reset counter
            refresh_counter <= (others => '0');
        elsif ((not o_wb_stall_i) or user_self_refresh) = '1' then -- if no request (but not stalled) OR already on self-refresh, then increment counter
            refresh_counter <= refresh_counter + 1;
        end if;
      end if;
    end process;

    -- choose self-refresh options
    with (SELF_REFRESH) select user_self_refresh <=
      i_user_self_refresh when 0, -- use input i_user_self_refresh (high = enter self-refresh, low = exit self-refresh)
      refresh_counter(6)  when 1,  -- Self-refresh mode is enabled after 64 controller clock cycles of no requests, then exit Self-refresh after another 64 controller clk cycles
      refresh_counter(7)  when 2,  -- Self-refresh mode is enabled after 128 controller clock cycles of no requests, then exit Self-refresh after another 128 controller clk cycles
      refresh_counter(8)  when others; -- Self-refresh mode is enabled after 256 controller clock cycles of no requests, then exit Self-refresh after another 256 controller clk cycles

    --module instantiations
    d3ctrl : uber_ddr3_controller
    generic map (
      CONTROLLER_CLK_PERIOD => CONTROLLER_CLK_PERIOD, --ps, clock period of the controller interface
      DDR3_CLK_PERIOD => DDR3_CLK_PERIOD, --ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD)
      ROW_BITS => ROW_BITS, --width of row address
      COL_BITS => COL_BITS, --width of column address
      BA_BITS => BA_BITS, --width of bank address
      DQ_BITS => DQ_BITS,  --width of DQ
      LANES => BYTE_LANES, -- byte lanes
      AUX_WIDTH => AUX_WIDTH, --width of aux line (must be >= 4)
      WB2_ADDR_BITS => WB2_ADDR_BITS, --width of 2nd wishbone address bus
      WB2_DATA_BITS => WB2_DATA_BITS,  --width of 2nd wishbone data bus
      MICRON_SIM => MICRON_SIM, --simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
      ODELAY_SUPPORTED => ODELAY_SUPPORTED,  --set to 1 when ODELAYE2 is supported
      SECOND_WISHBONE => SECOND_WISHBONE, --set to 1 if 2nd wishbone is needed
      ECC_ENABLE => ECC_ENABLE, -- set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC )
      DLL_OFF => DLL_OFF, -- 1 = DLL off for low frequency ddr3 clock (< 125MHz)
      WB_ERROR => WB_ERROR, -- set to 1 to support Wishbone error (asserts at ECC double bit error)
      BIST_MODE => BIST_MODE, -- 0 = No BIST, 1 = run through all address space ONCE , 2 = run through all address space for every test (burst w/r, random w/r, alternating r/w)
      BIST_TEST_DATAMASK => BIST_TEST_DATAMASK, -- 1 = include per-byte DM writes in BIST, 0 = all-byte writes only
      DIC => DIC, --Output Driver Impedance Control (2'b00 = RZQ/6, 2'b01 = RZQ/7, RZQ = 240ohms)
      RTT_NOM => RTT_NOM, --RTT Nominal (3'b000 = disabled, 3'b001 = RZQ/4, 3'b010 = RZQ/2 , 3'b011 = RZQ/6, RZQ = 240ohms)
      DUAL_RANK_DIMM => DUAL_RANK_DIMM, -- enable dual rank DIMM (1 =  enable, 0 = disable)
      SPEED_BIN => SPEED_BIN, -- 0 = Use top-level parameters , 1 = DDR3-1066 (7-7-7) , 2 = DR3-1333 (9-9-9) , 3 = DDR3-1600 (11-11-11)
      SDRAM_CAPACITY => SDRAM_CAPACITY, -- 0 = 256Mb, 1 = 512Mb, 2 = 1Gb, 3 = 2Gb, 4 = 4Gb, 5 = 8Gb, 6 = 16Gb
      TRCD => TRCD, -- ps Active to Read/Write command time (only used if SPEED_BIN = 0)
      TRP => TRP, -- ps Precharge command period (only used if SPEED_BIN = 0)
      TRAS => TRAS -- ps ACT to PRE command period (only used if SPEED_BIN = 0)
    )
    port map (
      i_controller_clk => i_controller_clk, --i_controller_clk has period of CONTROLLER_CLK_PERIOD
      i_rst_n => i_rst_n, --200MHz input clock
            -- Wishbone inputs
      i_wb_cyc => i_wb_cyc, --bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
      i_wb_stb => i_wb_stb, --request a transfer
      i_wb_we => i_wb_we, --write-enable (1 = write, 0 = read)
      i_wb_addr => i_wb_addr, --burst-addressable {row,bank,col}
      i_wb_data => i_wb_data, --write data, for a 4:1 controller data width is 8 times the number of pins on the device
      i_wb_sel => i_wb_sel, --byte strobe for write (1 = write the byte)
      i_aux => i_aux, --for AXI-interface compatibility (given upon strobe)
            -- Wishbone outputs
      o_wb_stall => o_wb_stall_i, --1 = busy, cannot accept requests
      o_wb_ack => o_wb_ack, --1 = read/write request has completed
      o_wb_err => o_wb_err, --1 = Error due to ECC double bit error (fixed to 0 if WB_ERROR = 0)
      o_wb_data => o_wb_data, --read data, for a 4:1 controller data width is 8 times the number of pins on the device
      o_aux => o_aux, --for AXI-interface compatibility (returned upon ack)
            -- Wishbone 2 (PHY) inputs
      i_wb2_cyc => i_wb2_cyc, --bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
      i_wb2_stb => i_wb2_stb, --request a transfer
      i_wb2_we => i_wb2_we, --write-enable (1 = write, 0 = read)
      i_wb2_addr => i_wb2_addr, -- memory-mapped register to be accessed
      i_wb2_data => i_wb2_data, --write data
      i_wb2_sel => i_wb2_sel, --byte strobe for write (1 = write the byte)
            -- Wishbone 2 (Controller) outputs
      o_wb2_stall => o_wb2_stall, --1 = busy, cannot accept requests
      o_wb2_ack => o_wb2_ack, --1 = read/write request has completed
      o_wb2_data => o_wb2_data, --read data
            --
            -- PHY interface
      i_phy_iserdes_data => iserdes_data,
      i_phy_iserdes_dqs => iserdes_dqs,
      i_phy_iserdes_bitslip_reference => iserdes_bitslip_reference,
      i_phy_idelayctrl_rdy => idelayctrl_rdy,
      o_phy_cmd => cmd,
      o_phy_dqs_tri_control => dqs_tri_control,
      o_phy_dq_tri_control => dq_tri_control,
      o_phy_toggle_dqs => toggle_dqs,
      o_phy_data => data,
      o_phy_dm => dm,
      o_phy_odelay_data_cntvaluein => odelay_data_cntvaluein,
      o_phy_odelay_dqs_cntvaluein => odelay_dqs_cntvaluein,
      o_phy_idelay_data_cntvaluein => idelay_data_cntvaluein,
      o_phy_idelay_dqs_cntvaluein => idelay_dqs_cntvaluein,
      o_phy_odelay_data_ld => odelay_data_ld,
      o_phy_odelay_dqs_ld => odelay_dqs_ld,
      o_phy_idelay_data_ld => idelay_data_ld,
      o_phy_idelay_dqs_ld => idelay_dqs_ld,
      o_phy_bitslip => bitslip,
      o_phy_write_leveling_calib => write_leveling_calib,
      o_phy_reset => reset,
            -- Done Calibration pin
      o_calib_complete => o_calib_complete,
            -- Debug outputs
      o_debug1 => o_debug1,
--            .o_debug2(o_debug2,
--            .o_debug3(o_debug3)
            -- User enabled self-refresh
      i_user_self_refresh => user_self_refresh,
      uart_tx => uart_tx
    );

  d3phy : uber_ddr3_phy_unisim
    generic map (
      ROW_BITS => ROW_BITS, --width of row address
      BA_BITS => BA_BITS, --width of bank address
      DQ_BITS => DQ_BITS,  --width of DQ
      LANES => BYTE_LANES, --8 lanes of DQ
      CONTROLLER_CLK_PERIOD => CONTROLLER_CLK_PERIOD, --ps, period of clock input to this DDR3 controller module
      DDR3_CLK_PERIOD => DDR3_CLK_PERIOD, --ps, period of clock input to DDR3 RAM device
      ODELAY_SUPPORTED => ODELAY_SUPPORTED, --set to 1 when ODELAYE2 is supported
      DUAL_RANK_DIMM => DUAL_RANK_DIMM) -- enable dual rank DIMM (1 =  enable, 0 = disable)
    port map (
      i_controller_clk => i_controller_clk,
      i_ddr3_clk => i_ddr3_clk,
      i_ref_clk => i_ref_clk,
      i_ddr3_clk_90 => i_ddr3_clk_90,
      i_rst_n => i_rst_n,
                -- Controller Interface
      i_controller_reset => reset,
      i_controller_cmd => cmd,
      i_controller_dqs_tri_control => dqs_tri_control,
      i_controller_dq_tri_control => dq_tri_control,
      i_controller_toggle_dqs => toggle_dqs,
      i_controller_data => data,
      i_controller_dm => dm,
      i_controller_odelay_data_cntvaluein => odelay_data_cntvaluein,
      i_controller_odelay_dqs_cntvaluein => odelay_dqs_cntvaluein,
      i_controller_idelay_data_cntvaluein => idelay_data_cntvaluein,
      i_controller_idelay_dqs_cntvaluein => idelay_dqs_cntvaluein,
      i_controller_odelay_data_ld => odelay_data_ld,
      i_controller_odelay_dqs_ld => odelay_dqs_ld,
      i_controller_idelay_data_ld => idelay_data_ld,
      i_controller_idelay_dqs_ld => idelay_dqs_ld,
      i_controller_bitslip => bitslip,
      i_controller_write_leveling_calib => write_leveling_calib,
      o_controller_iserdes_data => iserdes_data,
      o_controller_iserdes_dqs => iserdes_dqs,
      o_controller_iserdes_bitslip_reference => iserdes_bitslip_reference,
      o_controller_idelayctrl_rdy => idelayctrl_rdy,
                -- DDR3 I/O Interface
      o_ddr3_clk_p => o_ddr3_clk_p,
      o_ddr3_clk_n => o_ddr3_clk_n,
      o_ddr3_reset_n => o_ddr3_reset_n,
      o_ddr3_cke => o_ddr3_cke, -- CKE
      o_ddr3_cs_n => o_ddr3_cs_n, -- chip select signal
      o_ddr3_ras_n => o_ddr3_ras_n, -- RAS#
      o_ddr3_cas_n => o_ddr3_cas_n, -- CAS#
      o_ddr3_we_n => o_ddr3_we_n, -- WE#
      o_ddr3_addr => o_ddr3_addr,
      o_ddr3_ba_addr => o_ddr3_ba_addr,
      io_ddr3_dq => io_ddr3_dq,
      io_ddr3_dqs => io_ddr3_dqs,
      io_ddr3_dqs_n => io_ddr3_dqs_n,
      o_ddr3_dm => o_ddr3_dm,
      o_ddr3_odt => o_ddr3_odt -- on-die termination
--      o_ddr3_debug_read_dqs_p(/*o_ddr3_debug_read_dqs_p*/,
--      o_ddr3_debug_read_dqs_n(/*o_ddr3_debug_read_dqs_n*/)
    );

end;

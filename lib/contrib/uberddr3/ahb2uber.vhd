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
-- Entity:      ahb2uber
-- File:        ahb2uber.vhd
-- Author:      Jiri Gaisler
--
--  This is a AHB-2.0 interface for the Uber DDR3 controller.
--  The amba device ID is set to Xilinx MIG2 so that grmon detects
--  the memory.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
use work.uber_ddr3_comp.all;

entity ahb2uber is
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
end ;

architecture rtl of ahb2uber is

type bstate_type is (idle, write1, write2, read0, read1, read2, read3);

constant hconfig : ahb_config_type := (
   0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_MIGDDR2, 0, 0, 0),
   4 => ahb_membar(haddr, '1', '1', hmask),
   others => zero32);

constant pconfig : apb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_MIGDDR2, 0, 0, 0),
  1 => apb_iobar(paddr, pmask));

type reg_type is record
  bstate 	: bstate_type;
  hready         : std_logic;
  hsel           : std_logic;
  hwrite         : std_logic;
  htrans         : std_logic_vector(1 downto 0);
  hburst         : std_logic_vector(2 downto 0);
  hsize          : std_logic_vector(2 downto 0);
  hrdata         : std_logic_vector(127 downto 0);
  hrdata2        : std_logic_vector(127 downto 0);
  hwdata         : std_logic_vector(127 downto 0);
  haddr          : std_logic_vector(31 downto 0);
  wb_addr        : std_logic_vector(23 downto 0);
  wb_we          : std_logic;
  wb_sel         : std_logic_vector(15 downto 0);
  wcnt           : std_logic_vector(2 downto 0);
  d1rdy          : std_logic;
end record;

signal r, rin    : reg_type;
signal rst_syn : std_logic;
signal calib_done_i, l_wb_stb : std_logic;

signal i_wb_cyc    : std_logic;
signal i_wb_stb    : std_logic;
signal i_wb_we     : std_logic;
signal o_wb_data   : std_logic_vector(127 downto 0);
signal i_wb_data   : std_logic_vector(127 downto 0);
signal i_wb_addr   : std_logic_vector(23 downto 0);
signal i_wb_sel    : std_logic_vector(15 downto 0);
signal o_wb_ack    : std_logic;
signal o_wb_stall  : std_logic;
signal debug       : std_logic_vector(27 downto 0);

begin

  comb: process( rst_n_syn, r, ahbsi, o_wb_data, o_wb_ack, o_wb_stall)
  variable v : reg_type;
  variable wmask : std_logic_vector(3 downto 0);
  variable hwdata         :  std_logic_vector(31 downto 0);
  variable readdata       :  std_logic_vector(31 downto 0);
  variable hrdata         :  std_logic_vector(31 downto 0);
  variable wb_addr        :  std_logic_vector(23 downto 0);
  variable wb_stb         :  std_logic;
  variable wb_cyc         :  std_logic;
  variable busy           :  std_logic;
  begin
    v := r;
    wb_stb := '0';
    wb_addr := r.haddr(27 downto 4);
    if r.wcnt = "000" then busy := '0'; else busy := '1'; end if;

    if (ahbsi.hready = '1') then
      if (ahbsi.hsel(hindex) and ahbsi.htrans(1)) = '1' then
        v.hsel := '1'; v.hburst := ahbsi.hburst;
        v.hwrite := ahbsi.hwrite; v.hsize := ahbsi.hsize;
        v.haddr := ahbsi.haddr;
      else
        v.hsel := '0'; v.hready := '1';
      end if;
      v.htrans := ahbsi.htrans;
    end if;

    if (litend = 1) then
      case r.hsize(1 downto 0) is
      when "00" =>
        case r.haddr(1 downto 0) is
        when "00" => wmask := "1000";
        when "01" => wmask := "0100";
        when "10" => wmask := "0010";
        when others => wmask := "0001";
        end case;
      when "01" =>
        if (r.haddr(1) = '0') then wmask := "1100";
        else wmask := "0011"; end if;
      when others => wmask := "1111";
      end case;

      case r.haddr(3 downto 2) is
      when "00" =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(127 downto 96) := ahbsi.hwdata;
          v.wb_sel(15 downto 12) := wmask;
        end if;
        hrdata := r.hrdata(127 downto 96);
      when "01" =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(95 downto 64) := ahbsi.hwdata;
          v.wb_sel(11 downto 8) := wmask;
        end if;
        hrdata := r.hrdata(95 downto 64);
      when "10" =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(63 downto 32) := ahbsi.hwdata;
          v.wb_sel(7 downto 4) := wmask;
        end if;
        hrdata := r.hrdata(63 downto 32);
      when others =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(31 downto 0) := ahbsi.hwdata;
          v.wb_sel(3 downto 0) := wmask;
        end if;
        hrdata := r.hrdata(31 downto 0);
      end case;
    else
      hwdata := ahbsi.hwdata(7 downto 0) & ahbsi.hwdata(15 downto 8) &
        ahbsi.hwdata(23 downto 16) & ahbsi.hwdata(31 downto 24);
      case r.hsize(1 downto 0) is
      when "00" =>
        case r.haddr(1 downto 0) is
        when "00" => wmask := "0001";
        when "01" => wmask := "0010";
        when "10" => wmask := "0100";
        when others => wmask := "1000";
        end case;
      when "01" =>
        if (r.haddr(1) = '1') then wmask := "1100";
        else wmask := "0011"; end if;
      when others => wmask := "1111";
      end case;

      case r.haddr(3 downto 2) is
      when "00" =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(31 downto 0) := hwdata;
          v.wb_sel(3 downto 0) := wmask;
        end if;
        hrdata := r.hrdata(31 downto 0);
      when "01" =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(63 downto 32) := hwdata;
          v.wb_sel(7 downto 4) := wmask;
        end if;
        hrdata := r.hrdata(63 downto 32);
      when "10" =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(95 downto 64) := hwdata;
          v.wb_sel(11 downto 8) := wmask;
        end if;
        hrdata := r.hrdata(95 downto 64);
      when others =>
        if (r.hsel and r.hwrite and r.hready) = '1' then
          v.hwdata(127 downto 96) := hwdata;
          v.wb_sel(15 downto 12) := wmask;
        end if;
        hrdata := r.hrdata(127 downto 96);
      end case;
      hrdata := hrdata(7 downto 0) & hrdata(15 downto 8) &
        hrdata(23 downto 16) & hrdata(31 downto 24);
    end if;

    if r.hwrite = '0' then wmask := (others => '1'); end if;

    case r.bstate is
    when idle =>
      if v.hsel = '1' then
        if v.hwrite = '1' then
          v.wb_sel := (others => '0');
          v.bstate := write1;
          v.wb_we := '1';
        else
          v.wb_sel := (others => '1');
          v.wb_we := '0';
          v.bstate := read0;
          v.hready := '0';
        end if;
        v.haddr := ahbsi.haddr;
      end if;
    when write1 =>
      if (ahbsi.htrans /= "11") or (r.haddr(3 downto 2) = "11") then
        v.bstate := write2;
        v.hready := '0';
        v.wb_addr := r.haddr(27 downto 4);
        v.wb_we := r.hwrite;
      end if;
    when write2 =>
      v.hready := '0';
      wb_addr := r.wb_addr;
      wb_stb := not o_wb_stall;
      if wb_stb = '1' then
        if (v.hsel = '1') then
          if v.hwrite = '1' then
            v.bstate := write1;
            v.hready := '1'; --r.hsel;
            v.wb_sel := (others => '0');
          else
            v.wb_we := '0';
            v.bstate := read0;
            v.wb_sel := (others => '1');
          end if;
        else
          v.bstate := idle;
          v.hready := '1';
        end if;
      end if;
    when read0 =>
      v.hready := '0';
      wb_addr := r.haddr(27 downto 4);
      wb_stb := not o_wb_stall;
      if wb_stb = '1' then -- fetch 2x 4-word lines on burst access
        if (r.hburst /= "000") and (r.haddr(4) = '0') then
          v.bstate := read3;
        else
          v.bstate := read1;
        end if;
      end if;
    when read3 =>
      wb_addr := r.haddr(27 downto 5) & "1";
      wb_stb := not o_wb_stall;
      if wb_stb = '1' then
        if r.d1rdy = '1' then
          v.bstate := read2; v.hready := '1';
        else
          v.bstate := read1;
        end if;
      else
        if (o_wb_ack and not busy) = '1' then -- stall between two wb_stb
          v.hrdata := o_wb_data;
          v.d1rdy := '1';
        end if;
      end if;
    when read1 =>
      v.hready := '0'; v.d1rdy := '0';
      if (o_wb_ack and not busy) = '1' then
        v.bstate := read2; v.hready := '1';
        v.hrdata := o_wb_data;
      end if;
    when read2 =>
      if (r.haddr(3 downto 2) = "11") and (r.hready = '1') then
        v.hrdata := r.hrdata2;
      end if;
      if (o_wb_ack and not busy) = '1' then
        v.hrdata2 := o_wb_data;
        v.d1rdy := '0';
        if ((r.haddr(3 downto 2) = "11") and (r.hready = '1'))
          or ((r.haddr(3 downto 2) = "00") and (r.hready = '0')) then
          v.hrdata := o_wb_data;
        end if;
      end if;
      if v.hsel = '1' then
        if (ahbsi.htrans /= "11") or (r.haddr(4 downto 2) = "111") then
          if ahbsi.hwrite = '1' then
            v.bstate := write1;
            v.wb_sel := (others => '0');
            v.hready := '1';
          else
            v.hready := '0';
            v.bstate := read0;
          end if;
        else
          v.hready := not r.d1rdy;
        end if;
      else
	      v.bstate := idle;
        v.hready := '1';
	    end if;
    end case;

    if (o_wb_ack and busy and not (wb_stb and r.wb_we)) = '1' then
      v.wcnt := r.wcnt - 1;
    elsif ((wb_stb and r.wb_we) and not (o_wb_ack and busy)) = '1' then
      v.wcnt := r.wcnt + 1;
    end if;

    if r.bstate = idle then
      wb_cyc := busy;
    else
      wb_cyc := '1';
    end if;

-- uber ddr3 uses row:bank:column addressing, while the gaisler ddr3 memory is
-- initialized with bank:row:column scheme. Twist the addressing to make the
-- testbench work ...

--pragma translate_off
    if litend = 0 then
      wb_addr := wb_addr(20 downto 7) & wb_addr(23 downto 21) &
               wb_addr(6 downto 0);
    end if;
--pragma translate_on

    i_wb_stb  <= wb_stb;
    l_wb_stb  <= wb_stb;
    i_wb_addr <= wb_addr;
    i_wb_cyc  <= wb_cyc;

    ahbso.hrdata  <= hrdata;
    readdata := (others => '0');

    if rst_n_syn = '0' then
      v.bstate := idle; v.hready := '1'; v.wcnt := "000";
      v.d1rdy := '0';
    end if;

    rin <= v;
    apbo.prdata <= readdata;


  end process;

  i_wb_sel  <= r.wb_sel;
  i_wb_data <= r.hwdata;
  i_wb_we   <= r.wb_we;

  ahbso.hready  <= r.hready;
  ahbso.hresp   <= "00";

  ahbso.hconfig <= hconfig;
  ahbso.hirq    <= (others => '0');
  ahbso.hindex  <= hindex;
  ahbso.hsplit  <= (others => '0');

  apbo.pindex <= pindex;
  apbo.pconfig <= pconfig;
  apbo.pirq <= (others => '0');

  debug <= r.haddr(15 downto 0) & r.d1rdy & l_wb_stb & r.wb_we & r.hready &
      o_wb_ack & r.wcnt & o_wb_stall &
        std_logic_vector(to_unsigned(bstate_type'pos(r.bstate), 3));

  regs : process(clk_amba)
  begin
    if rising_edge(clk_amba) then
      r <= rin;
    end if;
  end process;


    u1 : uber_ddr3_top
       generic map (
      CONTROLLER_CLK_PERIOD => CONTROLLER_CLK_PERIOD,
      DDR3_CLK_PERIOD => DDR3_CLK_PERIOD,
      ROW_BITS => ROW_BITS, -- width of row address
      COL_BITS => COL_BITS, -- width of column address
      BA_BITS => BA_BITS, -- width of bank address
      BYTE_LANES => BYTE_LANES, -- number of DDR3 modules to be controlled
      AUX_WIDTH => 6, -- width of aux line (must be >= 4)
      WB2_ADDR_BITS => 32, -- width of 2nd wishbone address bus
      WB2_DATA_BITS => 32, -- width of 2nd wishbone data bus
      MICRON_SIM => MICRON_SIM, -- enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
      ODELAY_SUPPORTED => ODELAY_SUPPORTED, -- set to 1 when ODELAYE2 is supported
      SECOND_WISHBONE => 0, -- set to 1 if 2nd wishbone is needed
      ECC_ENABLE => 0, --  set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC )
      WB_ERROR => 0, --  set to 1 to support Wishbone error (asserts at ECC double bit error)
      BIST_MODE => 1, --  0 = No BIST, 1 = run through all address space ONCE , 2 = run through all address space for every test (burst w/r, random w/r, alternating r/w)
      SPEED_BIN => SPEED_BIN, --  0 = Use top-level parameters , 1 = DDR3-1066 (7-7-7) , 2 = DR3-1333 (9-9-9) , 3 = DDR3-1600 (11-11-11)
      SDRAM_CAPACITY => SDRAM_CAPACITY,
      DUAL_RANK_DIMM => DUAL_RANK_DIMM,
      SELF_REFRESH => SELF_REFRESH,
      DQ_BITS => DQ_BITS
    )
    port map (
      i_controller_clk => clk_amba,
      i_ddr3_clk => ddr3_clk,
      i_ref_clk => ref_clk,
      i_ddr3_clk_90 => ddr3_clk_90,
      i_rst_n => ddr3_rst,
      o_ddr3_clk_p => ddr3_ck_p,
      o_ddr3_clk_n => ddr3_ck_n,
      o_ddr3_reset_n => ddr3_reset_n,
      o_ddr3_cke => ddr3_cke,
      o_ddr3_cs_n => ddr3_cs_n,
      o_ddr3_ras_n => ddr3_ras_n,
      o_ddr3_cas_n => ddr3_cas_n,
      o_ddr3_we_n => ddr3_we_n,
      o_ddr3_addr => ddr3_addr,
      o_ddr3_ba_addr => ddr3_ba,
      io_ddr3_dq => ddr3_dq,
      io_ddr3_dqs => ddr3_dqs_p,
      io_ddr3_dqs_n => ddr3_dqs_n,
      o_ddr3_dm => ddr3_dm,
      o_ddr3_odt => ddr3_odt,
      i_wb_cyc => i_wb_cyc,
      i_wb_stb => i_wb_stb,
      i_wb_we => i_wb_we,
      o_wb_data => o_wb_data,
      i_wb_data => i_wb_data,
      i_wb_addr => i_wb_addr,
      i_wb_sel => i_wb_sel,
      o_wb_ack => o_wb_ack,
      o_wb_stall => o_wb_stall,
      i_wb2_cyc =>  '0',
      i_wb2_stb => '0',
      i_wb2_we => '0',
      i_wb2_addr => (others => '0'),
      i_wb2_data => (others => '0'),
      i_wb2_sel => (others => '0'),
      i_aux => (others => '0'),
      o_calib_complete => calib_done,
      i_user_self_refresh => '0'
    );

end;

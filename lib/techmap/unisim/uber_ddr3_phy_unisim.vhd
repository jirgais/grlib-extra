--////////////////////////////////////////////////////////////////////////////////
--//
--// Filename: ddr3_phy.v
--// Project: UberDDR3 - An Open Source DDR3 Controller
--//
--// Purpose: PHY component for the DDR3 controller. Handles the primitives such
--// as IOSERDES, IODELAY, and IOBUF. These generates the signals connected to
--// the DDR3 RAM.
--//
--// Engineer: Angelo C. Jacobo
--//
--////////////////////////////////////////////////////////////////////////////////
--//
--// Copyright (C) 2023-2025  Angelo Jacobo
--//
--//     This program is free software: you can redistribute it and/or modify
--//     it under the terms of the GNU General Public License as published by
--//     the Free Software Foundation, either version 3 of the License, or
--//     (at your option) any later version.
--//
--//     This program is distributed in the hope that it will be useful,
--//     but WITHOUT ANY WARRANTY; without even the implied warranty of
--//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--//     GNU General Public License for more details.
--//
--//     You should have received a copy of the GNU General Public License
--//     along with this program.  If not, see <https://www.gnu.org/licenses/>.
--//
--////////////////////////////////////////////////////////////////////////////////

-- Converted from verilog to VHDL by Jiri Gaisler, 2026.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library grlib;
use grlib.stdlib.all;

entity uber_ddr3_phy_unisim is
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
end;

architecture rtl of uber_ddr3_phy_unisim is
  constant cmd_len : integer := (7 + BA_BITS + ROW_BITS + 2*DUAL_RANK_DIMM);
  constant CMD_CS_N_2 : integer := cmd_len -1;
  constant CMD_CS_N : integer := cmd_len - DUAL_RANK_DIMM - 1;
  constant CMD_RAS_N : integer := cmd_len - DUAL_RANK_DIMM - 2;
  constant CMD_CAS_N : integer := cmd_len - DUAL_RANK_DIMM - 3;
  constant CMD_WE_N : integer := cmd_len - DUAL_RANK_DIMM - 4;
  constant CMD_ODT : integer := cmd_len - DUAL_RANK_DIMM - 5;
  constant CMD_CKE_2 : integer := cmd_len - DUAL_RANK_DIMM - 6;
  constant CMD_CKE : integer := cmd_len - DUAL_RANK_DIMM*2 - 6;
  constant CMD_RESET_N : integer := cmd_len - DUAL_RANK_DIMM*2 - 7;
  constant CMD_BANK_START : integer := BA_BITS + ROW_BITS - 1;
  constant CMD_ADDRESS_START : integer := ROW_BITS - 1;
  constant SYNC_RESET_DELAY : integer := 52000/CONTROLLER_CLK_PERIOD + 1;
  constant SYNC_RESET_DELAY_BITS : integer := log2x(SYNC_RESET_DELAY) + 1;
  constant DATA_IDELAY_TAP : integer := 0;
  constant DQS_IDELAY_TAP : integer := ((DDR3_CLK_PERIOD*1000/4))/78125 + DATA_IDELAY_TAP;

  signal oserdes_cmd, cmd : std_logic_vector(cmd_len -1 downto 0);
  signal oserdes_data, odelay_data, idelay_data, read_dq :
     std_logic_vector((DQ_BITS*LANES)-1 downto 0);
  signal oserdes_dm, odelay_dm : std_logic_vector(LANES-1 downto 0);
  signal odelay_dqs, read_dqs, idelay_dqs : std_logic_vector(LANES-1 downto 0);
  signal oserdes_dq_tri_control : std_logic_vector((DQ_BITS*LANES)-1 downto 0);
  signal oserdes_dqs : std_logic_vector(LANES-1 downto 0);
  signal oserdes_dqs_tri_control : std_logic_vector(LANES-1 downto 0);
  signal oserdes_bitslip_reference : std_logic_vector(LANES-1 downto 0);
  signal delay_before_release_reset :
    std_logic_vector(SYNC_RESET_DELAY_BITS-1 downto 0);
  signal sync_rst, ddr3_clk, ddr3_clk_delayed : std_logic;
  signal toggle_dqs_q : std_logic;
  signal idelayctrl_rdy, dci_locked : std_logic;
  signal o_controller_iserdes_bitslip_reference_reg :
    std_logic_vector(LANES*8-1 downto 0);
  signal shift_bitslip_index : std_logic_vector(LANES-1 downto 0);
  signal i_ddr3_clk_n : std_logic;
  signal dqs_temp : std_logic_vector(1 to 8);
  attribute IODELAY_GROUP : string;
begin

  i_ddr3_clk_n <= not i_ddr3_clk;
  o_controller_idelayctrl_rdy <= idelayctrl_rdy and dci_locked;

  synrst : process (i_controller_clk)
  begin
    if rising_edge(i_controller_clk) then
      if (i_rst_n = '0') or (i_controller_reset = '1') then
        sync_rst <= '1';
        delay_before_release_reset <=
          conv_std_logic_vector(SYNC_RESET_DELAY, SYNC_RESET_DELAY_BITS);
        toggle_dqs_q <= '0';
      else
        if delay_before_release_reset /= zero32(SYNC_RESET_DELAY_BITS-1 downto 0) then
          delay_before_release_reset <= delay_before_release_reset - 1;
          sync_rst <= '1';
        else
          sync_rst <= '0';
        end if;
        toggle_dqs_q <= i_controller_toggle_dqs;
      end if;
    end if;
  end process;

  phycmd : for i in 0 to cmd_len-1 generate
    OSERDESE2_cmd : OSERDESE2
--    OSERDESE2_cmd : entity work.OSERDESE2_model
    generic map( DATA_RATE_OQ => "SDR", DATA_RATE_TQ => "SDR", DATA_WIDTH => 4,
      INIT_OQ => '0', TRISTATE_WIDTH => 1)
    port map(OQ => oserdes_cmd(i),CLK => i_ddr3_clk, CLKDIV => i_controller_clk,
      D1 => i_controller_cmd(cmd_len*0 + i),
      D2 => i_controller_cmd(cmd_len*1 + i),
      D3 => i_controller_cmd(cmd_len*2 + i),
      D4 => i_controller_cmd(cmd_len*3 + i),
      D5 => '0', D6 => '0', D7 => '0', D8 => '0',
      OCE => '1', RST => sync_rst, SHIFTIN1 => '0', SHIFTIN2 => '0',
      T1 => '0', T2 => '0', T3 => '0', T4 => '0', TBYTEIN => '0', TCE => '0'
    );
  end generate;

 -- skip dual_rank for now
  nodr : if DUAL_RANK_DIMM = 0 generate

    o_ddr3_cs_n(0) <= oserdes_cmd(CMD_CS_N);
    o_ddr3_cke(0) <= oserdes_cmd(CMD_CKE);
    o_ddr3_odt(0) <= oserdes_cmd(CMD_ODT);

  end generate;

  o_ddr3_ras_n <= oserdes_cmd(CMD_RAS_N);
  o_ddr3_cas_n <= oserdes_cmd(CMD_CAS_N);
  o_ddr3_we_n <= oserdes_cmd(CMD_WE_N);
  o_ddr3_reset_n <= oserdes_cmd(CMD_RESET_N);
  o_ddr3_ba_addr <= oserdes_cmd(CMD_BANK_START downto CMD_ADDRESS_START+1);
  o_ddr3_addr <= oserdes_cmd(CMD_ADDRESS_START downto 0);

  obufds_clk : OBUFDS
  port map ( o => o_ddr3_clk_p(0), ob => o_ddr3_clk_n(0), i => i_ddr3_clk);

  phydata : for i in 0 to (DQ_BITS*LANES)-1 generate
  attribute IODELAY_GROUP of idel_data: label is "DDR3-GROUP";
  begin
    OSERDESE2_data : OSERDESE2
--    OSERDESE2_data : entity work.OSERDESE2_model
    generic map( DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "BUF", DATA_WIDTH => 8,
      INIT_OQ => '0', TRISTATE_WIDTH => 1)
    port map(
      OFB => open,
      OQ => oserdes_data(i),
      TQ => oserdes_dq_tri_control(i),
      CLK => i_ddr3_clk_90,
      CLKDIV => i_controller_clk,
      D1 => i_controller_data(i + (DQ_BITS*LANES)*0),
      D2 => i_controller_data(i + (DQ_BITS*LANES)*1),
      D3 => i_controller_data(i + (DQ_BITS*LANES)*2),
      D4 => i_controller_data(i + (DQ_BITS*LANES)*3),
      D5 => i_controller_data(i + (DQ_BITS*LANES)*4),
      D6 => i_controller_data(i + (DQ_BITS*LANES)*5),
      D7 => i_controller_data(i + (DQ_BITS*LANES)*6),
      D8 => i_controller_data(i + (DQ_BITS*LANES)*7),
      OCE => '1', RST => sync_rst, SHIFTIN1 => '0', SHIFTIN2 => '0',
      T1 => i_controller_dq_tri_control,
      T2 => '0', T3 => '0', T4 => '0', TBYTEIN => '0', TCE => '1'
    );

    iobuf_data : IOBUF
    generic map (IBUF_LOW_PWR => FALSE, SLEW => "FAST")
    port map (o => read_dq(i), io => io_ddr3_dq(i), i => oserdes_data(i),
      t => oserdes_dq_tri_control(i));

    idel_data : IDELAYE2
--    idel_data : entity work.IDELAYE2_model
    generic map (DELAY_SRC => "IDATAIN", HIGH_PERFORMANCE_MODE => "TRUE",
      IDELAY_TYPE => "VAR_LOAD", IDELAY_VALUE => DATA_IDELAY_TAP,
      PIPE_SEL => "FALSE", REFCLK_FREQUENCY => 200.0, SIGNAL_PATTERN => "DATA" )
    port map (DATAOUT => idelay_data(i), C => i_controller_clk, CE => '0',
      CINVCTRL => '0', CNTVALUEIN => i_controller_idelay_data_cntvaluein,
      IDATAIN => read_dq(i), INC => '0', LD => i_controller_idelay_data_ld(i/8),
      DATAIN => '0', LDPIPEEN => '0', REGRST => '0');

    iser_data : ISERDESE2
--    iser_data : entity work.ISERDESE2_model
    generic map (DATA_RATE => "DDR", DATA_WIDTH => 8,
      INIT_Q1 => '0', INIT_Q2 => '0', INIT_Q3 => '0', INIT_Q4 => '0',
      INTERFACE_TYPE => "NETWORKING", IOBDELAY => "IFD", NUM_CE => 1,
      OFB_USED => "FALSE",
      SRVAL_Q1 => '0', SRVAL_Q2 => '0', SRVAL_Q3 => '0', SRVAL_Q4 => '0')
    port map (
      Q1 => o_controller_iserdes_data((DQ_BITS*LANES)*7 + i),
      Q2 => o_controller_iserdes_data((DQ_BITS*LANES)*6 + i),
      Q3 => o_controller_iserdes_data((DQ_BITS*LANES)*5 + i),
      Q4 => o_controller_iserdes_data((DQ_BITS*LANES)*4 + i),
      Q5 => o_controller_iserdes_data((DQ_BITS*LANES)*3 + i),
      Q6 => o_controller_iserdes_data((DQ_BITS*LANES)*2 + i),
      Q7 => o_controller_iserdes_data((DQ_BITS*LANES)*1 + i),
      Q8 => o_controller_iserdes_data((DQ_BITS*LANES)*0 + i),
      BITSLIP => i_controller_bitslip(i/8),
      CE1 => '1', CE2 => '1', CLK => i_ddr3_clk, CLKB => i_ddr3_clk_n,
      CLKDIV => i_controller_clk, DDLY => idelay_data(i), RST => sync_rst,
      CLKDIVP => '0', D => '0', DYNCLKDIVSEL => '0', DYNCLKSEL => '0',
      OCLK => '0', OCLKB => '0', OFB => '0', SHIFTIN1 => '0', SHIFTIN2 => '0'
      );

  end generate;

  phydm : for i in 0 to LANES-1 generate
--  attribute IODELAY_GROUP of idel_data: label is "DDR3-GROUP";
  begin

    OSERDESE2_dm : OSERDESE2
--    OSERDESE2_dm : entity work.OSERDESE2_model
    generic map( DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "BUF", DATA_WIDTH => 8,
      INIT_OQ => '0', TRISTATE_WIDTH => 1)
    port map(
      OFB => open,
      OQ => oserdes_dm(i),
      CLK => i_ddr3_clk_90,
      CLKDIV => i_controller_clk,
      D1 => i_controller_dm(i + LANES*0),
      D2 => i_controller_dm(i + LANES*1),
      D3 => i_controller_dm(i + LANES*2),
      D4 => i_controller_dm(i + LANES*3),
      D5 => i_controller_dm(i + LANES*4),
      D6 => i_controller_dm(i + LANES*5),
      D7 => i_controller_dm(i + LANES*6),
      D8 => i_controller_dm(i + LANES*7),
      OCE => '1', RST => sync_rst, SHIFTIN1 => '0', SHIFTIN2 => '0',
      T1 => '0', T2 => '0', T3 => '0', T4 => '0', TBYTEIN => '0', TCE => '0'
    );

    obuf_dm : OBUF
    generic map (SLEW => "FAST")
    port map (o => o_ddr3_dm(i), i => oserdes_dm(i));

  end generate;

  -- this looks silly but it is how the original code looked like ...

  dqs_temp(1) <= (i_controller_toggle_dqs or toggle_dqs_q);
  dqs_temp(2) <= '0';
  dqs_temp(3) <= (i_controller_toggle_dqs or toggle_dqs_q) and
    not i_controller_write_leveling_calib;
  dqs_temp(4) <= '0';
  dqs_temp(5) <= i_controller_toggle_dqs and not i_controller_write_leveling_calib;
  dqs_temp(6) <= '0';
  dqs_temp(7) <= i_controller_toggle_dqs and not i_controller_write_leveling_calib;
  dqs_temp(8) <= '0';

  phydqs : for i in 0 to LANES-1 generate
  attribute IODELAY_GROUP of idel_dqs: label is "DDR3-GROUP";
  begin

    OSERDESE2_dqs : OSERDESE2
--    OSERDESE2_dqs : entity work.OSERDESE2_model
    generic map( DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "BUF", DATA_WIDTH => 8,
      INIT_OQ => '1', TRISTATE_WIDTH => 1)
    port map(
      OFB => open,
      OQ => oserdes_dqs(i),
      TQ => oserdes_dqs_tri_control(i),
      CLK => i_ddr3_clk_n,
      CLKDIV => i_controller_clk,
      D1 => dqs_temp(1), D2 => dqs_temp(2), D3 => dqs_temp(3),
      D4 => dqs_temp(4), D5 => dqs_temp(5), D6 => dqs_temp(6),
      D7 => dqs_temp(7), D8 => dqs_temp(8),
      OCE => '1', RST => sync_rst, SHIFTIN1 => '0', SHIFTIN2 => '0',
      T1 => i_controller_dq_tri_control,
      T2 => '0', T3 => '0', T4 => '0', TBYTEIN => '0', TCE => '1'
    );

    iobufds_dqs : IOBUFDS
--    iobufds_dqs : entity work.IOBUFDS_model
    generic map (IBUF_LOW_PWR => FALSE)
    port map (o => read_dqs(i), io => io_ddr3_dqs(i), iob => io_ddr3_dqs_n(i),
      i => oserdes_dqs(i), t => oserdes_dqs_tri_control(i));

    idel_dqs : IDELAYE2
--    idel_dqs : entity work.IDELAYE2_model
    generic map (DELAY_SRC => "IDATAIN", HIGH_PERFORMANCE_MODE => "TRUE",
      IDELAY_TYPE => "VAR_LOAD", IDELAY_VALUE => DQS_IDELAY_TAP,
      PIPE_SEL => "FALSE", REFCLK_FREQUENCY => 200.0, SIGNAL_PATTERN => "CLOCK" )
    port map (DATAOUT => idelay_dqs(i), C => i_controller_clk, CE => '0',
      CINVCTRL => '0', CNTVALUEIN => i_controller_idelay_dqs_cntvaluein,
      IDATAIN => read_dqs(i), INC => '0', LD => i_controller_idelay_dqs_ld(i),
      DATAIN => '0', LDPIPEEN => '0', REGRST => '0');

    iser_dqs : ISERDESE2
--    iser_dqs : entity work.ISERDESE2_model
    generic map (DATA_RATE => "DDR", DATA_WIDTH => serdes_ratio*2,
      INIT_Q1 => '0', INIT_Q2 => '0', INIT_Q3 => '0', INIT_Q4 => '0',
      INTERFACE_TYPE => "NETWORKING", IOBDELAY => "IFD", NUM_CE => 1,
      OFB_USED => "FALSE",
      SRVAL_Q1 => '0', SRVAL_Q2 => '0', SRVAL_Q3 => '0', SRVAL_Q4 => '0')
    port map (
      Q1 => o_controller_iserdes_dqs((serdes_ratio*2*i)+7),
      Q2 => o_controller_iserdes_dqs((serdes_ratio*2*i)+6),
      Q3 => o_controller_iserdes_dqs((serdes_ratio*2*i)+5),
      Q4 => o_controller_iserdes_dqs((serdes_ratio*2*i)+4),
      Q5 => o_controller_iserdes_dqs((serdes_ratio*2*i)+3),
      Q6 => o_controller_iserdes_dqs((serdes_ratio*2*i)+2),
      Q7 => o_controller_iserdes_dqs((serdes_ratio*2*i)+1),
      Q8 => o_controller_iserdes_dqs((serdes_ratio*2*i)+0),
      BITSLIP => i_controller_bitslip(i),
      CE1 => '1', CE2 => '1', CLK => i_ddr3_clk, CLKB => i_ddr3_clk_n,
      CLKDIV => i_controller_clk, DDLY => idelay_dqs(i), RST => sync_rst,
      CLKDIVP => '0', D => '0', DYNCLKDIVSEL => '0', DYNCLKSEL => '0',
      OCLK => '0', OCLKB => '0', OFB => '0', SHIFTIN1 => '0', SHIFTIN2 => '0'
      );

    no_ioser_lb : if NO_IOSERDES_LOOPBACK /= 0 generate
    begin
      rp : process (i_controller_clk)
      begin
        if rising_edge(i_controller_clk) then
          if (i_rst_n = '0') or (i_controller_reset = '1') then
            o_controller_iserdes_bitslip_reference_reg(serdes_ratio*2*i + 7 downto serdes_ratio*2*i) <= "00011110";
              shift_bitslip_index(i) <= '0';
          else
            if i_controller_bitslip(i) = '1' then
              if shift_bitslip_index(i) = '1' then
                o_controller_iserdes_bitslip_reference_reg((serdes_ratio*2*i + 7) downto (serdes_ratio*2*i)) <=  o_controller_iserdes_bitslip_reference_reg((serdes_ratio*2*i + 2) downto (serdes_ratio*2*i)) & o_controller_iserdes_bitslip_reference_reg((serdes_ratio*2*i + 7) downto (serdes_ratio*2*i + 3));
              else
                o_controller_iserdes_bitslip_reference_reg((serdes_ratio*2*i + 7) downto (serdes_ratio*2*i)) <=  o_controller_iserdes_bitslip_reference_reg((serdes_ratio*2*i + 6) downto (serdes_ratio*2*i)) & o_controller_iserdes_bitslip_reference_reg((serdes_ratio*2*i + 7));
              end if;
              shift_bitslip_index(i) <= not shift_bitslip_index(i);
            end if;
          end if;
        end if;
      end process;

      o_controller_iserdes_bitslip_reference <= o_controller_iserdes_bitslip_reference_reg;

    end generate;

  end generate;

  idel_ctrl : IDELAYCTRL
--  idel_ctrl : entity work.IDELAYCTRL_model
  port map ( RDY => idelayctrl_rdy, REFCLK => i_ref_clk, RST => sync_rst);

  dci_locked <= '1';

end;

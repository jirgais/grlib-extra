LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
library grlib;
use grlib.stdlib.all;

ENTITY ISERDESE2 IS	--
  generic (
     DATA_RATE : string := "DDR";
     DATA_WIDTH : integer := 4;
     DYN_CLKDIV_INV_EN : string := "FALSE";
     DYN_CLK_INV_EN : string := "FALSE";
     INIT_Q1 : bit := '0';
     INIT_Q2 : bit := '0';
     INIT_Q3 : bit := '0';
     INIT_Q4 : bit := '0';
     INTERFACE_TYPE : string := "MEMORY";
     IOBDELAY : string := "NONE";
     IS_CLKB_INVERTED : bit := '0';
     IS_CLKDIVP_INVERTED : bit := '0';
     IS_CLKDIV_INVERTED : bit := '0';
     IS_CLK_INVERTED : bit := '0';
     IS_D_INVERTED : bit := '0';
     IS_OCLKB_INVERTED : bit := '0';
     IS_OCLK_INVERTED : bit := '0';
     NUM_CE : integer := 2;
     OFB_USED : string := "FALSE";
     SERDES_MODE : string := "MASTER";
     SRVAL_Q1 : bit := '0';
     SRVAL_Q2 : bit := '0';
     SRVAL_Q3 : bit := '0';
     SRVAL_Q4 : bit := '0'
  );
  port (
     O : out std_ulogic;
     Q1 : out std_ulogic;
     Q2 : out std_ulogic;
     Q3 : out std_ulogic;
     Q4 : out std_ulogic;
     Q5 : out std_ulogic;
     Q6 : out std_ulogic;
     Q7 : out std_ulogic;
     Q8 : out std_ulogic;
     SHIFTOUT1 : out std_ulogic;
     SHIFTOUT2 : out std_ulogic;
     BITSLIP : in std_ulogic;
     CE1 : in std_ulogic;
     CE2 : in std_ulogic;
     CLK : in std_ulogic;
     CLKB : in std_ulogic;
     CLKDIV : in std_ulogic;
     CLKDIVP : in std_ulogic;
     D : in std_ulogic;
     DDLY : in std_ulogic;
     DYNCLKDIVSEL : in std_ulogic;
     DYNCLKSEL : in std_ulogic;
     OCLK : in std_ulogic;
     OCLKB : in std_ulogic;
     OFB : in std_ulogic;
     RST : in std_ulogic;
     SHIFTIN1 : in std_ulogic;
     SHIFTIN2 : in std_ulogic
  );
END ISERDESE2;


ARCHITECTURE sim OF ISERDESE2 IS

    signal counter, bitslip_counter : std_logic_vector(2 DOWNTO 0) := "000";
    signal clk_delayed, clkdiv_delayed : std_logic ;
    signal  Q_clk_0, Q_clk_1 : std_logic_vector(7 DOWNTO 0);

BEGIN

    PROCESS
    BEGIN
        assert not((DATA_RATE /= "DDR") or (DATA_WIDTH /= 8))
            report "DATA_WIDTH must be 8 and DATA_RATE mustbe DDR"
            severity failure;
        assert (INTERFACE_TYPE = "NETWORKING")
            report "INTERFACE_TYPE must be NETWORKING"
            severity failure;
        assert (IOBDELAY = "IFD")
            report "IOBDELAY must be IFD"
            severity failure;
        assert (OFB_USED = "FALSE")
            report "OFB_USED must be FALSE"
            severity failure;
        WAIT;
    END PROCESS;


  clk_delayed <= TRANSPORT CLK AFTER 100 ps;
  clkdiv_delayed <= TRANSPORT CLKDIV AFTER 100 ps;


    PROCESS
    BEGIN
      WAIT UNTIL rising_edge(CLKDIV);
      if BITSLIP = '1' then
        bitslip_counter <= bitslip_counter + 1;
      end if;
    END PROCESS;

    PROCESS
    BEGIN
      WAIT UNTIL rising_edge(CLKDIV) or rising_edge(clk_delayed) OR falling_edge(clk_delayed);
      if rising_edge(CLKDIV) then
        IF RST = '1' THEN
          counter <= "000";
        end if;
      end if;
      if rising_edge(clk_delayed) OR falling_edge(clk_delayed) then
        counter <= counter + 1;
      end if;
    END PROCESS;

    PROCESS
    variable ctmp : std_logic_vector(2 downto 0);
    BEGIN
      WAIT UNTIL rising_edge(clk) OR falling_edge(clk);
        ctmp := counter - bitslip_counter;
        case ctmp is
        when "000" => Q_clk_0(3) <= DDLY;
        when "001" => Q_clk_0(2) <= DDLY;
        when "010" => Q_clk_0(1) <= DDLY;
        when "011" => Q_clk_0(0) <= DDLY;
          Q_clk_1 <= Q_clk_0(7 downto 1) & DDLY;
        when "100" => Q_clk_0(7) <= DDLY;
        when "101" => Q_clk_0(6) <= DDLY;
        when "110" => Q_clk_0(5) <= DDLY;
        when others => Q_clk_0(4) <= DDLY;
        end case;
    END PROCESS;


    PROCESS
    variable ctmp : std_logic_vector(2 downto 0);
    BEGIN
      WAIT UNTIL rising_edge(clkdiv_delayed);
        Q8 <= Q_clk_1(7);
        Q7 <= Q_clk_1(6);
        Q6 <= Q_clk_1(5);
        Q5 <= Q_clk_1(4);
        Q4 <= Q_clk_1(3);
        Q3 <= Q_clk_1(2);
        Q2 <= Q_clk_1(1);
        Q1 <= Q_clk_1(0);
    END PROCESS;

END sim;


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
library grlib;
use grlib.stdlib.all;

ENTITY OSERDESE2 IS	--
  generic (
     DATA_RATE_OQ : string := "DDR";
     DATA_RATE_TQ : string := "DDR";
     DATA_WIDTH : integer := 4;
     INIT_OQ : bit := '0';
     INIT_TQ : bit := '0';
     IS_CLKDIV_INVERTED : bit := '0';
     IS_CLK_INVERTED : bit := '0';
     IS_D1_INVERTED : bit := '0';
     IS_D2_INVERTED : bit := '0';
     IS_D3_INVERTED : bit := '0';
     IS_D4_INVERTED : bit := '0';
     IS_D5_INVERTED : bit := '0';
     IS_D6_INVERTED : bit := '0';
     IS_D7_INVERTED : bit := '0';
     IS_D8_INVERTED : bit := '0';
     IS_T1_INVERTED : bit := '0';
     IS_T2_INVERTED : bit := '0';
     IS_T3_INVERTED : bit := '0';
     IS_T4_INVERTED : bit := '0';
     SERDES_MODE : string := "MASTER";
     SRVAL_OQ : bit := '0';
     SRVAL_TQ : bit := '0';
     TBYTE_CTL : string := "FALSE";
     TBYTE_SRC : string := "FALSE";
     TRISTATE_WIDTH : integer := 4
  );
  port (
     OFB : out std_ulogic;
     OQ : out std_ulogic;
     SHIFTOUT1 : out std_ulogic;
     SHIFTOUT2 : out std_ulogic;
     TBYTEOUT : out std_ulogic;
     TFB : out std_ulogic;
     TQ : out std_ulogic;
     CLK : in std_ulogic;
     CLKDIV : in std_ulogic;
     D1 : in std_ulogic;
     D2 : in std_ulogic;
     D3 : in std_ulogic;
     D4 : in std_ulogic;
     D5 : in std_ulogic;
     D6 : in std_ulogic;
     D7 : in std_ulogic;
     D8 : in std_ulogic;
     OCE : in std_ulogic;
     RST : in std_ulogic;
     SHIFTIN1 : in std_ulogic;
     SHIFTIN2 : in std_ulogic;
     T1 : in std_ulogic;
     T2 : in std_ulogic;
     T3 : in std_ulogic;
     T4 : in std_ulogic;
     TBYTEIN : in std_ulogic;
     TCE : in std_ulogic
  );
END OSERDESE2;

ARCHITECTURE VeriArch OF OSERDESE2 IS
-- Intermediate signal for TQ
    SIGNAL V2V_TQ : std_logic;
-- Intermediate signal for OFB
    SIGNAL V2V_OFB : std_logic;
-- Intermediate signal for OQ
    SIGNAL V2V_OQ : std_logic;
-- Intermediate signal for SHIFTOUT1
    SIGNAL V2V_SHIFTOUT1 : std_logic;
-- Intermediate signal for SHIFTOUT2
    SIGNAL V2V_SHIFTOUT2 : std_logic;
-- Intermediate signal for TBYTEOUT
    SIGNAL V2V_TBYTEOUT : std_logic;
-- Intermediate signal for TFB
    SIGNAL V2V_TFB : std_logic;

    SIGNAL std_io : integer:= 1;

    SIGNAL D_clkdiv_q : std_logic_vector(7 DOWNTO 0);

    SIGNAL D_clk_q : std_logic_vector(7 DOWNTO 0);

    SIGNAL counter : std_logic_vector(2 DOWNTO 0) := "000";

    SIGNAL clk_delayed : std_logic ;

    SIGNAL D1_delayed : std_logic ;

    SIGNAL D2_delayed : std_logic ;

    SIGNAL D3_delayed : std_logic ;

    SIGNAL D4_delayed : std_logic ;

    SIGNAL D5_delayed : std_logic ;

    SIGNAL D6_delayed : std_logic ;

    SIGNAL D7_delayed : std_logic ;

    SIGNAL D8_delayed : std_logic ;

BEGIN
--  D1 - D8: Parallel data inputs
--  Buffer input/output for tristate controlle
--  Serial output
--  NOT MODELLED
--  stop simulation if this modelfile does not support the settings
    PROCESS
    BEGIN
        assert not((DATA_RATE_OQ = "SDR") AND (DATA_WIDTH /= 4))
            report "DATA_WIDTH must be 4 if DATA_RATE_OQ is SDR"
            severity failure;

        assert not((DATA_RATE_OQ = "DDR") AND (DATA_WIDTH /= 8))
            report "DATA_WIDTH must be 8 if DATA_RATE_OQ is DDR"
            severity failure;
        WAIT;
    END PROCESS;


    clk_delayed <= TRANSPORT CLK AFTER 100 ps;
    D1_delayed <= TRANSPORT D1 AFTER 100 ps;
    D2_delayed <= TRANSPORT D2 AFTER 100 ps;
    D3_delayed <= TRANSPORT D3 AFTER 100 ps;
    D4_delayed <= TRANSPORT D4 AFTER 100 ps;
    D5_delayed <= TRANSPORT D5 AFTER 100 ps;
    D6_delayed <= TRANSPORT D6 AFTER 100 ps;
    D7_delayed <= TRANSPORT D7 AFTER 100 ps;
    D8_delayed <= TRANSPORT D8 AFTER 100 ps;
    V2V_TQ <= TRANSPORT T1 AFTER 100 ps;

-- ---------------------------------------------------------------------------------------//
-- ----------------------------------- DATA RATE = DDR -----------------------------------//
-- ---------------------------------------------------------------------------------------//
--     if(DATA_RATE_OQ == "DDR") begin
--  reset the counter on CLKDIV posedge to make sure first CLK posedge has counter == 0
  ddr_gen : if(DATA_RATE_OQ = "DDR") generate
  begin

    PROCESS
    BEGIN
        WAIT UNTIL rising_edge(clk_delayed) OR falling_edge(clk_delayed)
          or rising_edge(CLKDIV);

        if rising_edge(CLKDIV) then
          IF RST = '1' THEN
            counter <= "000";
          END IF;
        END IF;

        if rising_edge(clk_delayed) OR falling_edge(clk_delayed) then
          V2V_OQ <= D_clk_q(conv_integer(counter));
          IF NOT ((counter = "000") AND (clk_delayed = '0')) THEN
            counter <= counter + "001";	-- counts from 0->1->2->...->7->0..
--  should never happen where counter will increment up from zero @negedge (only @posedge will 0 increments to 1)
          END IF;
        END IF;
    END PROCESS;


    PROCESS
    BEGIN
        WAIT UNTIL rising_edge(CLK);

        IF counter = "000" THEN
            D_clkdiv_q <= D8 & D7 & D6 & D5 & D4 & D3 & D2 & D1;
--  store D1-D8 at first CLK posedge after CLKDIV posedge (in short the time when counter == 0)
            D_clk_q <= D_clkdiv_q;

        END IF;

        IF RST = '1' THEN
            D_clkdiv_q <= (others => '0');
            D_clk_q <= (others => '0');
        END IF;
    END PROCESS;
  end generate;

  sdr_gen : if(DATA_RATE_OQ = "SDR") generate
  begin

    PROCESS
    BEGIN
      WAIT UNTIL rising_edge(CLKDIV) or rising_edge(clk_delayed);
      if rising_edge(CLKDIV) then
        IF RST = '1' THEN
          counter <= "000";
        END IF;
      END IF;
      if rising_edge(clk_delayed) then
        case counter(1 downto 0) is
          when "00" => V2V_OQ <= D_clk_q(0);
          when "01" => V2V_OQ <= D_clk_q(1);
          when "10" => V2V_OQ <= D_clk_q(2);
          when others => V2V_OQ <= D_clk_q(3);
        end case;
        if counter(1 downto 0) = "11" then
          counter <= "000";
        else
          counter <= counter + "001";
        end if;
      end if;
    END PROCESS;

    PROCESS
    BEGIN
        WAIT UNTIL rising_edge(CLK);
        IF RST = '1' THEN
          D_clkdiv_q <= (others => '0');
          D_clk_q <= (others => '0');
        elsif counter = "000" then
          D_clkdiv_q <= "0000" & D4&D3&D2&D1;
          D_clk_q <= D_clkdiv_q;
        end if;

    END PROCESS;

  end generate;

    TQ <= V2V_TQ;
    OQ <= V2V_OQ;
    V2V_OFB <= V2V_OQ;
    OFB <= V2V_OQ;
    SHIFTOUT1 <= V2V_SHIFTOUT1;
    SHIFTOUT2 <= V2V_SHIFTOUT2;
    TBYTEOUT <= V2V_TBYTEOUT;
    TFB <= V2V_TFB;
END VeriArch;

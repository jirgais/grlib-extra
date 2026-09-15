-----------------------------------------------------
-- Clock generator for uber_ddr3. Based on clk_wiz.v
-----------------------------------------------------
-- Jiri Gaisler, 2026.


library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity uber_clk is
  generic (clkmul : integer := 10);
  port (
    -- async reset
    rstn        : in    std_logic;
    clkin       : in    std_logic;
    clk83       : out   std_logic;
    clk333      : out   std_logic;
    clk200      : out   std_logic;
    clk333_90   : out   std_logic;
    clk25       : out   std_logic;
    locked      : out   std_logic
  );
end;

architecture rtl of uber_clk is
  signal clkfbout    : std_logic;
  signal clk_pll_i, clk333i, clk200i, clk333_90i, clk25i : std_logic;
  signal reset                : std_ulogic;
begin

  reset <= not rstn;

  clk25_buf: unisim.vcomponents.BUFG
  port map (
      I => clk25i,
      O => clk25
  );
  clk83_buf : unisim.vcomponents.BUFG
     port map (
      I => clk_pll_i,
      O => clk83
    );
  clk333_buf : unisim.vcomponents.BUFG
     port map (
      I => clk333i,
      O => clk333
    );
  clk333_90_buf : unisim.vcomponents.BUFG
     port map (
      I => clk333_90i,
      O => clk333_90
    );

  clk200_buf : unisim.vcomponents.BUFG
     port map (
      I => clk200i,
      O => clk200
    );
  plle2_adv_inst: unisim.vcomponents.PLLE2_ADV
    generic map(
      BANDWIDTH => "OPTIMIZED",
      COMPENSATION => "INTERNAL",
      STARTUP_WAIT => "FALSE",
      DIVCLK_DIVIDE => 1,
      CLKFBOUT_MULT => clkmul,  -- 1000/1200 MHz base clk
      CLKFBOUT_PHASE => 0.000000,
      CLKIN1_PERIOD => 10.000000, -- 100 MHz in clk
      CLKIN2_PERIOD => 0.000000,
      CLKOUT0_DIVIDE => 12,       -- 83.33/100 MHz system clock
      CLKOUT0_DUTY_CYCLE => 0.500000,
      CLKOUT0_PHASE => 0.000000,
      CLKOUT1_DIVIDE => 3,        -- 333.33/400 MHz DDR clock
      CLKOUT1_DUTY_CYCLE => 0.500000,
      CLKOUT1_PHASE => 0.000000,
      CLKOUT2_DIVIDE => clkmul/2,        -- 200 MHz delay clock
      CLKOUT2_DUTY_CYCLE => 0.500000,
      CLKOUT2_PHASE => 0.000000,
      CLKOUT3_DIVIDE => 3,        -- 333.33/400 MHz 90 phase
      CLKOUT3_DUTY_CYCLE => 0.500000,
      CLKOUT3_PHASE => 90.000000,
      CLKOUT4_DIVIDE => 4*clkmul,       -- 25 MHz eth clock
      CLKOUT4_DUTY_CYCLE => 0.500000,
      CLKOUT4_PHASE => 0.000000,
      CLKOUT5_DIVIDE => 1,
      CLKOUT5_DUTY_CYCLE => 0.500000,
      CLKOUT5_PHASE => 0.000000,
      REF_JITTER1 => 0.010000,
      REF_JITTER2 => 0.010000
    )
    port map (
      CLKFBIN => clkfbout,
      CLKFBOUT => clkfbout,
      CLKIN1 => clkin,
      CLKIN2 => '0',
      CLKINSEL => '1',
      CLKOUT0 => clk_pll_i,
      CLKOUT1 => clk333i,
      CLKOUT2 => clk200i,
      CLKOUT3 => clk333_90i,
      CLKOUT4 => clk25i,
      CLKOUT5 => open,
      DADDR => (others => '0'),
      DCLK => '0',
      DEN => '0',
      DI => (others => '0'),
      DO => open,
      DRDY => open,
      DWE => '0',
      LOCKED => locked,
      PWRDWN => '0',
      RST => reset
    );
end;

------------------------------------------------------------------------------
--  This file is a part of the IRIS FPU VHDL model
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
-----------------------------------------------------------------------------
-- Entity:      grlfpu
-- File:        grlfpu_iris.vhd
-- Author:      Jiri Gaisler
-- Description: FPU controller for IRIS
------------------------------------------------------------------------------
-- Wrapper for IRIS to emulate grlfpu
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library contrib;

entity grlfpu is
  port(
    clock      : in  std_logic;
    FpInst     : in  std_logic_vector(9 downto 0);
    FpOp       : in  std_logic;
    FpLd       : in  std_logic;
    Reset      : in  std_logic;
    Flush      : in  std_logic;
    fprf_dout1 : in  std_logic_vector(63 downto 0);
    fprf_dout2 : in  std_logic_vector(63 downto 0);
    RoundingMode : in  std_logic_vector(1 downto 0);
    FpBusy     : out std_logic;
    FracResult : out std_logic_vector(54 downto 3);
    ExpResult  : out std_logic_vector(10 downto 0);
    SignResult : out std_logic;
    SNnotDB    : out std_logic;
    Excep      : out std_logic_vector(5 downto 0);
    ConditionCodes : out std_logic_vector(1 downto 0)
  );
end;

architecture rtl of grlfpu is

  component irisfpu
  generic(
    fpga      : integer := 0;  -- optimize timing for fpga
    busydelay : integer := 0;  -- 0 or 1 clock delay from busy to data
    srtopt    : integer range 0 to 3 := 3;  -- div speed, increases area
    tinypostrnd : integer range 0 to 1 := 0;  -- detect tininess after rounding
    fsmulden  : integer range 0 to 1 := 1  -- enable FSMULD instruction
   );
  port(
    clock      : in  std_logic;
    FpInst     : in  std_logic_vector(9 downto 0); --op3(0) & opf
    FpOp       : in  std_logic;
    FpLd       : in  std_logic;
    Reset      : in  std_logic;
    fprf_dout1 : in  std_logic_vector(63 downto 0);
    fprf_dout2 : in  std_logic_vector(63 downto 0);
    RoundingMode : in  std_logic_vector(1 downto 0); -- 00:near, 01: zero, 10:+inf, 11:-inf
    FpBusy     : out std_logic;
    FracResult : out std_logic_vector(54 downto 3);
    ExpResult  : out std_logic_vector(10 downto 0);
    SignResult : out std_logic;
    SNnotDB    : out std_logic; -- 0: double results, 1: single result
    Excep      : out std_logic_vector(5 downto 0); -- unimp, nv, ovf, unf, divz, nx
    ConditionCodes : out std_logic_vector(1 downto 0)-- 00:op1=op2, 01:op1<op2, 10:op1>op2, 11:unordered
  );
  end component;

signal rst : std_logic;

begin

  rst <= Reset or Flush;

  irisfpu0 : irisfpu
  generic map (0, 1, 3, 0, 1)
  port map (clock, FpInst, FpOp, FpLd, rst, fprf_dout1, fprf_dout2,
    RoundingMode, FpBusy, FracResult, ExpResult, SignResult, SNnotDB,
    Excep, ConditionCodes);
end;

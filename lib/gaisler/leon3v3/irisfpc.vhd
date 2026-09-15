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
-- Entity:      irisfpc
-- File:        irisfpc.vhd
-- Author:      Jiri Gaisler
-- Description: FPU controller for IRIS
------------------------------------------------------------------------------
-- leon3 floating-point controller (FPC) for the IRIS FPU. Also implements the
-- SPARC FPU registers %fsr, %fq and %f0 - %f31. One FPU instruction (fpop)
-- can run in parallel with the CPU. The fmovs/fabss/fnegs instructions
-- are executed in the FPC and do not enter the FPU. fmovs/fabss/fnegs
-- and FPU load/stores can overtake executing fpops as long as there is no
-- data dependency. The floating-point queue (FPQ) has one entry, consisting
-- of the trapped instructions address and opcode.
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
use grlib.sparc.all;
-- pragma translate_off
use grlib.sparc_disas.all;
-- pragma translate_on

library gaisler;
use gaisler.leon3.all;
use gaisler.libleon3.all;
use gaisler.libfpu.all;
library techmap;
use techmap.gencomp.all;
library contrib;

entity irisfpc is
  generic (
    tech     : integer := 0;
    pclow    : integer range 0 to 2 := 2;
    dsu      : integer range 0 to 1 := 0;
    disas    : integer range 0 to 2 := 0;
    pipe     : integer              := 0;
    netlist  : integer              := 0;
    index    : integer              := 0;
    scantest : integer              := 0);
  port (
    rst    : in  std_ulogic;                    -- Reset
    clk    : in  std_ulogic;
    holdn  : in  std_ulogic;                    -- pipeline hold
    cpi    : in  fpc_in_type;
    cpo    : out fpc_out_type;
    testin : in  std_logic_vector(TESTIN_WIDTH-1 downto 0)
    );
end;

architecture rtl of irisfpc is

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

  function isldf (d : std_logic_vector(31 downto 0)) return boolean is
  begin
    return (d(31 downto 30) = LDST) and
      ((d(24 downto 19) = LDF) or (d(24 downto 19) = LDDF));
  end;

  type fpc_state_type is (nominal, expend, except);
  type fpq_type is record
    act    : std_logic; -- fpop active
    com    : std_logic; -- fpop commited
    fccv   : std_logic;
    pc     : std_logic_vector(31 downto 0);
    inst   : std_logic_vector(31 downto 0);
  end record;

  type fsr_type is record -- %fsr bits according SPARC V8 standard p.34
    rd       : std_logic_vector(1 downto 0);     -- rounding direction
    tem      : std_logic_vector(4 downto 0);     -- trap enable mask
    ftt      : std_logic_vector(2 downto 0);     -- fpu trap type
    qne      : std_logic;                        -- queue not empty
    fcc      : std_logic_vector(1 downto 0);     -- fpu condition codes
    aexc     : std_logic_vector(4 downto 0);     -- accrued exception
    cexc     : std_logic_vector(4 downto 0);     -- current exception
  end record;

  type reg_type is record
    fpq        : fpq_type;
    fsr        : fsr_type;
    fpop       : std_logic;
    state      : fpc_state_type;
    eres, mres, xres : std_logic_vector(31 downto 0);
    amov, emov, mmov, xmov : std_logic;
  end record;

  constant FPCVER : std_logic_vector(2 downto 0) := "100"; -- set fsr.ver to 4
  signal FpInst     : std_logic_vector(9 downto 0); --op3(0) & opf
  signal FpOp       : std_logic;
  signal FpLd       : std_logic;
  signal Reset      : std_logic;
  signal fprf_dout1 : std_logic_vector(63 downto 0);
  signal fprf_dout2 : std_logic_vector(63 downto 0);
  signal RoundingMode : std_logic_vector(1 downto 0);
  signal FpBusy     : std_logic;
  signal FracResult : std_logic_vector(54 downto 3);
  signal ExpResult  : std_logic_vector(10 downto 0);
  signal SignResult : std_logic;
  signal SNnotDB    : std_logic; -- 0: double results, 1: single result
  signal Excep      : std_logic_vector(5 downto 0); -- unimp, nv, ovf, unf, divz, nx
  signal ConditionCodes : std_logic_vector(1 downto 0);
  signal disfsr : std_logic;

  signal rfi1, rfi2  : fp_rf_in_type;
  signal rfo1, rfo2  : fp_rf_out_type;
  signal r, rin : reg_type;

begin

  comb : process (r, FpBusy, FracResult, ExpResult, SignResult, SNnotDB,
    Excep, ConditionCodes, rfo1, rfo2, rst, holdn, cpi)
  variable rfa1, rfa2, rfwa : std_logic_vector(4 downto 0);
  variable dinst, dsudata, stfdata : std_logic_vector(31 downto 0);
  variable rfdata1, rfdata2, rfwdata, fpures : std_logic_vector(63 downto 0);
  variable v : reg_type;
  variable fpurst, fpopv : std_logic;
  variable wren1, wren2 : std_logic;
  variable loadfsr, ldlock, disins : std_logic;
  begin

    v := r;
    fpopv := '0'; dinst := cpi.d.inst;
    wren1 := '0'; wren2 := '0';
    loadfsr := '0'; fpurst := '0'; ldlock := '0';
    disins := '0'; rfwa := cpi.x.inst(29 downto 25);

    -- generate result depending on single- or double-precision
    if SNnotDB = '1' then
      fpures := SignResult & ExpResult(7 downto 0) & FracResult (54 downto 32) &
                 SignResult & ExpResult(7 downto 0) & FracResult (54 downto 32);
    else
      fpures := SignResult & ExpResult(10 downto 0) & FracResult (54 downto 3);
    end if;

    if r.xmov = '1' then
      rfwdata := r.xres & r.xres;
    else
      rfwdata := fpures;
    end if;

  -- exception stage --

    if ((cpi.x.trap and not cpi.x.annul and holdn and cpi.flush) = '1') then
      if r.fpq.com = '0' then
        v.fpq.act := '0'; -- flush uncommited fpop on trap
        fpurst := '1'; -- reset fpu
        v.fpq.fccv := '1';  -- in case an fcmp was aborted
      end if;
    elsif (cpi.x.annul or cpi.x.trap or cpi.flush or not holdn) = '0' then
      if (cpi.x.inst(31 downto 30) = FMT3) then
        if (cpi.x.inst(24 downto 20) = FPOP1(5 downto 1)) then
        -- if fpop reaches x stage, store the result or mark it commited
          rfwa := r.fpq.inst(29 downto 25);
          if r.xmov = '1' then
            rfwa := cpi.x.inst(29 downto 25);
            v.fsr.ftt := "000";
            v.fsr.aexc := "00000";
            wren1 := not cpi.x.inst(25); wren2 := cpi.x.inst(25);
            disins := '1';
          else
          if FpBusy = '0' then
            v.fpq.act := '0';
            if Excep(5) = '1' then -- dont update aexc/cexc on unimp fpop
              v.fsr.ftt := FPUNIMP_ERR;  -- unimp fpop
            elsif (r.fsr.tem and Excep(4 downto 0)) /= "00000" then
              v.fsr.cexc := r.fsr.tem and Excep(4 downto 0);
              v.fsr.ftt := FPIEEE_ERR;  -- ieee-754 exception
            else
              v.fsr.aexc := Excep(4 downto 0);
              v.fsr.cexc := r.fsr.aexc or Excep(4 downto 0);
              v.fsr.ftt := "000";
            end if;
            if v.fsr.ftt /= "000" then
              v.state := expend; v.fsr.qne := '1';
            end if;
            if (cpi.x.inst(24 downto 19) = FPOP1) and (v.fsr.ftt = "000") then
              if SNnotDB = '1' then
                wren1 := not r.fpq.inst(25); wren2 := r.fpq.inst(25);
              else
                wren1 := '1'; wren2 := '1';
              end if;
            elsif (cpi.x.inst(24 downto 19) = FPOP2) then
              if (v.fsr.ftt = "000") then
                v.fsr.fcc := ConditionCodes;
              end if;
              v.fpq.fccv := '1';
              disins := '1';
            end if;
          else
            v.fpq.com := '1';
          end if;
          end if;
        end if;
      elsif (cpi.x.inst(31 downto 30) = LDST) then
        if (cpi.x.inst(24 downto 19) = STFSR) then
          v.fpq.act := '0';
          v.fsr.ftt := "000";    -- STFSR clears fsr.ftt
        elsif (cpi.x.inst(24 downto 19) = LDFSR) then
          v.fpq.act := '0';
        elsif (cpi.x.inst(24 downto 19) = STDFQ) and (cpi.x.cnt = "00") then
          if r.fsr.qne = '0' then
            v.state := expend;
            v.fsr.ftt := FPSEQ_ERR;
          else
            v.fsr.qne := '0'; v.state := nominal;
          end if;
        end if;
      end if;
    end if;

    if (cpi.exack = '1') and (r.state = expend) then
      if r.fsr.qne = '1' then
        v.state := except;
      else
        v.state := nominal;
      end if;
    end if;

    -- generate rf write stobes for LD
    if (cpi.x.inst(31 downto 30) = LDST) then
      rfwdata := cpi.lddata & cpi.lddata;
      if (cpi.x.inst(24 downto 19) = LDF) then
        wren1 := not cpi.x.inst(25);
        wren2 := cpi.x.inst(25);
      elsif (cpi.x.inst(24 downto 19) = LDDF) then
        wren1 := not cpi.x.cnt(0);
        wren2 := cpi.x.cnt(0);
      elsif (cpi.x.inst(24 downto 19) = LDFSR) then
        loadfsr := '1';
      end if;
      rfwa := cpi.x.inst(29 downto 25);
    end if;

    -- abort load if trap or hold
    if (cpi.x.annul or cpi.x.trap or cpi.flush or not holdn) = '1' then
      wren1 := '0'; wren2 := '0'; loadfsr := '0';
    end if;

    -- write new fsr
    if loadfsr = '1' then
      v.fsr.rd   := cpi.lddata(31 downto 30);
      v.fsr.tem  := cpi.lddata(27 downto 23);
      v.fsr.fcc  := cpi.lddata(11 downto 10);
      v.fsr.aexc := cpi.lddata(9 downto 5);
      v.fsr.cexc := cpi.lddata(4 downto 0);
    end if;

    -- write result from commited fpop
    if (r.fpq.act and r.fpq.com and not FpBusy) = '1' then
      if Excep(5) = '1' then -- dont update aexc/cexc on unimp fpop
        v.fsr.ftt := FPUNIMP_ERR;  -- unimp fpop
        v.fpq.act := '0'; v.fpq.com := '0';
      elsif (r.fsr.tem and Excep(4 downto 0)) /= "00000" then
        v.fpq.act := '0'; v.fpq.com := '0';
        v.fsr.cexc := r.fsr.tem and Excep(4 downto 0);
        v.fsr.ftt := FPIEEE_ERR;  -- ieee-754 exception
      else
        v.fsr.aexc := Excep(4 downto 0);
        v.fsr.cexc := r.fsr.aexc or Excep(4 downto 0);
        v.fsr.ftt := "000";
      end if;
      if v.fsr.ftt /= "000" then
        v.state := expend; v.fsr.qne := '1';
      end if;
      if r.fpq.fccv = '0' then
        v.fpq.fccv := '1';
        v.fpq.act := '0'; v.fpq.com := '0';
        if v.fsr.ftt = "000" then
          v.fsr.fcc := ConditionCodes;
        end if;
        disins := '1';
      elsif ((wren1 or wren2) = '0') and (v.fsr.ftt = "000") then
        rfwdata := fpures;
        rfwa := r.fpq.inst(29 downto 25);
        v.fpq.act := '0'; v.fpq.com := '0';
        v.fsr.aexc := Excep(4 downto 0);
        v.fsr.cexc := r.fsr.aexc or Excep(4 downto 0);
        if SNnotDB = '1' then
          wren1 := not r.fpq.inst(25); wren2 := r.fpq.inst(25);
        else
          wren1 := '1'; wren2 := '1';
        end if;
      end if;
    end if;

  -- memory stage --

    if holdn = '1' then
      v.xres := r.mres; v.xmov := r.mmov;
    end if;

  -- execute stage --

    if holdn = '1' then
      v.mmov := r.emov;
      v.mres := r.eres; -- execute fmov/fneg/fabs locally
      v.mres(31) := (r.eres(31) xor cpi.e.inst(7)) and not cpi.e.inst(8);
    end if;

  -- reg access stage --

    -- generate store data
    if (cpi.a.inst(25) = '1') or (cpi.a.cnt(1 downto 0) = "10") then
      stfdata := rfo2.data2;
    else
      stfdata := rfo1.data2;
    end if;
    if (cpi.a.inst(31 downto 30) = LDST) then
      if (cpi.a.inst(24 downto 19) = STFSR) then
        stfdata := r.fsr.rd & "00" & r.fsr.tem & "000" & FPCVER & r.fsr.ftt &
          r.fsr.qne & "0" & r.fsr.fcc & r.fsr.aexc & r.fsr.cexc;
      elsif (cpi.a.inst(24 downto 19) = STDFQ) then
        if (cpi.a.cnt(1 downto 0) = "10") then
          stfdata := r.fpq.inst;
        else
          stfdata := r.fpq.pc;
        end if;
      else  -- data forward from fmov to store
        if ((not cpi.m.annul and r.mmov) = '1') and
          (((cpi.m.inst(29 downto 25) =  cpi.a.inst(29 downto 25)) and (cpi.a.cnt = "01")) or
           ((cpi.m.inst(29 downto 25) =  cpi.a.inst(29 downto 26) & '1') and (cpi.a.cnt = "10")))
        then
          stfdata := r.mres;
        elsif ((not cpi.x.annul and r.xmov) = '1') and
          (((cpi.x.inst(29 downto 25) =  cpi.a.inst(29 downto 25)) and (cpi.a.cnt = "01")) or
           ((cpi.x.inst(29 downto 25) =  cpi.a.inst(29 downto 26) & '1') and (cpi.a.cnt = "10")))
        then
          stfdata := r.xres;
        end if;
      end if;
    end if;

    rfdata1 := rfo1.data1 & rfo2.data1;
    rfdata2 := rfo1.data2 & rfo2.data2;

    -- data forwarding from fmov to fpop operand
    if ((not cpi.x.annul and r.xmov) = '1') then -- data forward from exception stage
      if (cpi.x.inst(29 downto 26) = cpi.a.inst(18 downto 15)) then
        if cpi.x.inst(25) = '1' then
          rfdata1(31 downto 0) := r.xres;
        else
          rfdata1(63 downto 32) := r.xres;
        end if;
      end if;
      if (cpi.x.inst(29 downto 26) = cpi.a.inst(4 downto 1)) then
        if cpi.x.inst(25) = '1' then
          rfdata2(31 downto 0) := r.xres;
        else
          rfdata2(63 downto 32) := r.xres;
        end if;
      end if;
    end if;
    if ((not cpi.m.annul and r.mmov) = '1') then -- data forward from mem stage
      if (cpi.m.inst(29 downto 26) = cpi.a.inst(18 downto 15)) then
        if cpi.m.inst(25) = '1' then
          rfdata1(31 downto 0) := r.mres;
        else
          rfdata1(63 downto 32) := r.mres;
        end if;
      end if;
      if (cpi.m.inst(29 downto 26) = cpi.a.inst(4 downto 1)) then
        if cpi.m.inst(25) = '1' then
          rfdata2(31 downto 0) := r.mres;
        else
          rfdata2(63 downto 32) := r.mres;
        end if;
      end if;
    end if;
    if ((not cpi.e.annul and r.emov) = '1') then -- data forward from exe stage
      if (cpi.e.inst(29 downto 26) = cpi.a.inst(18 downto 15)) then
        if cpi.e.inst(25) = '1' then
          rfdata1(31 downto 0) := v.mres;
        else
          rfdata1(63 downto 32) := v.mres;
        end if;
      end if;
      if (cpi.e.inst(29 downto 26) = cpi.a.inst(4 downto 1)) then
        if cpi.e.inst(25) = '1' then
          rfdata2(31 downto 0) := v.mres;
        else
          rfdata2(63 downto 32) := v.mres;
        end if;
      end if;
    end if;

    -- align single-precision operands
    if cpi.a.inst(20) = '0' then
      if cpi.a.inst(14) = '1' then
        rfdata1 := rfdata1(31 downto 0) & rfdata1(31 downto 0);
      end if;
      if cpi.a.inst(0) = '1' then
        rfdata2 := rfdata2(31 downto 0) & rfdata2(31 downto 0);
      end if;
    end if;

    if holdn = '1' then
      v.emov := r.amov;
      if v.emov = '1' then
        v.eres := rfdata2(63 downto 32);
      else
        v.eres := stfdata;
      end if;
    end if;

    -- decode stage --

    if holdn = '1' then
      dinst := cpi.d.inst;
    else
      dinst := cpi.a.inst;
    end if;

    -- launch fpops
    if (cpi.d.annul or cpi.d.trap or not holdn) = '0' then
      v.amov := '0';
      if (cpi.d.inst(31 downto 30) = FMT3) then
        if ((cpi.d.inst(24 downto 19) = FPOP1) and (cpi.d.inst(13 downto 9) = "00000")) then
          v.amov := '1'; -- fmov/fneg/fabs does not enter fpu
        end if;
        if (cpi.d.inst(24 downto 20) = FPOP1(5 downto 1)) then
          if v.fsr.qne = '1' then
            --v.state := expend;
          elsif (isldf(cpi.a.inst) and (cpi.d.inst(18 downto 15) = cpi.a.inst(29 downto 26))) or
                (isldf(cpi.e.inst) and (cpi.d.inst(18 downto 15) = cpi.e.inst(29 downto 26))) or
                (isldf(cpi.m.inst) and (cpi.d.inst(18 downto 15) = cpi.m.inst(29 downto 26))) or
                (isldf(cpi.a.inst) and (cpi.d.inst( 4 downto  1) = cpi.a.inst(29 downto 26))) or
                (isldf(cpi.e.inst) and (cpi.d.inst( 4 downto  1) = cpi.e.inst(29 downto 26))) or
                (isldf(cpi.m.inst) and (cpi.d.inst( 4 downto  1) = cpi.m.inst(29 downto 26)))
          then
            ldlock := '1';
          elsif ((v.fpq.act and not v.amov)) = '1' or -- can be replaced with r.fpq.act to improve timing
             (((v.fpq.act and v.amov) = '1') and (cpi.d.inst(4 downto 1) = r.fpq.inst(29 downto 26)))
          then
            ldlock := '1';
            -- send fmov with wrong opcode to fpu to trigger unimp fpop trap
          elsif (v.amov = '0') or ((v.amov = '1') and
            ((cpi.d.inst(6 downto 5) /= "01") or
            (cpi.d.inst(8 downto 7) = "11")))
          then
            -- start fpop
            fpopv := '1'; v.amov := '0';
            v.fpq.act := '1';
            v.fpq.inst := cpi.d.inst; v.fpq.pc := cpi.d.pc;
            v.fpq.fccv := not cpi.d.inst(19);
          end if;
        end if;
      elsif (cpi.d.inst(31 downto 30) = LDST) then
        if (cpi.d.inst(24 downto 19) = STFSR) or
           (cpi.d.inst(24 downto 19) = LDFSR) then
          ldlock := r.fpq.act;
          if (ldlock = '0') and (cpi.d.cnt = "00") then
            v.fpq.act := '1'; -- block fpops while executing lsfsr/stfsr
          end if;
        elsif (cpi.d.inst(24 downto 19) = LDDF) or
              (cpi.d.inst(24 downto 19) = LDF) then
          if (r.fpq.act = '1') and
            ((((cpi.d.inst(29 downto 26) = r.fpq.inst(4 downto 1)) or
             (cpi.d.inst(29 downto 26) = r.fpq.inst(18 downto 15))) and
            (r.fsr.tem /= "00000")) or -- only check source reg if exceptions are enabled
             (cpi.d.inst(29 downto 26) = r.fpq.inst(29 downto 26)))
          then
            ldlock := '1'; -- load to same reg as ongoing fpop src/dest
          end if;
        elsif (cpi.d.inst(24 downto 19) = STDF) or
              (cpi.d.inst(24 downto 19) = STF) then
          if (r.fpq.act = '1') and
             (cpi.d.inst(29 downto 26) = r.fpq.inst(29 downto 26))
          then
            ldlock := '1'; -- store of same reg as ongoing fpop dest
          end if;
          if (isldf(cpi.a.inst) and (cpi.d.inst(29 downto 26) = cpi.a.inst(29 downto 26))) or
             (isldf(cpi.e.inst) and (cpi.d.inst(29 downto 26) = cpi.e.inst(29 downto 26))) or
             (isldf(cpi.m.inst) and (cpi.d.inst(29 downto 26) = cpi.m.inst(29 downto 26)))
          then
            ldlock := '1'; -- store of same reg as ongoing ld dest
          end if;
        end if;
      end if;
    end if;

    -- generate RF read addresses
    rfa1 := dinst(18 downto 14); rfa2 := dinst(4 downto 0);
    if (dinst(31 downto 30) = LDST) and (dinst(24 downto 21) = STF(5 downto 2))
    then
      rfa2 := dinst(29 downto 25); --STF/STDF/STFSR
    end if;

    v.fpop := fpopv;

    -- leon3 dsu access

    dsudata := r.fsr.rd & "00" & r.fsr.tem & "000" & FPCVER & r.fsr.ftt &
          r.fsr.qne & "0" & r.fsr.fcc & r.fsr.aexc & r.fsr.cexc;
    if (dsu /= 0) and (cpi.dbg.enable = '1') then
      rfa2 := cpi.dbg.addr; rfwa := cpi.dbg.addr;
      rfwdata := cpi.dbg.data & cpi.dbg.data;
      if cpi.dbg.fsr = '1' then
        if cpi.dbg.write = '1' then
          v.fsr.rd   := cpi.lddata(31 downto 30);
          v.fsr.tem  := cpi.lddata(27 downto 23);
          v.fsr.fcc  := cpi.lddata(11 downto 10);
          v.fsr.aexc := cpi.lddata(9 downto 5);
          v.fsr.cexc := cpi.lddata(4 downto 0);
          if cpi.dbg.data(28) = '1' then -- grmon uses this for reset
            v.state := nominal; v.fsr.qne := '0'; v.fsr.tem := "00000";
          end if;
        end if;
      else
        if cpi.dbg.addr(0) = '1' then dsudata := rfo2.data2;
        else dsudata := rfo1.data2; end if;
        if cpi.dbg.write = '1' then
          wren1 := not cpi.dbg.addr(0);
          wren2 := cpi.dbg.addr(0);
        end if;
      end if;
    end if;

    if rst = '0' then
      v.fpq.act := '0'; v.fpq.com := '0'; v.fpq.fccv := '1';
      v.fsr.qne := '0'; v.fsr.ftt := "000"; fpurst := '1';
      v.state := nominal; v.fsr.tem := "00000"; v.amov := '0';
    end if;

    rin <= v;

    Reset <= fpurst;
    RoundingMode <= r.fsr.rd;
    FpLd <= r.fpop;
    FpOp <= fpopv;
    FpInst <= dinst(19) & dinst(13 downto 5);
    rfi1.rd1addr <= rfa1(4 downto 1);
    rfi1.rd2addr <= rfa2(4 downto 1);
    rfi2.rd1addr <= rfa1(4 downto 1);
    rfi2.rd2addr <= rfa2(4 downto 1);
    rfi1.ren1 <= '1'; rfi1.ren2 <= '1';
    rfi2.ren1 <= '1'; rfi2.ren2 <= '1';
    rfi1.wren <= wren1; rfi2.wren <= wren2;
    rfi1.wraddr <= rfwa(4 downto 1);
    rfi2.wraddr <= rfwa(4 downto 1);
    rfi1.wrdata <= rfwdata(63 downto 32);
    rfi2.wrdata <= rfwdata(31 downto 0);
    cpo.data <= r.eres;
    cpo.cc <= r.fsr.fcc;
    cpo.ccv <= r.fpq.fccv;
    cpo.ldlock <= ldlock;
    cpo.holdn <= '1';
    cpo.dbg.data <= dsudata;
    fprf_dout1 <= rfdata1;
    fprf_dout2 <= rfdata2;
    disfsr <= loadfsr or disins;
  end process;

  cpo.exc <= '1' when r.state = expend else '0';

  regs : process(clk)
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;

  irisfpu0 : irisfpu
    generic map (0, 0, 3, 0, 1)
    port map (clk, FpInst, FpOp, FpLd, Reset,
      fprf_dout1, fprf_dout2, RoundingMode, FpBusy, FracResult,
      ExpResult, SignResult, SNnotDB, Excep, ConditionCodes);

  regfile1 : regfile_3p_l3 generic map (tech, 4, 32, 1, 16, scantest)
    port map (clk, rfi1.wraddr, rfi1.wrdata, rfi1.wren, clk, rfi1.rd1addr,
      rfi1.ren1, rfo1.data1, rfi1.rd2addr, rfi1.ren2, rfo1.data2, testin);

  regfile2 : regfile_3p_l3 generic map (tech, 4, 32, 1, 16, scantest)
    port map (clk, rfi2.wraddr, rfi2.wrdata, rfi2.wren, clk, rfi2.rd1addr,
      rfi2.ren1, rfo2.data1, rfi2.rd2addr, rfi2.ren2, rfo2.data2, testin);

-- pragma translate_off
  disasfp : process(clk)
  variable ldata : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if (rfi1.wren or rfi2.wren or disfsr) = '1' then
        if (r.fpq.com and not rin.fpq.com) = '1' then
          print_fpinsn(index, r.fpq.pc, r.fpq.inst, rfi1.wrdata & rfi2.wrdata,
            ((rfi1.wren and rfi2.wren) = '1'), (disas /= 0),
                        false, ((rfi1.wren or rfi2.wren) = '1'));
        else
          if (cpi.x.inst(31 downto 30) = LDST) and (cpi.x.inst(24 downto 19) = LDDF) then
            if (cpi.x.cnt = "00") then
              ldata := rfi1.wrdata; -- save first load data during LDDF
            else
              print_fpinsn(index, cpi.x.pc, cpi.x.inst, ldata & rfi2.wrdata,
              true, (disas /= 0), false, true);
            end if;
          else
            print_fpinsn(index, cpi.x.pc, cpi.x.inst, rfi1.wrdata & rfi2.wrdata,
              ((rfi1.wren and rfi2.wren) = '1'), ((rfi1.wren or rfi2.wren or disfsr) = '1')
              and (disas /= 0), false, ((rfi1.wren or rfi2.wren or disfsr) = '1'));
         end if;
        end if;
      end if;
    end if;
  end process;
-- pragma translate_on
end;

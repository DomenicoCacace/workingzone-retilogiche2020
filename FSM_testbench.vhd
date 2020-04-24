--------------------------------------------------------------------------------
--                        Prova Finale di Reti Logiche                        --
--                           FSM_testbench.vhd                                --
-- Anno Accademico 2019/2020                                                  --
-- Prof. William Fornaciari                                                   --
--                                                                            --
-- Studente: Domenico Cacace                                                  --
-- Codice Persona: [REDACTED]                                                 --
-- Matricola: [REDACTED]                                                      --
--------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.std_logic_textio.ALL;
use STD.textio.ALL;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
constant CLK_PERIOD		: time := 100 ns;
signal   tb_done		  : std_logic;
signal   mem_address	: std_logic_vector (15 downto 0) := (others => '0');
signal   tb_rst	      : std_logic := '0';
signal   tb_start		  : std_logic := '0';
signal   tb_clk		    : std_logic := '0';
signal   mem_o_data 	: std_logic_vector (7 downto 0);
signal   mem_i_data 	: std_logic_vector (7 downto 0);
signal   enable_wire  : std_logic;
signal   mem_we		    : std_logic;

type ramType is array (65535 downto 0) of std_logic_vector(7 downto 0);

signal RAM               : ramType;
signal endOfTests        : boolean := false;
signal loadMemoryRequest : boolean := false;

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;


begin
UUT: project_reti_logiche
port map (
          i_clk       => tb_clk,
          i_start     => tb_start,
          i_rst       => tb_rst,
          i_data      => mem_o_data,
          o_address   => mem_address,
          o_done      => tb_done,
          o_en   	  => enable_wire,
          o_we 		  => mem_we,
          o_data      => mem_i_data
          );

CLK_GEN : process is
begin
    wait for CLK_PERIOD/2;
    tb_clk <= not tb_clk;
end process CLK_GEN;

MEM : process(tb_clk)
    file allTestStates  : text open read_mode is "D:\RAM.txt";
    variable ramContent : line;
    variable char       : character;
    variable nextValue  : String (1 to 3);
begin

    if (tb_clk'event and tb_clk = '1') then
        ---RAM FILE PARSER---
        if (loadMemoryRequest) then
            readline(allTestStates, ramContent);

            while (char /= '[') loop        --dumping test intestation{testNum.testModule) wz: [}
                read(ramContent, char);
            end loop;

            for wzIndex in 0 to 7 loop  --reading the Working Zone base addresses
                nextValue := "0  ";     --resetting the variable to "null"
                for i in 1 to 4 loop
                    read(ramContent, char);
                    exit when char = ',';
                    exit when char = ']';
                    nextValue(i) := char;

                end loop;
                read(ramContent, char); --dumping white space after the comma
                RAM(wzIndex) <= std_logic_vector(to_unsigned(integer'value(nextValue), 8));
            end loop;

            while (char /= ':') loop        --dumping test intestation {addr: }
                read(ramContent, char);
            end loop;
            read(ramContent, char);
            nextValue := "0  ";     --resetting the variable to "null"
            for i in 1 to 4 loop    --reading the address to encode
                read(ramContent, char);
                exit when char = ';';
                nextValue(i) := char;
            end loop;
            RAM(8) <= std_logic_vector(to_unsigned(integer'value(nextValue), 8));

            while (char /= ':') loop        --dumping test intestation {output: }
                read(ramContent, char);
            end loop;
            read(ramContent, char);
            nextValue := "0  ";     --resetting the variable to "null"
            for i in 1 to 3 loop    --reading the expected output
                read(ramContent, char);
                nextValue(i) := char;
                exit when ramContent'length = 0;
            end loop;
            RAM(10) <= std_logic_vector(to_unsigned(integer'value(nextValue), 8));

            if endfile(allTestStates) then
                endOfTests <= true;
                file_close(allTestStates);
            end if;
        ---END RAM FILE PARSER---

        ---MEMORY READ/WRITE OPERATIONS---
        elsif enable_wire = '1' then
            if mem_we = '1' then
                RAM(conv_integer(mem_address)) <= mem_i_data;
                mem_o_data <= mem_i_data after 1 ns;
            else
                mem_o_data <= RAM(conv_integer(mem_address)) after 1 ns;
            end if;
        end if;
        ---END MEMORY READ/WRITE OPERATIONS---
    end if;
end process MEM;

TESTING : process is
  file outcomeFile     : text open write_mode is "D:\passati.txt";
  variable outcome     : line;
  variable testNumber  : integer := 0;
  variable timer       : time;
  variable totalTime   : time;
  variable rstClkNum   : integer;
  variable randVal     : real;
  variable seed1       : positive := 1;
  variable seed2       : positive := 1;
begin
wait for 100 ns;
    totalTime := now;
    loop

    testNumber := testNumber + 1;
    exit when endOfTests;

    ---FIRST MODULE: ADDRESS IN A WORKING ZONE, FIRST START SIGNAL---
    loadMemoryRequest <= true; -- richiesta di modifica valori ram
    wait for CLK_PERIOD;
    loadMemoryRequest <= false;
    wait for CLK_PERIOD;
    tb_rst <= '1';
    wait for CLK_PERIOD;
    tb_rst <= '0';
    wait for CLK_PERIOD;
    tb_start <= '1';
    timer := now;
    wait for CLK_PERIOD;
    wait until tb_done = '1';
    timer := now - timer;
    wait for CLK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for CLK_PERIOD;
    if(RAM(9) = RAM(10)) then
        write(outcome, integer'image(testNumber) & ".1) PASSED (" & time'image(timer) & "; no reset);");
    else
        write(outcome, integer'image(testNumber) & ".1) FAILED (" & time'image(timer) & "; no reset): EXPECTED " & integer'image(to_integer(unsigned(RAM(10)))) & ", FOUND "& integer'image(to_integer(unsigned(RAM(9)))));
    end if;
    writeline(outcomeFile, outcome);


    ---SECOND MODULE: ADDRESS IN A WORKING ZONE, SECOND START SIGNAL---
    wait for CLK_PERIOD;
    if (endOfTests) then exit; end if;
    loadMemoryRequest <= true; -- richiesta di modifica valori ram
    wait for CLK_PERIOD;
    loadMemoryRequest <= false;
    wait for CLK_PERIOD;
    tb_start <= '1';
    wait for CLK_PERIOD;
    wait until tb_done = '1';
    wait for CLK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for CLK_PERIOD;
    if(RAM(9) = RAM(10)) then
        write(outcome, integer'image(testNumber) & ".2) PASSED (" & time'image(timer) & "; no reset);");
    else
        write(outcome, integer'image(testNumber) & ".2) FAILED (" & time'image(timer) & "; no reset): EXPECTED " & integer'image(to_integer(unsigned(RAM(10)))) & ", FOUND "& integer'image(to_integer(unsigned(RAM(9)))));
    end if;
    writeline(outcomeFile, outcome);

    ---THIRD MODULE: ADDRESS IN A WORKING ZONE, ASYNCHRONOUS RESET---
    if (endOfTests) then exit; end if;
    loadMemoryRequest <= true; -- richiesta di modifica valori ram
    wait for CLK_PERIOD;
    loadMemoryRequest <= false;
    wait for CLK_PERIOD;
    tb_rst <= '1';
    wait for CLK_PERIOD;
    tb_rst <= '0';
    wait for CLK_PERIOD;
    tb_start <= '1';

    for n in 1 to 10 loop
        uniform(seed1, seed2, randVal);
        rstClkNum := integer(floor(randVal*real(10-4+1) + real(4)));
    end loop;

    wait for CLK_PERIOD*rstClkNum;
    tb_rst <= '1';
    wait for CLK_PERIOD;
    tb_rst <= '0';
    wait for CLK_PERIOD;
    wait until tb_done = '1';
    wait for CLK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for CLK_PERIOD;

    if(RAM(9) = RAM(10)) then
        write(outcome, integer'image(testNumber) & ".3) PASSED (" & time'image(timer) & "; " & integer'image(rstClkNum) & " CLKs);");
    else
        write(outcome, integer'image(testNumber) & ".3) FAILED (" & time'image(timer) & "; " & integer'image(rstClkNum) & " CLKs); EXPECTED " & integer'image(to_integer(unsigned(RAM(10)))) & ", FOUND " & integer'image(to_integer(unsigned(RAM(9)))) & ";");
    end if;
    writeline(outcomeFile, outcome);

    ---FOURTH MODULE: ADDRESS IN NO WORKING ZONE, FIRST START SIGNAL---
    loadMemoryRequest <= true; -- richiesta di modifica valori ram
    wait for CLK_PERIOD;
    loadMemoryRequest <= false;
    wait for CLK_PERIOD;
    tb_rst <= '1';
    wait for CLK_PERIOD;
    tb_rst <= '0';
    wait for CLK_PERIOD;
    tb_start <= '1';
    timer := now;
    wait for CLK_PERIOD;
    wait until tb_done = '1';
    timer := now - timer;
    wait for CLK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for CLK_PERIOD;
    if(RAM(9) = RAM(10)) then
        write(outcome, integer'image(testNumber) & ".4) PASSED (" & time'image(timer) & "; no reset);");
    else
        write(outcome, integer'image(testNumber) & ".4) FAILED (" & time'image(timer) & "; no reset): EXPECTED " & integer'image(to_integer(unsigned(RAM(10)))) & ", FOUND "& integer'image(to_integer(unsigned(RAM(9)))));
    end if;
    writeline(outcomeFile, outcome);


    ---FIFTH MODULE: ADDRESS NO A WORKING ZONE, SECOND START SIGNAL---
    wait for CLK_PERIOD;
    if (endOfTests) then exit; end if;
    loadMemoryRequest <= true; -- richiesta di modifica valori ram
    wait for CLK_PERIOD;
    loadMemoryRequest <= false;
    wait for CLK_PERIOD;
    tb_start <= '1';
    wait for CLK_PERIOD;
    wait until tb_done = '1';
    wait for CLK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for CLK_PERIOD;
    if(RAM(9) = RAM(10)) then
        write(outcome, integer'image(testNumber) & ".5) PASSED (" & time'image(timer) & "; no reset);");
    else
        write(outcome, integer'image(testNumber) & ".5) FAILED (" & time'image(timer) & "; no reset): EXPECTED " & integer'image(to_integer(unsigned(RAM(10)))) & ", FOUND "& integer'image(to_integer(unsigned(RAM(9)))));
    end if;
    writeline(outcomeFile, outcome);

    ---SIXTH MODULE: ADDRESS NO A WORKING ZONE, ASYNCHRONOUS RESET---
    if (endOfTests) then exit; end if;
    loadMemoryRequest <= true; -- richiesta di modifica valori ram
    wait for CLK_PERIOD;
    loadMemoryRequest <= false;
    wait for CLK_PERIOD;
    tb_rst <= '1';
    wait for CLK_PERIOD;
    tb_rst <= '0';
    wait for CLK_PERIOD;
    tb_start <= '1';

    for n in 1 to 10 loop
        uniform(seed1, seed2, randVal);
        rstClkNum := integer(floor(randVal*real(10-4+1) + real(4)));
    end loop;

    wait for CLK_PERIOD*rstClkNum;
    tb_rst <= '1';
    wait for CLK_PERIOD;
    tb_rst <= '0';
    wait for CLK_PERIOD;
    wait until tb_done = '1';
    wait for CLK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for CLK_PERIOD;

    if(RAM(9) = RAM(10)) then
        write(outcome, integer'image(testNumber) & ".6) PASSED (" & time'image(timer) & "; " & integer'image(rstClkNum) & " CLKs);");
    else
        write(outcome, integer'image(testNumber) & ".6) FAILED (" & time'image(timer) & "; " & integer'image(rstClkNum) & " CLKs); EXPECTED " & integer'image(to_integer(unsigned(RAM(10)))) & ", FOUND " & integer'image(to_integer(unsigned(RAM(9)))) & ";");
    end if;
    writeline(outcomeFile, outcome);
    ---------- fine casi di test ----------
    end loop;
    write(outcome, "TOTAL TIME: " & time'image(now - totalTime));
    writeline(outcomeFile, outcome);
    file_close(outcomeFile);
    std.env.finish;
end process TESTING;

end projecttb;

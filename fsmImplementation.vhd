----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    Port (
           i_clk      : in  STD_LOGIC;      --input clock from benchtest
           i_start    : in  STD_LOGIC;      --start signal from benchtest
           i_rst      : in  STD_LOGIC;      --reset test, brings the FSM to the STANDBY state
           i_data     : in  STD_LOGIC_VECTOR (7 downto 0);      --data fetched from memory after a request
           o_address  : out STD_LOGIC_VECTOR (15 downto 0);      --memory address to read from/write to
           o_done     : out STD_LOGIC;      --signals the end of the operation
           o_en       : out STD_LOGIC;      --has to be set to 1 to access the memory
           o_we       : out STD_LOGIC;      --has to be set to 1 to write to memory, 0 to read
           o_data     : out STD_LOGIC_VECTOR (7 downto 0)     --data to write to memory
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    ---FSM states---
    type StateType is (STANDBY, ADDR_FETCH, WZ_FETCH, ADDR_LOAD, WZ_LOAD, MEM_WAIT, WZ_CHECK, ADDR_WRITE, DONE);      --FSM states
    signal currentState, nextState : StateType := STANDBY;     --current and next state of the FSM

    ---i/o signals---
    signal nextMemEnable, nextMemWriteEnable, nextOperationDone : std_logic := '0';   --memory enable signals and end of operation flag
    signal nextMemAddress : std_logic_vector (15 downto 0) := "0000000000000000";     --memory address to fetch/write
    signal nextDataToMemory : std_logic_vector (7 downto 0) := "00000000";    --data to be written on memory

    ---Working Zone address and data---
    signal workingZoneAddress, nextWorkingZoneAddress : std_logic_vector (15 downto 0) := "0000000000000000";      --address of the next working zone to fetch
    signal workingZoneData, nextWorkingZoneData : std_logic_vector (7 downto 0) := "00000000";     --content of the cell fetched during WZ_FETCH

    ---Address to encode---
    signal addressToEncode, nextAddressToEncode : std_logic_vector (7 downto 0) := "00000000";    --the address to be encoded, stored in cell 0000000000001001
    signal addressLoaded, nextAddressLoaded: boolean := false; --signals if the address to analyze has been fetched

    ---Output---
    signal encodedAddress, nextEncodedAddress : std_logic_vector (7 downto 0) := "00000000";   --the address calculated following the specifications


    begin

    process (i_clk, i_rst)
    begin
        if (i_rst = '1') then   --asynchronous reset, set all signals to default
          currentState <= STANDBY;

          o_done    <= '0';
          o_en      <= '0';
          o_we      <= '0';
          o_data    <= "00000000";
          o_address <= "0000000000000000";

          workingZoneAddress  <= "0000000000000000";
          workingZoneData     <= "00000000";
          addressToEncode     <= "00000000";
          addressLoaded       <= false;
          encodedAddress      <= "00000000";

        elsif (i_clk'event and i_clk = '1') then --refresh signals, assigning new values
          currentState <= nextState;

          o_done    <= nextOperationDone;
          o_en      <= nextMemEnable;
          o_we      <= nextMemWriteEnable;
          o_data    <= nextDataToMemory;
          o_address <= nextMemAddress;

          workingZoneAddress  <= nextWorkingZoneAddress;
          workingZoneData     <= nextWorkingZoneData;
          addressToEncode     <= nextAddressToEncode;
          addressLoaded       <= nextAddressLoaded;
          encodedAddress      <= nextEncodedAddress;

        end if;
    end process;



    process(currentState, i_start, i_data, workingZoneAddress, addressLoaded, addressToEncode,
            encodedAddress, workingZoneData)
    begin
        ---SETUP SIGNALS---
        nextState <= STANDBY;

        nextOperationDone   <= '0';
        nextMemEnable       <= '0';
        nextMemWriteEnable  <= '0';
        nextDataToMemory    <= "00000000";
        nextMemAddress      <= "0000000000000000";

        nextWorkingZoneData     <= workingZoneData;
        nextWorkingZoneAddress  <= workingZoneAddress;
        nextAddressToEncode     <= addressToEncode;
        nextAddressLoaded       <= addressLoaded;
        nextEncodedAddress      <= encodedAddress;
        ---END SETUP SIGNALS---

        ---STATES MANAGEMENT---
        case currentState is

            when STANDBY =>
                if (i_start = '1') then
                    nextState <= ADDR_FETCH;
                end if;
            ---END STANDBY---

            when ADDR_FETCH =>
                nextMemEnable <= '1';
                nextMemWriteEnable <= '0';  --setting flags to read from memory
                nextMemAddress <= "0000000000001000";   --the address to analyze is in the 9th memory cell

                nextState <= MEM_WAIT;
            ---END ADDR_FETCH---

            when WZ_FETCH =>
                nextMemEnable <= '1';
                nextMemWriteEnable <= '0';  --setting flags to read from memory
                nextMemAddress <= workingZoneAddress;    --address of the WZ to fetch, set in WZ_CHECK

                nextState <= MEM_WAIT;
            ---END WZ_FETCH---

            when MEM_WAIT =>
                if (not addressLoaded) then   --first time
                    nextAddressLoaded <= true;
                    nextState <= ADDR_LOAD;
                else
                    nextState <= WZ_LOAD;
                end if;
                nextMemEnable <= '0';
            ---END MEM_WAIT---

            when ADDR_LOAD =>
                nextAddressToEncode <= i_data;  --load the address to analyze
                nextAddressLoaded <= true;
                nextState <=  WZ_FETCH;

            when WZ_LOAD =>
                nextWorkingZoneData <= i_data;  --load the working zone to analyze
                nextState <= WZ_CHECK;



            when WZ_CHECK =>

                if (to_integer(unsigned(workingZoneAddress)) < 8) then  --true when there are non-analyzed working zones

                    if ((to_integer(unsigned(addressToEncode)) - to_integer(unsigned(workingZoneData)) < 4) and
                        (to_integer(unsigned(addressToEncode)) - to_integer(unsigned(workingZoneData)) > -1))then   --the difference is at most 3 and positive

                        nextEncodedAddress(7) <= '1';   --WZ_BIT set to 1
                        nextEncodedAddress(6 downto 4) <= workingZoneAddress(2 downto 0);   --number of the Working Zone

                        case (to_integer(unsigned(addressToEncode(1 downto 0) - workingZoneData(1 downto 0)))) is    --Calculate the offset in One-hot encoding
                            when 0 =>
                                nextEncodedAddress(3 downto 0) <= "0001";
                            when 1 =>
                                nextEncodedAddress(3 downto 0) <= "0010";
                            when 2 =>
                                nextEncodedAddress(3 downto 0) <= "0100";
                            when 3 =>
                                nextEncodedAddress(3 downto 0) <= "1000";
                            when others =>
                                --never gets here
                                nextEncodedAddress <= addressToEncode;
                        end case;
                        nextState <= ADDR_WRITE;    --break the cycle and write the result on memory

                    else    --check the next working zone
                        nextWorkingZoneAddress <= workingZoneAddress + "0000000000000001";
                        nextState <= WZ_FETCH;
                    end if;

                else    --checked all working zones, no correspondence found
                    nextEncodedAddress <= addressToEncode;
                    nextState <= ADDR_WRITE;
                end if;
            ---END WZ_CHECK---

            when ADDR_WRITE =>
                nextMemAddress      <= "0000000000001001";    --set the destination for the result the 10th cell
                nextMemEnable       <= '1';
                nextMemWriteEnable  <= '1';
                nextDataToMemory    <= encodedAddress;   --the address calculated in the previous state
                nextOperationDone   <= '1';

                nextState           <= DONE;
            ---END ADDR_WRITE---

            when DONE =>
                nextOperationDone       <= '0';       --reset all signals
                nextMemEnable           <= '0';
                nextMemWriteEnable      <= '0';
                nextDataToMemory        <= "00000000";
                nextMemAddress          <= "0000000000000000";
                nextWorkingZoneData     <= "00000000";
                nextWorkingZoneAddress  <= "0000000000000000";
                nextAddressToEncode     <= "00000000";
                nextAddressLoaded       <= false;
                nextEncodedAddress      <= "00000000";

                if (i_start = '0') then
                    nextState <= STANDBY;
                end if;
            ---END DONE---
        end case;
    end process;
end Behavioral;

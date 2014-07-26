--  Register Interface Test Bench
--
--  Description: Test bench for register interface.
--
--  Notes: None.
--
--  Revision History:
--      Steven Okai     07/26/14    1) Initial revision.
--

library ieee;
use ieee.std_logic_1164.all;

entity RegisterInterfaceTB is

end  RegisterInterfaceTB;

architecture test of RegisterInterfaceTB is
    signal UARTClk      : std_logic := '0';
    signal Clk          : std_logic := '0';
    signal Reset        : std_logic := '1';

    signal RxIn         : std_logic := '1';
    signal TxOut        : std_logic;

    signal TxDataIn     : std_logic_vector(7 downto 0) := x"A0";
    signal TxFIFOPush   : std_logic := '0';
    signal TxFIFOFull   : std_logic;

    signal RxDataOut    : std_logic_vector(7 downto 0);
    signal RxFIFOPop    : std_logic;
    signal RxFIFOEmpty  : std_logic;
    
    begin
    
    UARTClk <= not UARTClk after 50 ns;
    Clk <= not Clk after 5 ns;
    
    process
        begin
        
        wait for 20 ns;
        Reset <= '0';
        wait;
        
    end process;
    
    process
        begin
        
        wait for 1000 us;
        
        wait until rising_edge(UARTClk);
        
        -- start
        RxIn <= '0';
        for i in 0 to 8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        -- 0 to 6
        RxIn <= '0';
        for i in 0 to 7*8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        -- seq (7)
        RxIn <= '0';
        for i in 0 to 8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        -- stop
        RxIn <= '1';
        for i in 0 to 2*8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        for i in 1 to 3 loop
            -- start
            RxIn <= '0';
            for i in 0 to 8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
            
            -- 0 to 6
            RxIn <= '0';
            for i in 0 to 7*8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
            
            -- seq (7)
            RxIn <= '1';
            for i in 0 to 8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
            
            -- stop
            RxIn <= '1';
            for i in 0 to 2*8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;

            -- start
            RxIn <= '0';
            for i in 0 to 8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
            
            -- 0 to 6
            RxIn <= '0';
            for i in 0 to 7*8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
            
            -- seq (7)
            RxIn <= '0';
            for i in 0 to 8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
            
            -- stop
            RxIn <= '1';
            for i in 0 to 2*8*65-1 loop
                wait until rising_edge(UARTClk);
            end loop;
        end loop;
        
        wait;
    end process;
    
    uart : entity work.RegisterInterface
        generic map (
            CLK_FREQ            => 10000000.0,  --: real := 25000000.0;
            BAUD_RATE           => 19200.0,     --: real := 9600.0;
            BAUD_ACCUM_WIDTH    => 16           --: positive := 16;
        )
        port map (
            UARTClk     => UARTClk,     --: in  std_logic;
            Clk         => Clk,         --: in  std_logic;
            Reset       => Reset,       --: in  std_logic;
            
            RxIn        => RxIn,        --: in  std_logic;
            TxOut       => TxOut        --: out std_logic
        );
        
end test;

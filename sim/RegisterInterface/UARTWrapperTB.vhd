--  UART Wrapper Test Bench
--
--  Description: Test bench for UART Wrapper.
--
--  Notes: None.
--
--  Revision History:
--      Steven Okai     07/26/14    1) Initial revision.
--


library ieee;
use ieee.std_logic_1164.all;

entity UARTWrapperTB is

end UARTWrapperTB;

architecture test of UARTWrapperTB is
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
        
        wait for 100 ns;
        
        wait until rising_edge(Clk);
        TxFIFOPush <= '1';
        TxDataIn <= x"A0";
        
        wait until rising_edge(Clk);
        TxFIFOPush <= '0';
        
        wait;
        
    end process;
    
    process
        begin
        
        wait for 1000 ns;
        
        wait until rising_edge(UARTClk);
        RxIn <= '0';
        for i in 0 to 8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        RxIn <= '1';
        for i in 0 to 8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        RxIn <= '0';
        for i in 0 to 8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        RxIn <= '1';
        for i in 0 to 8*65-1 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        RxIn <= '0';
        for i in 0 to 8*65-11 loop
            wait until rising_edge(UARTClk);
        end loop;
        
        RxIn <= '1';
        for i in 0 to 8*1007-1 loop
            wait until rising_edge(UARTClk);
        end loop;

    end process;
    
    process (Clk)
        begin
        if (rising_edge(Clk)) then
            if (RxFIFOEmpty = '0') then
                RxFIFOPop <= '1';
            else
                RxFIFOPop <= '0';
            end if;
        end if;
    end process;
    
    uart : entity work.UARTWrapper
        generic map (
            CLK_FREQ            => 10000000.0,  --: real := 25000000.0;
            BAUD_RATE           => 19200.0,     --: real := 9600.0;
            BAUD_ACCUM_WIDTH    => 16,          --: positive := 16;
            WIDE_MODE           => FALSE,       --: boolean := TRUE;
            NUM_STOP_BITS       => 1            --: positive := 1
        )
        port map (
            UARTClk     => UARTClk,     --: in  std_logic;
            Clk         => Clk,         --: in  std_logic;
            Reset       => Reset,       --: in  std_logic;
            
            RxIn        => RxIn,        --: in  std_logic;
            TxOut       => TxOut,       --: out std_logic;
            
            TxDataIn    => TxDataIn,  --: in  std_logic_vector(7 downto 0);
            TxFIFOPush  => TxFIFOPush,  --: in  std_logic;
            TxFIFOFull  => TxFIFOFull,  --: out std_logic;
            
            RxDataOut   => RxDataOut,  --: out std_logic_vector(7 downto 0);
            RxFIFOPop   => RxFIFOPop,   --: in  std_logic;
            RxFIFOEmpty => RxFIFOEmpty  --: out std_logic
        );
        
end test;

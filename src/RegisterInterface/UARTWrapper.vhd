--  UART Wrapper
--
--  Description: Wrapper for UART which includes FIFOs.
--
--  Notes:  None.
--
--  Revision History:
--      Steven Okai     07/26/14    1) Initial revision.
--

library ieee;
use ieee.std_logic_1164.all;

entity UARTWrapper is
    generic (
        CLK_FREQ            : real := 25000000.0;
        BAUD_RATE           : real := 9600.0;
        BAUD_ACCUM_WIDTH    : positive := 16;
        WIDE_MODE           : boolean := TRUE;
        NUM_STOP_BITS       : positive := 1
    );
    port (
        UARTClk     : in  std_logic;
        Clk         : in  std_logic;
        Reset       : in  std_logic;
        
        RxIn        : in  std_logic;
        TxOut       : out std_logic;
        
        TxDataIn    : in  std_logic_vector(7 downto 0);
        TxFIFOPush  : in  std_logic;
        TxFIFOFull  : out std_logic;
        
        RxDataOut   : out std_logic_vector(7 downto 0);
        RxFIFOPop   : in  std_logic;
        RxFIFOEmpty : out std_logic
    );
end UARTWrapper;

architecture rtl of UARTWrapper is

    signal RxFIFODataIn     : std_logic_vector(7 downto 0);
    signal RxFIFOErrorIn    : std_logic_vector(7 downto 0);
    signal RxFIFOPush       : std_logic;
    signal RxFIFOFull       : std_logic;
    
    signal TxFIFODataOut    : std_logic_vector(7 downto 0);
    signal TxFIFOEmpty      : std_logic;
    signal TxFIFOPop        : std_logic;
    
    begin
    
    uart : entity work.UART
        generic map (
            CLK_FREQ            => CLK_FREQ,            --: real := 25000000.0;
            BAUD_RATE           => BAUD_RATE,           --: real := 9600.0;
            BAUD_ACCUM_WIDTH    => BAUD_ACCUM_WIDTH,    --: positive := 16;
            WIDE_MODE           => WIDE_MODE,           --: boolean := TRUE;
            NUM_STOP_BITS       => NUM_STOP_BITS        --: positive := 1
        )
        port map (
            Clk         => UARTClk,         --: in  std_logic;
            Reset       => Reset,           --: in  std_logic;
            
            RxIn        => RxIn,            --: in  std_logic;
            TxOut       => TxOut,           --: out std_logic;
            
            RxDataOut       => RxFIFODataIn,        --: out std_logic_vector(7 downto 0);
            RxOverrunError  => RxFIFOErrorIn(3),    --: out std_logic; 
            RxFramingError  => RxFIFOErrorIn(2),    --: out std_logic; 
            RxBreak         => RxFIFOErrorIn(1),    --: out std_logic;
            RxParityError   => RxFIFOErrorIn(0),    --: out std_logic;
            RxFIFOPush      => RxFIFOPush,      --: out std_logic;
            
            TxDataIn    => TxFIFODataOut,   --: in  std_logic_vector(7 downto 0);
            TxFIFOEmpty => TxFIFOEmpty,     --: in  std_logic;
            TxFIFOPop   => TxFIFOPop        --: out std_logic
        );
        
    -- TODO: make an 8-bit version of this.
    tx_fifo : entity work.ByteAsyncFIFO
        port map (
            rst         => Reset,               --: in std_logic;
            wr_clk      => Clk,                 --: in std_logic;
            rd_clk      => UARTClk,             --: in std_logic;
            din         => TxDataIn,    --: in std_logic_vector(19 downto 0);
            wr_en       => TxFIFOPush,       --: in std_logic;
            rd_en       => TxFIFOPop,       --: in std_logic;
            dout        => TxFIFODataOut,   --: out std_logic_vector(19 downto 0);
            full        => TxFIFOFull,                --: out std_logic;
            overflow    => open,        --: out std_logic;
            empty       => TxFIFOEmpty     --: out std_logic
        );
        
    rx_fifo : entity work.ByteAsyncFIFO
        port map (
            rst         => Reset,               --: in std_logic;
            wr_clk      => UARTClk,                 --: in std_logic;
            rd_clk      => Clk,             --: in std_logic;
            din         => RxFIFODataIn,   --: in std_logic_vector(19 downto 0);
            wr_en       => RxFIFOPush,       --: in std_logic;
            rd_en       => RxFIFOPop,       --: in std_logic;
            dout        => RxDataOut,   --: out std_logic_vector(19 downto 0);
            full        => RxFIFOFull,                --: out std_logic;
            overflow    => open,        --: out std_logic;
            empty       => RxFIFOEmpty     --: out std_logic
        );
end rtl;
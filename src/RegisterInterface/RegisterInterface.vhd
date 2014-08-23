--  UART to Register Interface
--
--  Description: Interface from UART to internal registers.
--
--  Notes:  None.
--
--  Revision History:
--      Steven Okai     07/26/14    1) Initial revision.
--      Steven Okai     07/26/14    1) Added command bus.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.GeneralFuncPkg.all;
use work.CommandBusPkg.all;

entity RegisterInterface is
    generic (
        CLK_FREQ            : real := 25000000.0;
        BAUD_RATE           : real := 9600.0;
        BAUD_ACCUM_WIDTH    : positive := 16;
        ADDRESS_DECODE      : slv_64_vector
    );
    port (
        UARTClk         : in  std_logic;
        Clk             : in  std_logic;
        Reset           : in  std_logic;
        
        RxIn            : in  std_logic;
        TxOut           : out std_logic;
        
        CmdIn           : out cmd_bus_in_vector;
        CmdOut          : in  cmd_bus_out_vector
    );

end RegisterInterface;

architecture rtl of RegisterInterface is

    --constant DEPTH                  : positive := 7;
    
    type fsm_state is (IDLE, GET_COMMAND_BYTE, WAIT_FOR_NEXT_BYTE, COMMAND_EXECUTE, LATCH_RESPONSE, QUEUE_RESPONSE);
    
    constant ERROR_PARITY           : natural := 0;
    constant ERROR_BREAK            : natural := 1;
    constant ERROR_FRAMING          : natural := 2;
    constant ERROR_OVERRUN          : natural := 3;
    constant ERROR_SEQ              : natural := 4;
    constant ERROR_RX_FIFO_OVERFLOW : natural := 5;
    constant ERROR_TX_FIFO_OVERFLOW : natural := 6;
    constant ERROR_TIMEOUT          : natural := 7;

    signal TimeOutCounter   : std_logic_vector(7 downto 0);
    alias TimedOut          : std_logic is TimeOutCounter(TimeOutCounter'high);
    
    signal ErrorBits        : std_logic_vector(15 downto 0);
    
    signal TxDataInt        : slv_8_vector(6 downto 0);
    signal RxDataInt        : slv_8_vector(6 downto 0);
    
    signal RxDataOut        : std_logic_vector(7 downto 0);
    signal RxFIFOPopInt     : std_logic;
    signal RxFIFODataValid  : std_logic;
    signal RxFIFOEmpty      : std_logic;
    
    signal TxFIFOPush       : std_logic;
    signal TxFIFOFull       : std_logic;
    
    signal CommandState     : fsm_state;
    
    signal BytesReceived    : std_logic_vector(2 downto 0);
    signal AllBytesReceived : std_logic;
    
    signal BytesSent        : std_logic_vector(2 downto 0);
    signal AllBytesSent     : std_logic;
    
    signal RegistersInt     : slv_32_vector(15 downto 0);
    
    signal WriteData        : std_logic_vector(31 downto 0);
    signal WriteEn          : std_logic;
    
    signal ReadData         : std_logic_vector(31 downto 0);
    signal ReadEn           : std_logic;
    
    signal Address          : std_logic_vector(15 downto 0);
    signal CommandType      : std_logic;
    signal Ack              : std_logic;
    
    begin
    
    assert (ADDRESS_DECODE'length = CmdIn'length) report "ADDRESS_DECODE and CmdIn lengths do not match." severity FAILURE;
    assert (ADDRESS_DECODE'length = CmdIn'length) report "CmdIn and CmdOut lengths do not match." severity FAILURE;
    
    uart : entity work.UARTWrapper
        generic map (
            CLK_FREQ            => CLK_FREQ,            --: real := 25000000.0;
            BAUD_RATE           => BAUD_RATE,           --: real := 9600.0;
            BAUD_ACCUM_WIDTH    => BAUD_ACCUM_WIDTH,    --: positive := 16;
            WIDE_MODE           => FALSE,               --: boolean := TRUE;
            NUM_STOP_BITS       => 1                    --: positive := 1
        )
        port map (
            UARTClk     => UARTClk, --: in  std_logic;
            Clk         => Clk,     --: in  std_logic;
            Reset       => Reset,   --: in  std_logic;
            
            RxIn        => RxIn,    --: in  std_logic;
            TxOut       => TxOut,   --: out std_logic;
            
            TxDataIn    => TxDataInt(TxDataInt'high),   --: in  std_logic_vector(7 downto 0);
            TxFIFOPush  => TxFIFOPush,      --: in  std_logic;
            TxFIFOFull  => TxFIFOFull,      --: out std_logic;
            
            RxDataOut   => RxDataOut,       --: out std_logic_vector(7 downto 0);
            RxFIFOPop   => RxFIFOPopInt,    --: in  std_logic;
            RxFIFOEmpty => RxFIFOEmpty      --: out std_logic
        );
        
    AllBytesReceived <= and_reduce(BytesReceived);
    AllBytesSent <= bool_to_sl(BytesSent = "110");
    
    process (Clk, Reset)
        begin
        if (rising_edge(Clk)) then
            
            -- TODO: output error bits from UARTWrapper.
            ErrorBits(ERROR_TX_FIFO_OVERFLOW) <= ErrorBits(ERROR_TX_FIFO_OVERFLOW) or '0';
            ErrorBits(ERROR_RX_FIFO_OVERFLOW) <= ErrorBits(ERROR_RX_FIFO_OVERFLOW) or '0';
            ErrorBits(ERROR_TIMEOUT) <= ErrorBits(ERROR_TIMEOUT) or TimedOut;
            
            if (RxFIFODataValid = '1') then
                RxDataInt <= RxDataInt(RxDataInt'high-1 downto RxDataInt'low) & RxDataOut;
                if (RxDataOut(7) = RxDataInt(0)(7) and CommandState = WAIT_FOR_NEXT_BYTE) then
                    -- Flag sequence error.
                    ErrorBits(ERROR_SEQ) <= '1';
                end if;
            end if;
            
            if (TxFIFOPush = '1') then
                TxDataInt <= TxDataInt(TxDataInt'high-1 downto 0) & x"00";
            end if;
            
            RxFIFODataValid <= RxFIFOPopInt;
            RxFIFOPopInt <= '0';
            TxFIFOPush <= '0';
            ReadEn <= '0';
            WriteEn <= '0';
            
            case (CommandState) is
                when IDLE =>

                    if (RxFIFOEmpty = '0') then
                        CommandState <= GET_COMMAND_BYTE;
                    end if;
                    TimeOutCounter <= (others=>'0');
                    BytesReceived <= (others=>'0');
                    BytesSent <= (others=>'0');
                    ErrorBits <= (others=>'0'); -- TODO: DEBUG;
                    RxDataInt(0) <= (others=>'1');
                    
                when GET_COMMAND_BYTE =>
                    if (RxFIFOEmpty = '0') then
                        -- Get a byte
                        RxFIFOPopInt <= '1';
                        BytesReceived <= BytesReceived + 1;
                        CommandState <= WAIT_FOR_NEXT_BYTE;
                    end if;
                    --TimeOutCounter <= TimeOutCounter + 1;
                when WAIT_FOR_NEXT_BYTE =>
                    if (AllBytesReceived = '1') then
                        if (or_reduce(ErrorBits) = '0') then
                            CommandState <= COMMAND_EXECUTE;
                            TimeOutCounter <= (others=>'0');
                        else
                            CommandState <= LATCH_RESPONSE;
                            TimeOutCounter <= (others=>'0');
                        end if;
                        TimeOutCounter <= (others=>'0');
--                    elsif (TimedOut = '1') then
--                        CommandState <= LATCH_RESPONSE;
--                        TimeOutCounter <= (others=>'0');
                    else
                        CommandState <= GET_COMMAND_BYTE;
                    end if;
                    --TimeOutCounter <= TimeOutCounter + 1;
                when COMMAND_EXECUTE =>
                    if (Ack = '1' or TimedOut = '1') then
                        CommandState <= LATCH_RESPONSE;
                        TimeOutCounter <= (others=>'0');
                    end if;
                    ReadEn <= not RxDataInt(6)(6);
                    WriteEn <= RxDataInt(6)(6);
                    CommandType <= RxDataInt(6)(6);
                    Address <= RxDataInt(6)(5 downto 0) & RxDataInt(5)(6 downto 0) & RxDataInt(4)(6 downto 4);
                    WriteData <= RxDataInt(4)(3 downto 0) & RxDataInt(3)(6 downto 0) & RxDataInt(2)(6 downto 0) &
                                 RxDataInt(1)(6 downto 0) & RxDataInt(0)(6 downto 0);
                    
                    
                    --TimeOutCounter <= TimeOutCounter + 1;
                    
                when LATCH_RESPONSE =>
                    TxDataInt(6) <= '0' & CommandType & ErrorBits(15 downto 10);
                    TxDataInt(5) <= '1' & ErrorBits(9 downto 3);
                    TxDataInt(4) <= '0' & ErrorBits(2 downto 0) & ReadData(31 downto 28);
                    TxDataInt(3) <= '1' & ReadData(27 downto 21);
                    TxDataInt(2) <= '0' & ReadData(20 downto 14);
                    TxDataInt(1) <= '1' & ReadData(13 downto 7);
                    TxDataInt(0) <= '0' & ReadData(6 downto 0);
                    CommandState <= QUEUE_RESPONSE;
                    
                    -- Read and write pulses one acked.
                    ReadEn  <= '0';
                    WriteEn <= '0';
                    
                when QUEUE_RESPONSE =>
                    if (TxFIFOFull = '0') then
                        -- Queue a byte.
                        TxFIFOPush <= '1';
                        BytesSent <= BytesSent + 1;
                    end if;
                        
                    if (AllBytesSent = '1') then
                        CommandState <= IDLE;
                        ErrorBits <= (others=>'0');
                    --elsif (TimedOut = '1') then
                    --    CommandState <= IDLE;
                    end if;
                    
                    --TimeOutCounter <= TimeOutCounter + 1;
            
            end case;
        end if;
        
        if (Reset = '1') then
            CommandState <= IDLE;
            ErrorBits <= (others=>'0');
            RxDataInt(0) <= (others=>'1');
            Address <= (others=>'0');
        end if;
    end process;
    
    process (Clk)
        variable TempAcks   : std_logic_vector(CmdOut'range);
        begin
        if (rising_edge(Clk)) then
            
            for i in 0 to ADDRESS_DECODE'length-1 loop
                if (std_match(pad_left(Address, 64, '0'), ADDRESS_DECODE(i))) then
                    CmdIn(i).Write <= WriteEn;
                    CmdIn(i).Read <= ReadEn;
                    ReadData <= CmdOut(i).Data(ReadData'range);
                end if;
                TempAcks(i) := CmdOut(i).Ack;
                CmdIn(i).Address(Address'range) <= Address;
                CmdIn(i).Data(WriteData'range) <= WriteData;
            end loop;
            Ack <= or_reduce(TempAcks);    -- TODO: should I only look at the correct Ack instead? Creates a GIANT mux...
        end if;
    end process;
end rtl;

--  AC'97 Controller
--
--  Description: An AC'97 audio codec controller.
--
--  Notes:  None.
--
--  Revision History:
--      Steven Okai     06/22/14    1) Initial revision.
--

library ieee;
use ieee.std_logic_1164.all;

use work.GeneralFuncPkg.all;
use work.AC97ControllerPkg.all;

entity AC97Controller is
    port (
        Clk             : in  std_logic;
        Reset           : in  std_logic;
        
        Init            : in  std_logic;
        Ready           : out std_logic;
        
        SDataIn         : in  std_logic;
        SDataOut        : out std_logic;
        
        Sync            : out std_logic;
        
        AudioInFIFOWr   : out  std_logic;
        AudioInFIFOData : out  std_logic_vector(19 downto 0);
        
        AudioOutFIFOEmpty   : in  std_logic;
        AudioOutFIFORd      : out std_logic;
        AudioOutFIFOData    : in  std_logic_vector(19 downto 0)
    );
end AC97Controller;

architecture rtl of AC97Controller is

    constant DEBUG_WAVEFORM : boolean := FALSE;
    constant BITS_PER_FRAME : positive := 256;
    constant SLOT0_BITS     : positive := 16;
    constant SLOT_BITS      : positive := 20;
    
    --constant SLOT0_FRAME_IN             : std_logic_vector(15 downto 11);
    constant SLOT0_FRAME_IN_CODEC_READY : natural := 4;
    
    signal ShiftAudioIn     : std_logic_vector(19 downto 0);
    signal AudioInSlotValid : std_logic_vector(14 downto 11);
    
    constant AudioOutValid  : std_logic := '1';
    
    signal ShiftAudioOut    : std_logic_vector(19 downto 0);
    signal BitCount         : std_logic_vector(7 downto 0);
    
    signal InitStatus       : std_logic_vector(3 downto 0);
    signal InitDone         : std_logic;
    
    signal DebugWaveformIndex   : integer;
    signal RegOut               : std_logic_vector(15 downto 0);
    
    begin
    
    ShiftAudioIn(ShiftAudioIn'right) <= SDataIn;
    AudioInFIFOData <= ShiftAudioIn;
    audio_in : process (Clk, Reset)
    
        begin
        
        if (rising_edge(Clk)) then
            if (slv_to_unsigned_int(BitCount) = SLOT0_BITS) then
                --if (ShiftAudioIn(15) = '1') then
                --    AudioInSlotValid <= ShiftAudioIn(14 downto 11);
                --end if;
                Ready <= ShiftAudioIn(15);
                AudioInSlotValid <= ShiftAudioIn(14 downto 11);
            end if;
            
            AudioInFIFOWr <= '0';
            --if (slv_to_unsigned_int(BitCount) = (SLOT0_BITS + (SLOT_BITS*3))-1 and AudioInSlotValid(1) = '1') then
            if (slv_to_unsigned_int(BitCount) = (SLOT0_BITS + (SLOT_BITS*3))) then
                --AudioInFIFOWr <= '1';
                AudioInFIFOWr <= AudioInSlotValid(12);
            end if;
            
            -- TODO: add additional fifos later...
            
            -- Shift in serial data.
            ShiftAudioIn(ShiftAudioIn'left downto ShiftAudioIn'right+1) <= ShiftAudioIn(ShiftAudioIn'left-1 downto ShiftAudioIn'right);
        end if;
    end process audio_in;
    
    SDataOut <= ShiftAudioOut(ShiftAudioOut'left);
    audio_out : process (Clk, Reset)
    
        begin 
        
        if (rising_edge(Clk)) then
        
            ShiftAudioOut <= ShiftAudioOut(ShiftAudioOut'left-1 downto ShiftAudioOut'right) & '0';
            if (slv_to_unsigned_int(BitCount) = 0) then
            --if (slv_to_unsigned_int(BitCount) = 255) then
                ShiftAudioOut <= (others=>'0');
                ShiftAudioOut(15+4) <= AudioOutValid;
                ShiftAudioOut(14+4) <= not InitDone;
                ShiftAudioOut(13+4) <= not InitDone;
                ShiftAudioOut(12+4) <= (not AudioOutFIFOEmpty) and InitDone;
                ShiftAudioOut(11+4) <= (not AudioOutFIFOEmpty) and InitDone;
            end if;
            
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS - 1) then
            if (slv_to_unsigned_int(BitCount) = SLOT0_BITS) then
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS - 2) then
                if (InitStatus = "0000") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0000010"; -- MASTER VOLUME (02h)
                    ShiftAudioOut(11 downto 0) <= (others=>'0');
                    RegOut <= (others=>'0');
                    InitStatus <= "0001";
                elsif (InitStatus = "0001") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    --ShiftAudioOut(18 downto 12) <= "0001110"; -- MIC IN VOL
                    --ShiftAudioOut(18 downto 12) <= "0010000"; -- LINE IN VOL (1Ah)
                    ShiftAudioOut(18 downto 12) <= "0011100"; -- RECORD GAIN (1Ch)
                    ShiftAudioOut(11 downto 0) <= (others=>'0');
                    RegOut <= (others=>'0');
                    InitStatus <= "0011"; -- DEBUG
                elsif (InitStatus = "0010") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0011100"; -- Phone Volume (0Ch)
                    ShiftAudioOut(11 downto 0) <= (others=>'0');
                    RegOut <= (others=>'0');
                    InitStatus <= "0011";
                elsif (InitStatus = "0011") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0011000"; -- PCM OUTPUT VOLUME (18h)
                    ShiftAudioOut(11 downto 0) <= (others=>'0');
                    RegOut <= (others=>'0');
                    InitStatus <= "0100";
                elsif (InitStatus = "0100") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0100000";
                    ShiftAudioOut(11 downto 0) <= (others=>'0'); -- BYPASS 3D BLOCK 
                    RegOut <= x"8000";
                    InitStatus <= "0101";
                elsif (InitStatus = "0101") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0000100";
                    ShiftAudioOut(11 downto 0) <= (others=>'0'); -- HEADPHONE VOLUME (02h)
                    RegOut <= (others=>'0');
                    --RegOut(12 downto 8) <= (others=>'1');
                    RegOut(12 downto 8) <= "11000";
                    --RegOut(4 downto 0) <= (others=>'1');
                    RegOut(4 downto 0) <= "11000";
                    InitStatus <= "0111"; -- DEBUG
                elsif (InitStatus = "0110") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0000110";
                    ShiftAudioOut(11 downto 0) <= (others=>'0'); -- MONO VOLUME (02h)
                    RegOut <= (others=>'0');
                    InitStatus <= "0111";
                elsif (InitStatus = "0111") then
                    ShiftAudioOut(19) <= '0';   -- Set to write.
                    ShiftAudioOut(18 downto 12) <= "0011010";
                    ShiftAudioOut(11 downto 0) <= (others=>'0'); -- RECORD SEL (1Ah)
                    RegOut <= (others=>'0');
                    RegOut(2 downto 0) <= "100";
                    RegOut(10 downto 8) <= "100";
                    InitStatus <= "1000";
                    InitDone <= '1';
                end if;
            end if;
            
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + SLOT_BITS - 1) then
            if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + SLOT_BITS) then
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + SLOT_BITS - 2) then
                ShiftAudioOut <= RegOut & "0000";
            end if;
            
            AudioOutFIFORd <= '0';
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*2) - 1) then
            if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*2)) then
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*2) - 2) then
                -- Use sine wave in debug mode.
                if (DEBUG_WAVEFORM) then
                    ShiftAudioOut <= DEBUG_SQUARE(DebugWaveformIndex);
                else
                    ShiftAudioOut <= AudioOutFIFOData;
                    --AudioOutFIFORd <= '1';  -- Pop audio out FIFO.
                end if;
            end if;
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*3) - 1) then
            if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*3)) then
            --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*3) - 2) then
                -- Use sine wave in debug mode.
                if (DEBUG_WAVEFORM) then
                    ShiftAudioOut <= DEBUG_SQUARE(DebugWaveformIndex);
                else
                    ShiftAudioOut <= AudioOutFIFOData;
                    AudioOutFIFORd <= '1';  -- Pop audio out FIFO.
                end if;
            end if;
            
            if (Init = '1') then
                InitStatus <= (others=>'0');
                InitDone <= '0';
            end if;
        end if;
        
        if (Reset = '1') then
            InitStatus <= (others=>'0');
            InitDone <= '0';
            ShiftAudioOut <= (others=>'0');
        end if;
        
    end process audio_out;
    
    sync_gen : process (Clk, Reset)
    
        begin
        
        if (rising_edge(Clk)) then
            if (slv_to_unsigned_int(BitCount) = BITS_PER_FRAME-1) then
                Sync <= '1';
            --elsif (slv_to_unsigned_int(BitCount) = 15) then
            elsif (slv_to_unsigned_int(BitCount) = 16) then
                Sync <= '0';
            end if;
        end if;
        
        if (Reset = '1') then
            Sync <= '0';
        end if;
        
    end process sync_gen;
    
    bit_counter : process (Clk, Reset)
        
        begin
        
        if (rising_edge(Clk)) then
        
            if (slv_to_unsigned_int(BitCount) = BITS_PER_FRAME-1) then
                BitCount <= (others=>'0');
            else
                BitCount <= increment(BitCount);
            end if;
            
        end if;
        
        if (Reset = '1') then
            BitCount <= (others=>'1');
            -- TODO: WHAT TO DO WITH SYNC?
        end if;
        
    end process bit_counter;
    
    debug_counter : if (DEBUG_WAVEFORM) generate
        process (Clk, Reset)
            begin
            
            if (rising_edge(Clk)) then
                --if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*4) - 1) then
                if (slv_to_unsigned_int(BitCount) = SLOT0_BITS + (SLOT_BITS*4)) then
                    if (DebugWaveformIndex = DEBUG_SQUARE'length-1) then
                        DebugWaveformIndex <= 0;
                    else
                        DebugWaveformIndex <= DebugWaveformIndex + 1;
                    end if;
                end if;
            end if;
            if (Reset = '1') then
                DebugWaveformIndex <= 0;
            end if;
        end process;
    end generate;
end rtl;

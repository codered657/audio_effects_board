--  Soft Clipper Effect
--
--  Description: Soft clipping audio effect.
--
--  Notes: None.
--
--  Revision History:
--      Steven Okai     06/22/14    1) Initial revision.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GeneralFuncPkg.all;
use work.CommandBusPkg.all;

entity SoftClipper is
    generic (
        CMD_ACK_DELAY   : positive := 8
    );
    port (
        Clk             : in  std_logic;

        Enable          : in  std_logic;
        
        CmdBusIn        : in  cmd_bus_in;
        CmdBusOut       : out cmd_bus_out;
        
        AudioIn         : in  std_logic_vector(17 downto 0);
        AudioInValid    : in  std_logic;
        
        AudioOut        : out std_logic_vector(17 downto 0);
        AudioOutValid   : out std_logic
    );
end SoftClipper;

architecture rtl of SoftClipper is

    -- Memory map.
    constant ADDR_THRESHOLD     : natural := 0;
    constant ADDR_COEFFICIENT   : natural := 1;
    
    signal AboveThresholdAudioP : slv_18_vector(0 to 4);
    signal AudioP               : slv_18_vector(0 to 4);
    signal AudioValidP          : std_logic_vector(0 to 4);
    signal ThresholdP           : slv_18_vector(0 to 4);
    signal NegativeThreshold    : std_logic_vector(17 downto 0);
    signal OutOfBoundsP         : std_logic_vector(0 to 4);

    signal Registers            : slv_32_vector(0 to 1);
    alias Threshold             : std_logic_vector(17 downto 0) is Registers(ADDR_THRESHOLD)(17 downto 0);    -- TODO: limit this to 17 bits...must be positive after all.
    alias Coefficient           : std_logic_vector(7 downto 0) is Registers(ADDR_THRESHOLD)(7 downto 0);
    constant REG_MASKS          : slv_32_vector(0 to 1) := (
        ADDR_THRESHOLD      => (Threshold'range => '1', others => '0'),
        ADDR_COEFFICIENT    => (Coefficient'range => '1', others => '0')
    );
    
    signal WriteP               : std_logic_vector(1 to CMD_ACK_DELAY);
    signal WriteEdge            : std_logic;
    signal AckP                 : std_logic_vector(1 to CMD_ACK_DELAY);
    
    begin
    
    AudioP(0) <= AudioIn;
    AudioValidP(0) <= AudioInValid;
    ThresholdP(0) <= Threshold;
    
    AudioOut <= AudioP(4);
    AudioOutValid <= AudioValidP(4);
    
    -- TODO: register this!!!!
    NegativeThreshold <= negate(Threshold);
    
    process (Clk)
        variable TempAboveThresholdAudioP3  : std_logic_vector(35 downto 0);
        begin
        if (rising_edge(Clk)) then
            -- Audio pipeline.
            AudioP(1 to 3) <= AudioP(0 to 2);
            AudioValidP(1 to 4) <= AudioValidP(0 to 3);
            ThresholdP(2 to 4) <= ThresholdP(1 to 3);
            OutOfBoundsP(2 to 4) <= OutOfBoundsP(1 to 3);
            
            -- Threshold detection stage.
            if (signed(AudioP(0)) > signed(Threshold)) then
                ThresholdP(1) <= Threshold;
                OutOfBoundsP(1) <= '1';
            elsif (signed(AudioP(0)) < signed(NegativeThreshold)) then
                ThresholdP(1) <= NegativeThreshold;
                OutOfBoundsP(1) <= '1';
            else
                OutOfBoundsP(1) <= '0';
            end if;
            
            AboveThresholdAudioP(2) <= std_logic_vector(signed(AudioP(1)) - signed(ThresholdP(1)));
            
            TempAboveThresholdAudioP3 := std_logic_vector(signed(AboveThresholdAudioP(2)) * signed(pad_left(Coefficient, 18, '0')));
            AboveThresholdAudioP(3) <= TempAboveThresholdAudioP3(17+8 downto 8);
            
            if (Enable = '1' and OutOfBoundsP(3) = '1') then
                AudioP(4) <= std_logic_vector(signed(ThresholdP(3)) + signed(AboveThresholdAudioP(3)));
            else
                AudioP(4) <= AudioP(3);
            end if;
            
        end if;
    end process;

    regs : process (Clk)
        variable CmdAddr    : std_logic_vector(2 downto 2);
        begin
        if (rising_edge(Clk)) then
        
            -- Edge detect the write pulse
            WriteP <= CmdBusIn.Write & WriteP(WriteP'low to WriteP'high-1);
            WriteEdge <= WriteP(WriteP'high-1) and (not WriteP(WriteP'high));  -- TODO: Do I need to delay this more for a multicycle path??? Probably...otherwise this possibly gets there before address?
            
            AckP <= (CmdBusIn.Write or CmdBusIn.Read) & AckP(AckP'low to AckP'high-1);
            CmdBusOut.Ack <= AckP(AckP'high); -- TODO: can this be tied directly to Ack instead of one last register?

            CmdAddr := CmdBusIn.Address(CmdAddr'range);
            -- TODO: add mask so unused bits get synthed out.
            CmdBusOut.Data(31 downto 0) <= Registers(slv_to_unsigned_int(CmdAddr)) and REG_MASKS(slv_to_unsigned_int(CmdAddr));  -- TODO: Should this even be registered?
            
            -- TODO: pad data out????
            if (WriteEdge = '1') then
                Registers(slv_to_unsigned_int(CmdAddr)) <= CmdBusIn.Data(31 downto 0) and REG_MASKS(slv_to_unsigned_int(CmdAddr));
            end if;
 
        end if;
    end process regs;
end rtl;

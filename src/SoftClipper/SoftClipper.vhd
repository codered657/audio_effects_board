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

entity SoftClipper is
    port (
        Clk             : in  std_logic;

        Enable          : in  std_logic;
        
        Threshold       : in  std_logic_vector(17 downto 0);    -- TODO: limit this to 17 bits...must be positive after all.
        Coefficient     : in  std_logic_vector(7 downto 0);
        
        AudioIn         : in  std_logic_vector(17 downto 0);
        AudioInValid    : in  std_logic;
        
        AudioOut        : out std_logic_vector(17 downto 0);
        AudioOutValid   : out std_logic
    );
end SoftClipper;

architecture rtl of SoftClipper is

    signal AboveThresholdAudioP : slv_18_vector(0 to 4);
    signal AudioP               : slv_18_vector(0 to 4);
    signal AudioValidP          : std_logic_vector(0 to 4);
    signal ThresholdP           : slv_18_vector(0 to 4);
    signal NegativeThreshold    : std_logic_vector(17 downto 0);
    signal OutOfBoundsP         : std_logic_vector(0 to 4);
    
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

end rtl;

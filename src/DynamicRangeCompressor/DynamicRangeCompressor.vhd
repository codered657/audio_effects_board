library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.GeneralFuncPkg.all;

entity DynamicRangeCompressor is
    port (
        Clk             : in  std_logic;
        Reset           : in  std_logic;
        
        Enable          : in  std_logic;
        
        AttackTime      : in  std_logic_vector(2 downto 0);
        ReleaseTime     : in  std_logic_vector(2 downto 0);
        Threshold       : in  std_logic_vector(4 downto 0);
        Ratio           : in  std_logic_vector(5 downto 0);
        MakeUpGain      : in  std_logic_vector(3 downto 0);
        
        AudioIn         : in  std_logic_vector(17 downto 0);
        AudioInValid    : in  std_logic;
        
        AudioOut        : out std_logic_vector(17 downto 0);
        AudioOutValid   : out std_logic 
    );
end DynamicRangeCompressor;

architecture rtl of DynamicRangeCompressor is
    
    signal AudioP       : slv_18_vector(0 to 10);
    signal AudioValidP  : std_logic_vector(0 to 10);
    signal PeakLevelP3  : std_logic_vector(17 downto 0);
    
    signal PeakLeveldBP : slv_5_vector(4 to 6);

    signal PeakLevelMinusThresholdP5    : std_logic_vector(4 downto 0);
    
    signal PeakLevelMinusThresholdTimesRatioP6  : std_logic_vector(4 downto 0);
    
    signal GaindBP7 : std_logic_vector(4 downto 0);
    
    signal TotalGaindBP8        : std_logic_vector(4 downto 0);
    signal SignedTotalGaindBP8  : std_logic_vector(5 downto 0);
    signal TotalGaindBP9        : std_logic_vector(5 downto 0);
    
    begin
    
    AudioP(0) <= AudioIn;
    AudioValidP(0) <= AudioInValid;
    
    AudioOut <= AudioP(10);
    AudioOutValid <= AudioValidP(10);
    
    peak_detector : entity work.PeakDetector
        port map (
            Clk             => Clk,             --: in  std_logic;
            Reset           => Reset,           --: in  std_logic;
            
            AttackTime      => AttackTime,      --: in  std_logic_vector(2 downto 0);
            ReleaseTime     => ReleaseTime,     --: in  std_logic_vector(2 downto 0);
            
            AudioIn         => AudioIn,         --: in  std_logic_vector(17 downto 0);
            AudioInValid    => AudioInValid,    --: in  std_logic;
            
            PeakLevel       => PeakLevelP3      --: out std_logic_vector(17 downto 0)
        );
    
    process (Clk)
    
        variable TempPeakLevelMinusThresholdTimesRatioP6    : std_logic_vector(10 downto 0);
        variable TempAudioP9                                : std_logic_vector(51 downto 0);
        variable TempAudioP10                               : std_logic_vector(51 downto 0);
        begin
        
        if (rising_edge(Clk)) then
        
            AudioP(AudioP'low+1 to 9) <= AudioP(AudioP'low to 8);
            AudioValidP(AudioValidP'low+1 to AudioValidP'high) <= AudioValidP(AudioValidP'low to AudioValidP'high-1);
        
            if (std_match(PeakLevelP3, "000000000000000000")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(0, 5);
            elsif (std_match(PeakLevelP3, "00000000000000000-")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(1, 5);
            elsif (std_match(PeakLevelP3, "0000000000000000--")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(2, 5);
            elsif (std_match(PeakLevelP3, "000000000000000---")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(3, 5);
            elsif (std_match(PeakLevelP3, "00000000000000----")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(4, 5);
            elsif (std_match(PeakLevelP3, "0000000000000-----")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(5, 5);
            elsif (std_match(PeakLevelP3, "000000000000------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(6, 5);
            elsif (std_match(PeakLevelP3, "00000000000-------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(7, 5);
            elsif (std_match(PeakLevelP3, "0000000000--------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(8, 5);
            elsif (std_match(PeakLevelP3, "000000000---------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(9, 5);
            elsif (std_match(PeakLevelP3, "00000000----------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(10, 5);
            elsif (std_match(PeakLevelP3, "0000000-----------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(11, 5);
            elsif (std_match(PeakLevelP3, "000000------------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(12, 5);
            elsif (std_match(PeakLevelP3, "00000-------------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(13, 5);
            elsif (std_match(PeakLevelP3, "0000--------------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(14, 5);
            elsif (std_match(PeakLevelP3, "000---------------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(15, 5);
            elsif (std_match(PeakLevelP3, "00----------------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(16, 5);
            elsif (std_match(PeakLevelP3, "0-----------------")) then
                PeakLeveldBP(4) <= unsigned_int_to_slv(17, 5);
            else
                PeakLeveldBP(4) <= unsigned_int_to_slv(18, 5);
            end if;
            
            PeakLevelMinusThresholdP5 <= PeakLeveldBP(4) - Threshold;
            PeakLeveldBP(5) <= PeakLeveldBP(4);
            
            TempPeakLevelMinusThresholdTimesRatioP6 := PeakLevelMinusThresholdP5 * Ratio;
            PeakLevelMinusThresholdTimesRatioP6 <= TempPeakLevelMinusThresholdTimesRatioP6(4+6 downto 6);
            
            PeakLeveldBP(6) <= PeakLeveldBP(5);
            
            if (PeakLeveldBP(6) <= Threshold) then
                --GaindBP7 <= PeakLeveldBP(6);
                GaindBP7 <= unsigned_int_to_slv(18, 5);
            else
                --GaindBP7 <= Threshold + PeakLevelMinusThresholdTimesRatioP6;
                GaindBP7 <= unsigned_int_to_slv(18, 5) - PeakLevelMinusThresholdTimesRatioP6;
            end if;
            
            TotalGaindBP8 <= GaindBP7 + pad_left(MakeUpGain, 5, '0');
                
            -- TODO: this actually should be left padded with the sign bit...
            --AudioOut <= (("000000000000000000") & AudioP(?))(35-TotalGaindB downto 18-TotalGaindB);
            if (Enable = '1') then
                TempAudioP10 := pad_left(AudioP(9), 36, AudioP(9)(AudioP(9)'high)) & x"0000";
                AudioP(10) <= TempAudioP10(35+16-slv_to_unsigned_int(TotalGaindBP9) downto 18+16-slv_to_unsigned_int(TotalGaindBP9));
            else
                AudioP(10) <= AudioP(9);
            end if;
        end if;
        
    end process;
    
    SignedTotalGaindBP8 <= '0' & TotalGaindBP8;
    
    test : entity work.IIRFirstOrderLPF
        generic map (
            DATA_WIDTH      => TotalGaindBP8'length+1
        )
        port map (
            Clk             => Clk,
            Reset           => Reset,
            
            Enable          => '1',
            
            SmoothingFactor => "11111",
            
            DataIn          => SignedTotalGaindBP8,
            DataInValid     => AudioValidP(8),
            
            DataOut         => TotalGaindBP9,
            DataOutValid    => open
        );
end rtl;
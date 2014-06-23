library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GeneralFuncPkg.all;

entity PeakDetector is
    port (
        Clk             : in  std_logic;
        
        Reset           : in  std_logic;
        
        AttackTime      : in  std_logic_vector(2 downto 0);
        ReleaseTime     : in  std_logic_vector(2 downto 0);
        
        AudioIn         : in  std_logic_vector(17 downto 0);
        AudioInValid    : in  std_logic;
        
        PeakLevel       : out std_logic_vector(17 downto 0)
        
    );
end PeakDetector;

architecture rtl of PeakDetector is

    constant AttackTable    : slv_18_vector(0 to 7) := (
            "111110101011100111",
            "111111010101011001",
            "111111101010101100",
            "111111110101010110",
            "111111111010101011",
            "111111111101001000",
            "111111111110110001",
            "111111111111001011"
        );
    
    constant ReleaseTable   : slv_18_vector(0 to 7) := (
            "111111111110101000",
            "111111111111010100",
            "111111111111101010",
            "111111111111110101",
            "111111111111111010",
            "111111111111111101",
            "111111111111111110",
            "111111111111111111"
        );
        
    signal AttackCoef           : std_logic_vector(17 downto 0);
    signal OneMinusAttackCoef   : std_logic_vector(17 downto 0);
    signal ReleaseCoef          : std_logic_vector(17 downto 0);
    
    signal AudioTimesOneMinusAttackCoefP2   : std_logic_vector(17 downto 0);
    
    signal PeakLevelP3          : std_logic_vector(17 downto 0);
    
    signal AudioValidP          : std_logic_vector(0 to 2);
    
    signal AudioAbsP            : slv_18_vector(1 to 2);
    
    begin
    
    AudioValidP(0) <= AudioInValid;
    PeakLevel <= PeakLevelP3;
    
    attack_release_lut : process (Clk)
        begin
        if (rising_edge(Clk)) then
            AttackCoef <= AttackTable(slv_to_unsigned_int(AttackTime));
            OneMinusAttackCoef <= "111111111111111111" - AttackTable(slv_to_unsigned_int(AttackTime));
            ReleaseCoef <= ReleaseTable(slv_to_unsigned_int(ReleaseTime));
        end if;
    end process attack_release_lut;
    
    process (Clk, Reset)
        variable TempAudioTimesOneMinusAttackCoefP2 : std_logic_vector(35 downto 0);
        variable TempPeakLevelP3                    : std_logic_vector(35 downto 0);
        begin
        
        if (rising_edge(Clk)) then
            
            -- Pass valid down pipeline.
            AudioValidP(AudioValidP'low+1 to AudioValidP'high) <= AudioValidP(AudioValidP'low to AudioValidP'high-1);
            
            -- Calculate absolute value of input audio.
            if (AudioIn(AudioIn'high) = '1') then
                AudioAbsP(1) <= negate(AudioIn);
            else
                AudioAbsP(1) <= AudioIn;
            end if;
            
            -- Calculate (1 - AttackCoef)*|AudioIn|.
            TempAudioTimesOneMinusAttackCoefP2 := (OneMinusAttackCoef * AudioAbsP(1));
            AudioTimesOneMinusAttackCoefP2 <= TempAudioTimesOneMinusAttackCoefP2(17+18 downto 18);
            AudioAbsP(2) <= AudioAbsP(1);   -- Pass absolute value of audio in down pipeline.
            
            -- Only update peak level when audio is valid.
            if (AudioValidP(2) = '1') then
                -- If |AudioIn| > PeakLevel(n-1), attack phase.
                if (AudioAbsP(2) > PeakLevelP3) then
                    TempPeakLevelP3 := AttackCoef * PeakLevelP3;
                    PeakLevelP3 <= TempPeakLevelP3(17+18 downto 18) + AudioTimesOneMinusAttackCoefP2;
                -- Otherwise, release phase.
                else
                    TempPeakLevelP3 := ReleaseCoef * PeakLevelP3;
                    PeakLevelP3 <= TempPeakLevelP3(17+18 downto 18);
                end if;
            end if;
        end if;
        
        if (Reset = '1') then
            PeakLevelP3 <= (others=>'0');
        end if;
    end process;
    
end rtl;

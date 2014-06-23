library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.GeneralFuncPkg.all;

entity DynamicRangeCompressorTB is
end DynamicRangeCompressorTB;

architecture test of DynamicRangeCompressorTB is
    signal Clk              : std_logic := '0';
    signal Reset            : std_logic := '1';

    signal Enable           : std_logic := '1';
    
    signal AttackTime       : std_logic_vector(2 downto 0) := "010";
    signal ReleaseTime      : std_logic_vector(2 downto 0) := "001";
    signal Threshold        : std_logic_vector(4 downto 0) := unsigned_int_to_slv(3, 5);
    signal Ratio            : std_logic_vector(5 downto 0) := "100000";
    signal MakeUpGain       : std_logic_vector(3 downto 0) := "0000";
    
    signal AudioIn          : std_logic_vector(17 downto 0) := (others=>'0');
    signal AudioInValid     : std_logic := '1';
    
    signal AudioOut         : std_logic_vector(17 downto 0);
    signal AudioOutValid    : std_logic;
    
    signal AudioAmplitude   : std_logic_vector(17 downto 0) := "000000000000000001";
    
    begin
    
    Clk <= not Clk after 5 ns;
    
    process
        begin
        
        wait for 20 ns;
        Reset <= '0';
        
        wait until rising_edge(Clk);
        
        AudioAmplitude <= "000010000000000000";
        
        wait for 2 ms;
        
        wait until rising_edge(Clk);
        
        AudioAmplitude <= "000000000000000010";
        
        wait;
    end process;
   
    process (Clk)
        begin
        
        if (rising_edge(Clk)) then
            
            if (AudioIn = AudioAmplitude) then
                AudioIn <= negate(AudioAmplitude);
            else
                AudioIn <= AudioIn + 1;
            end if;
            
        end if;
    end process;
    
    uut : entity work.DynamicRangeCompressor
        port map (
            Clk             => Clk,                             --: in  std_logic;
            Reset           => Reset,                           --: in  std_logic;

            Enable          => Enable,                          --: in  std_logic;

            AttackTime      => AttackTime,                      --: in  std_logic_vector(2 downto 0);
            ReleaseTime     => ReleaseTime,                     --: in  std_logic_vector(2 downto 0);
            Threshold       => Threshold,                       --: in  std_logic_vector(4 downto 0);
            Ratio           => Ratio,                           --: in  std_logic_vector(5 downto 0);
            MakeUpGain      => MakeUpGain,                      --: in  std_logic_vector(3 downto 0);

            AudioIn         => AudioIn,                         --: in  std_logic_vector(17 downto 0);
            AudioInValid    => AudioInValid,                    --: in  std_logic;

            AudioOut        => AudioOut,                        --: out std_logic_vector(17 downto 0);
            AudioOutValid   => AudioOutValid                    --: out std_logic 
        );
        
end test;

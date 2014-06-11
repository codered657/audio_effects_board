library ieee;
use ieee.std_logic_1164.all;

entity AudioEffectsBoardTB is
end entity AudioEffectsBoardTB;

architecture testbench of AudioEffectsBoardTB is

    signal BitClk   : std_logic := '0';
    signal AudSDI   : std_logic;
    signal AudSDO   : std_logic;
    signal AudSync  : std_logic;
    signal AudRst   : std_logic;

    signal Btn      : std_logic_vector(0 to 5) := "011111";
    
    begin
    
    BitClk <= not BitClk after 5 ns;
    Btn <= "100000" after 20 ns;
    
    process
        begin
        wait;
    end process;
    
    uut : entity work.AudioEffectsBoard
        port map (
            BitClk  => BitClk,  --: in  std_logic;
            AudSDI  => AudSDI,  --: in  std_logic;
            AudSDO  => AudSDO,  --: out std_logic;
            AudSync => AudSync, --: out std_logic;
            AudRst  => AudRst,  --: out std_logic;
            
            LED     => open,    --: out std_logic_vector(7 downto 0);
            Btn     => Btn      --: in  std_logic_vector(0 to 5)
        );
        
end testbench;
library ieee;
use ieee.std_logic_1164.all;

entity AudioEffectsBoardTB is
end entity AudioEffectsBoardTB;

architecture testbench of AudioEffectsBoardTB is

    signal Clk      : std_logic := '0';
    signal BitClk   : std_logic := '0';
    signal AudSDI   : std_logic;
    signal AudSDO   : std_logic;
    signal AudSync  : std_logic;
    signal AudRst   : std_logic;

    signal Btn      : std_logic_vector(0 to 5) := "011111";
    signal Sw       : std_logic_vector(7 downto 0) := (others=>'1');
    
    begin
    
    BitClk <= not BitClk after 10 ns;
    Clk <= not Clk after 5 ns;
    Btn <= "100000" after 20 ns;
    
    process
        begin
        wait;
    end process;
    
    uut : entity work.AudioEffectsBoard
        generic map (
            USE_DEBUG_COUNTER => TRUE
        )
        port map (
            Clk     => Clk,     --: in  std_logic;
            BitClk  => BitClk,  --: in  std_logic;
            AudSDI  => AudSDI,  --: in  std_logic;
            AudSDO  => AudSDO,  --: out std_logic;
            AudSync => AudSync, --: out std_logic;
            AudRst  => AudRst,  --: out std_logic;
            
            LED     => open,    --: out std_logic_vector(7 downto 0);
            Btn     => Btn,     --: in  std_logic_vector(0 to 5);
            Sw      => Sw       --: in  std_logic_vector(7 downto 0);
        );
        
end testbench;
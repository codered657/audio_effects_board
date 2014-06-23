library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GeneralFuncPkg.all;

entity SoftClipperTB is
end SoftClipperTB;

architecture test of SoftClipperTB is

    signal Clk             : std_logic := '0';

    signal Enable          : std_logic := '1';
    
    signal Threshold       : std_logic_vector(17 downto 0) := signed_int_to_slv(64, 18);
    signal Coefficient     : std_logic_vector(7 downto 0) := "00000001";
    
    signal AudioIn         : std_logic_vector(17 downto 0) := (others=>'0');
    signal AudioInValid    : std_logic := '0';
    
    signal AudioOut        : std_logic_vector(17 downto 0);
    signal AudioOutValid   : std_logic;
    
    begin

    Clk <= not Clk after 5 ns;
    
    process
        begin
        
        wait until rising_edge(Clk);
        AudioInValid <= '1';
        
        for i in 0 to 127 loop
            AudioInValid <= '1';
            AudioIn <= increment(AudioIn);
            wait until rising_edge(Clk);
            AudioInValid <= '0';
            AudioIn <= increment(AudioIn);
            wait until rising_edge(Clk);
        end loop;
        
        AudioIn <= signed_int_to_slv(-128, 18);
        wait until rising_edge(Clk);
        
        for i in 0 to 127 loop
            AudioInValid <= '1';
            AudioIn <= increment(AudioIn);
            wait until rising_edge(Clk);
            AudioInValid <= '0';
            AudioIn <= increment(AudioIn);
            wait until rising_edge(Clk);
        end loop;
        
        wait;
    end process;
    
    uut : entity work.SoftClipper
        port map (
            Clk             => Clk,             --: in  std_logic;

            Enable          => Enable,          --: in  std_logic;

            Threshold       => Threshold,       --: in  std_logic_vector(17 downto 0);
            Coefficient     => Coefficient,     --: in  std_logic_vector(7 downto 0);

            AudioIn         => AudioIn,         --: in  std_logic_vector(17 downto 0);
            AudioInValid    => AudioInValid,    --: in  std_logic;

            AudioOut        => AudioOut,        --: out std_logic_vector(17 downto 0);
            AudioOutValid   => AudioOutValid    --: out std_logic
        );
end test;
--  Soft Clipper Test Bench
--
--  Description: Test bench for soft clipping audio effect.
--
--  Notes: None.
--
--  Revision History:
--      Steven Okai     06/22/14    1) Initial revision.
--      Steven Okai     08/05/14    1) Updated to use command bus.
--      Steven Okai     08/23/14    1) Fixed bugs in register writes.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GeneralFuncPkg.all;
use work.CommandBusPkg.all;

entity SoftClipperTB is
end SoftClipperTB;

architecture test of SoftClipperTB is

    signal Clk             : std_logic := '0';

    signal Enable          : std_logic := '1';
    
    signal CmdBusIn        : cmd_bus_in := CMD_BUS_IN_IDLE;
    signal CmdBusOut       : cmd_bus_out;
    
    signal AudioIn         : std_logic_vector(17 downto 0) := (others=>'0');
    signal AudioInValid    : std_logic := '0';
    
    signal AudioOut        : std_logic_vector(17 downto 0);
    signal AudioOutValid   : std_logic;
    
    begin

    Clk <= not Clk after 5 ns;
    
    process
        begin
        
        wait for 20 ns;
        
        -- TODO: use constants, maybe add non-slv argument options by overloading functions?
        cmd_bus_write_verify(x"0000", x"00008000", Clk, CmdBusIn, CmdBusOut);
        cmd_bus_write_verify(x"0004", x"00000001", Clk, CmdBusIn, CmdBusOut);
        
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

            CmdBusIn        => CmdBusIn,        --: in  cmd_bus_in;
            CmdBusOut       => CmdBusOut,       --: out cmd_bus_out;

            AudioIn         => AudioIn,         --: in  std_logic_vector(17 downto 0);
            AudioInValid    => AudioInValid,    --: in  std_logic;

            AudioOut        => AudioOut,        --: out std_logic_vector(17 downto 0);
            AudioOutValid   => AudioOutValid    --: out std_logic
        );
end test;
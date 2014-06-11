library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.GeneralFuncPkg.all;

entity AudioEffectsBoard is
    port (
        BitClk  : in  std_logic;
        AudSDI  : in  std_logic;
        AudSDO  : out std_logic;
        AudSync : out std_logic;
        AudRst  : out std_logic;
        
        LED     : out std_logic_vector(7 downto 0);
        Btn     : in  std_logic_vector(0 to 5)
    );
    
end entity AudioEffectsBoard;

architecture rtl of AudioEffectsBoard is

    signal Reset                : std_logic;
    signal nResetIn             : std_logic;
    signal ResetIn              : std_logic;
    signal Init                 : std_logic;
    
    signal AudioInFIFOWr        : std_logic;
    signal AudioInFIFOData      : std_logic_vector(19 downto 0);

    signal AudioOutFIFOEmpty    : std_logic;
    signal AudioOutFIFORd       : std_logic;
    signal AudioOutFIFOData     : std_logic_vector(19 downto 0);
    
    signal DEBUG_COUNTER        : std_logic_vector(19 downto 0);
    
    begin
    
    LED(2 downto 1) <= (others=>'1');
    LED(7) <= BitClk;
    LED(6) <= Reset;
    LED(5) <= ResetIn;
    LED(4) <= Btn(1);
    Init <= Btn(1);
    ResetIn <= not Btn(0);
    nResetIn <= not Btn(5);
    AudRst <= nResetIn;
    LED(3) <= nResetIn;
    
    global_reset : entity work.ResetSynchronizer
        generic map (
            NUM_STAGES  => 4    --: natural range 2 to 8 := 2    -- Number of synchronization stages.
        )
        port map (
            Clk         => BitClk,      --: in  std_logic;
            ResetIn     => ResetIn,     --: in  std_logic;
            ResetOut    => Reset        --: out std_logic;
        );
        
    audio_controller : entity work.AC97Controller
        port map (
            Clk                 => BitClk,              --: in  std_logic;
            Reset               => Reset,               --: in  std_logic;
            
            Init                => Init,                --: in  std_logic;
            Ready               => LED(0),              --: out std_logic;
            
            SDataIn             => AudSDI,              --: in  std_logic;
            SDataOut            => AudSDO,              --: out std_logic;
            
            Sync                => AudSync,             --: out std_logic;
            
            AudioInFIFOWr       => AudioInFIFOWr,       --: out  std_logic;
            AudioInFIFOData     => AudioInFIFOData,     --: out  std_logic_vector(19 downto 0);
            
            AudioOutFIFOEmpty   => AudioOutFIFOEmpty,   --: in  std_logic;
            AudioOutFIFORd      => AudioOutFIFORd,      --: out std_logic;
            AudioOutFIFOData    => AudioOutFIFOData     --AudioOutFIFOData     --: in  std_logic_vector(19 downto 0)
        );

    audio_fifo : entity work.AsyncFIFO
        port map (
            rst     => Reset,               --: in std_logic;
            wr_clk  => BitClk,              --: in std_logic;
            rd_clk  => BitClk,              --: in std_logic;
            din     => AudioInFIFOData,     --: in std_logic_vector(19 downto 0);
            wr_en   => AudioInFIFOWr,       --: in std_logic;
            rd_en   => AudioOutFIFORd,      --: in std_logic;
            dout    => AudioOutFIFOData,    --: out std_logic_vector(19 downto 0);
            full    => open,                --: out std_logic;
            empty   => AudioOutFIFOEmpty    --: out std_logic
        );
        
    debug_data : process (BitClk, Reset)
    
        begin
        
        if (rising_edge(BitClk)) then
            --Reset <= ResetIn;
            DEBUG_COUNTER(19 downto 4) <= DEBUG_COUNTER(19 downto 4) + 1;
        end if;
        
        if (Reset = '1') then
            DEBUG_COUNTER <= (others=>'0');
        end if;
    end process;
end rtl;


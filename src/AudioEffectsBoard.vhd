library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.GeneralFuncPkg.all;

entity AudioEffectsBoard is
    generic (
        USE_DEBUG_COUNTER   : boolean := FALSE
    );
    port (
        Clk     : in  std_logic;
        BitClk  : in  std_logic;
        AudSDI  : in  std_logic;
        AudSDO  : out std_logic;
        AudSync : out std_logic;
        AudRst  : out std_logic;
        
        LED     : out std_logic_vector(7 downto 0);
        Btn     : in  std_logic_vector(0 to 5);
        Sw      : in  std_logic_vector(7 downto 0)
    );
    
end entity AudioEffectsBoard;

architecture rtl of AudioEffectsBoard is

    signal Reset                : std_logic;
    signal nResetIn             : std_logic;
    signal ResetIn              : std_logic;
    signal Init                 : std_logic;
    
    signal AudioInFIFOWr        : std_logic;
    signal AudioInFIFOEmpty     : std_logic;
    signal AudioInFIFORd        : std_logic;
    signal AudioInFIFOWrData    : std_logic_vector(19 downto 0);
    signal AudioInFIFORdData    : std_logic_vector(19 downto 0);

    signal AudioOutFIFOWr       : std_logic;
    signal AudioOutFIFOEmpty    : std_logic;
    signal AudioOutFIFORd       : std_logic;
    signal AudioOutFIFOWrData   : std_logic_vector(19 downto 0);
    signal AudioOutFIFORdData   : std_logic_vector(19 downto 0);
    
    signal EnableSoftClipper    : std_logic;
    signal EnableDistortion     : std_logic;
    signal EnableCompressor     : std_logic;
    
    signal Threshold            : std_logic_vector(17 downto 0) := signed_int_to_slv(65000, 18);
    signal Coefficient          : std_logic_vector(7 downto 0) := "01000000";
    signal AudioInValid         : std_logic;
    
    signal SoftClipperOut       : std_logic_vector(17 downto 0);
    signal SoftClipperOutValid  : std_logic;
    
    signal DistortionOut        : std_logic_vector(17 downto 0);
    signal DistortionOutValid   : std_logic;
    
    signal PushBtn              : std_logic_vector(1 to 5);
    signal Press                : std_logic_vector(1 to 5);
    signal Release              : std_logic_vector(1 to 5);
    
    signal AttackTime           : std_logic_vector(2 downto 0) := "001";
    signal ReleaseTime          : std_logic_vector(2 downto 0) := "111";
    signal CompressorThreshold  : std_logic_vector(4 downto 0) := unsigned_int_to_slv(8, 5);
    signal CompressorRatio      : std_logic_vector(5 downto 0) := "001000";
    signal CompressorMakeUpGain : std_logic_vector(3 downto 0) := unsigned_int_to_slv(0, 4);
    
    signal DEBUG_COUNTER        : std_logic_vector(19 downto 0);
    
    
    begin
    
    LED(0) <= EnableSoftClipper;
    LED(2 downto 1) <= (others=>'1');
    Init <= Btn(1);
    ResetIn <= not Btn(0);
    nResetIn <= not Btn(5);
    AudRst <= nResetIn;
    
    EnableSoftClipper <= Sw(0);
    EnableDistortion <= Sw(1);
    EnableCompressor <= Sw(2);
    
    gen_debouncers : for i in 1 to 5 generate
    
        debouncer : entity work.Debouncer
            generic map (
                COUNTER_WIDTH   => 10       --: positive := 4
            )
            port map (
                Clk             => BitClk,      --: in  std_logic;
                Reset           => Reset,       --: in  std_logic;
                
                KeyIn           => Btn(i),      --: in  std_logic;
                KeyOut          => PushBtn(i),  --: out std_logic;
                
                Press           => Press(i),    --: out std_logic;
                Release         => Release(i)   --: out std_logic 
            );
                
    end generate gen_debouncers;
    
    process (BitClk)
        begin
        if (rising_edge(BitClk)) then
            --if (Press(4) = '1') then
            --    Threshold  <= increment(Threshold, 5000);
            --elsif (Press(2) = '1') then
            --    Threshold  <= decrement(Threshold, 5000);
            --end if;
            if (Press(4) = '1') then
                CompressorThreshold <= increment(CompressorThreshold);
            elsif (Press(2) = '1') then
                CompressorThreshold <= decrement(CompressorThreshold);
            end if;
            Led(7 downto 3) <= CompressorThreshold;
        end if;
    end process;
    
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
            Ready               => open,                --: out std_logic;
            
            SDataIn             => AudSDI,              --: in  std_logic;
            SDataOut            => AudSDO,              --: out std_logic;
            
            Sync                => AudSync,             --: out std_logic;
            
            AudioInFIFOWr       => AudioInFIFOWr,       --: out  std_logic;
            AudioInFIFOData     => AudioInFIFOWrData,   --: out  std_logic_vector(19 downto 0);
            
            AudioOutFIFOEmpty   => AudioOutFIFOEmpty,   --: in  std_logic;
            AudioOutFIFORd      => AudioOutFIFORd,      --: out std_logic;
            AudioOutFIFOData    => AudioOutFIFORdData   --AudioOutFIFOData     --: in  std_logic_vector(19 downto 0)
        );

    process (Clk)
        begin
        if (rising_edge(Clk)) then
            if (AudioInFIFOEmpty = '0') then
                AudioInFIFORd <= '1';
            else
                AudioInFIFORd <= '0';
            end if;
            
            --AudioInValid <= AudioInFIFORd; -- TODO: debug
        end if;
    end process;
    AudioInValid <= AudioInFIFORd;
    audio_in_fifo : entity work.AsyncFIFO
        port map (
            rst     => Reset,               --: in std_logic;
            wr_clk  => BitClk,              --: in std_logic;
            rd_clk  => Clk,                 --: in std_logic;
            din     => AudioInFIFOWrData,   --: in std_logic_vector(19 downto 0);
            wr_en   => AudioInFIFOWr,       --: in std_logic;
            rd_en   => AudioInFIFORd,       --: in std_logic;
            dout    => AudioInFIFORdData,   --: out std_logic_vector(19 downto 0);
            full    => open,                --: out std_logic;
            empty   => AudioInFIFOEmpty     --: out std_logic
        );
        
    audio_out_fifo : entity work.AsyncFIFO
        port map (
            rst     => Reset,               --: in std_logic;
            wr_clk  => Clk,                 --: in std_logic;
            rd_clk  => BitClk,              --: in std_logic;
            din     => AudioOutFIFOWrData,  --: in std_logic_vector(19 downto 0);
            wr_en   => AudioOutFIFOWr,      --: in std_logic;
            rd_en   => AudioOutFIFORd,      --: in std_logic;
            dout    => AudioOutFIFORdData,  --: out std_logic_vector(19 downto 0);
            full    => open,                --: out std_logic;
            empty   => AudioOutFIFOEmpty    --: out std_logic
        );
        
    soft_clipper : entity work.SoftClipper
        port map (
            Clk             => Clk,                 --: in  std_logic;

            Enable          => EnableSoftClipper,   --: in  std_logic;

            Threshold       => Threshold,           --: in  std_logic_vector(17 downto 0);
            Coefficient     => Coefficient,         --: in  std_logic_vector(3 downto 0);

            AudioIn         => AudioInFIFORdData(19 downto 2),   --: in  std_logic_vector(17 downto 0);
            AudioInValid    => AudioInValid,        --: in  std_logic;

            AudioOut        => SoftClipperOut,      --: out std_logic_vector(17 downto 0);
            AudioOutValid   => SoftClipperOutValid  --: out std_logic
        );
    
    distortion : entity work.SoftClipper
        port map (
            Clk             => Clk,                 --: in  std_logic;

            Enable          => EnableDistortion,    --: in  std_logic;

            Threshold       => Threshold,           --: in  std_logic_vector(17 downto 0);
            Coefficient     => "00000001",          --: in  std_logic_vector(3 downto 0);

            AudioIn         => SoftClipperOut,      --: in  std_logic_vector(17 downto 0);
            AudioInValid    => SoftClipperOutValid, --: in  std_logic;

            AudioOut        => DistortionOut,       --: out std_logic_vector(17 downto 0);
            AudioOutValid   => DistortionOutValid   --: out std_logic
        );
        
    compressor : entity work.DynamicRangeCompressor
        port map (
            Clk             => Clk,                             --: in  std_logic;
            Reset           => Reset,                           --: in  std_logic;
            
            Enable          => EnableCompressor,                --: in  std_logic;

            AttackTime      => AttackTime,                      --: in  std_logic_vector(2 downto 0);
            ReleaseTime     => ReleaseTime,                     --: in  std_logic_vector(2 downto 0);
            Threshold       => CompressorThreshold,             --: in  std_logic_vector(4 downto 0);
            Ratio           => CompressorRatio,                 --: in  std_logic_vector(5 downto 0);
            MakeUpGain      => CompressorMakeUpGain,            --: in  std_logic_vector(3 downto 0);

            AudioIn         => DistortionOut,                   --: in  std_logic_vector(17 downto 0);
            AudioInValid    => DistortionOutValid,              --: in  std_logic;

            AudioOut        => AudioOutFIFOWrData(19 downto 2), --: out std_logic_vector(17 downto 0);
            AudioOutValid   => AudioOutFIFOWr                   --: out std_logic 
        );
        
    AudioOutFIFOWrData(1 downto 0) <= (others=>'0');    -- TODO: temp, fix
    
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


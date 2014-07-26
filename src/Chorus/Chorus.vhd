--  Chorus Effect
--
--  Description: Chorus audio effect.
--
--  Notes: None.
--
--  Revision History:
--      Steven Okai     07/26/14    1) Initial revision.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GeneralFuncPkg.all;

entity Chorus is
    port (
        Clk             : in  std_logic;
        Reset           : in  std_logic;
        
        Enable          : in  std_logic;
        
        EffectLevel     : in  std_logic_vector(3 downto 0);
        NumVoices       : in  std_logic_vector(1 downto 0);
        Width           : in  std_logic_vector(7 downto 0);
        Rate            : in  std_logic_vector(1 downto 0);
        Delay           : in  std_logic_vector(10 downto 0);
        
        AudioIn         : in  std_logic_vector(17 downto 0);
        AudioInValid    : in  std_logic;
        
        AudioOut        : out std_logic_vector(17 downto 0);
        AudioOutValid   : out std_logic
    );
end Chorus;

architecture rtl of Chorus is

    signal VariableDelay    : std_logic_vector(8 downto 0);
    signal WidthBySine      : std_logic_vector(13 downto 0);
    
    signal AudioDelay       : slv_18_vector(0 to 4);
    
    signal AudioP           : slv_18_vector(0 to 1);
    signal AudioValidP      : std_logic_vector(0 to 1);
    
    signal SineOut          : std_logic_vector(15 downto 0);
    
    signal AudioDelaySum12  : std_logic_vector(19 downto 0);
    signal AudioDelaySum34  : std_logic_vector(19 downto 0);
    signal AudioDelaySum    : std_logic_vector(17 downto 0);
    begin
    
    AudioDelay(0) <= shift_right_logical(AudioP(0), slv_to_unsigned_int(EffectLevel));  -- TODO: fix this so gain increases with increasing EffectLevel
    AudioValidP(0) <= AudioInValid;
    AudioP(0) <= AudioIn;
    
    AudioOut <= AudioP(1);
    AudioOutValid <= AudioValidP(1);
    
    gen_dynamic_delay : for i in 0 to 3 generate
        dynamic_delay : entity work.DynamicBRAMDelayLine
            generic map (
                MAX_DEPTH   => 512, --: positive;
                WIDTH       => 18   --: positive
            )
            port map (
                Clk         => Clk,             --: in  std_logic;
                Enable      => AudioValidP(0),  --: in  std_logic;
                
                Delay       => VariableDelay,   --: in  std_logic_vector(log2(MAX_DEPTH)-1 downto 0);
                DataIn      => AudioDelay(i),   --: in  std_logic_vector(WIDTH-1 downto 0);
                DataOut     => AudioDelay(i+1)  --: out std_logic_vector(WIDTH-1 downto 0)
            );
    end generate gen_dynamic_delay;
    
    process (Clk)
        variable TempVariableDelay  : std_logic_vector(9 downto 0);
        variable TempWidthBySine    : std_logic_vector(8 downto 0);
        begin
        
        AudioValidP(1) <= AudioValidP(0);
        
        -- Decide how many voices to add in.
        case slv_to_unsigned_int(NumVoices) is
            when 0 =>
                AudioDelaySum12 <= (others=>'0');
                AudioDelaySum34 <= sign_extend(AudioDelay(4), AudioDelaySum34'length);
            when 1 =>
                AudioDelaySum12 <= sign_extend(AudioDelay(2), AudioDelaySum12'length);
                AudioDelaySum34 <= sign_extend(AudioDelay(4), AudioDelaySum34'length);
            when others =>
                AudioDelaySum12 <= std_logic_vector(signed(sign_extend(AudioDelay(1), AudioDelaySum12'length)) + signed(sign_extend(AudioDelay(2), AudioDelaySum12'length)));
                AudioDelaySum34 <= std_logic_vector(signed(sign_extend(AudioDelay(3), AudioDelaySum34'length)) + signed(sign_extend(AudioDelay(4), AudioDelaySum34'length)));
        end case;

        -- Sum of all chorus voices.
        AudioDelaySum <= trunc_right(std_logic_vector(signed(AudioDelaySum12) + signed(AudioDelaySum34)), AudioDelaySum'length);   -- Div by 4 (shift right 4);
        
        if (Enable = '1') then
            -- Audio out is sum of dry signal and chorus voices.
            AudioP(1) <= std_logic_vector(signed(AudioP(0)) + signed(AudioDelaySum));
        else
            AudioP(1) <= AudioP(0);
        end if;
        
        TempWidthBySine := trunc_right(std_logic_vector(signed('0' & Width) * signed(SineOut)), Width'length+1);
        WidthBySine <= sign_extend(TempWidthBySine, WidthBySine'length);
        TempVariableDelay := trunc_right(std_logic_vector(signed(WidthBySine) + signed(pad_left(Delay, WidthBySine'length, '0'))), TempVariableDelay'length);   -- Div by 4 (shift right 4);
        VariableDelay <= trunc_left(TempVariableDelay, VariableDelay'length);   -- Remove sign bit, delay must be positive.
    end process;
    
    lfo : entity work.DirectDigitalSynthesizer
        generic map (
            PERIOD_SIZE     => 8192,    --: positive := 4096;
            TABLE_SIZE      => 1024,    --: positive := 1024;
            OUTPUT_WIDTH    => 16       --: positive := 32
        )
        port map (
            Clk             => Clk,             --: in  std_logic;
            Reset           => Reset,           --: in  std_logic;
            Enable          => AudioValidP(0),  --: in  std_logic;
            
            FreqScaling     => Rate,            --: in  std_logic_vector(log2(PERIOD_SIZE/(TABLE_SIZE*2))-1 downto 0);
        
            WaveOut         => SineOut,         --: out std_logic_vector(OUTPUT_WIDTH-1 downto 0);
            WaveOutValid    => open             --: out std_logic
        );
        
end rtl;

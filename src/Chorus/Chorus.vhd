--  Chorus Effect
--
--  Description: Chorus audio effect.
--
--  Notes: None.
--
--  Revision History:
--      Steven Okai     07/26/14    1) Initial revision.
--      Steven Okai     08/23/14    1) Updated to use command bus.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GeneralFuncPkg.all;
use work.CommandBusPkg.all;

entity Chorus is
    port (
        Clk             : in  std_logic;
        Reset           : in  std_logic;
        
        CmdBusIn        : in  cmd_bus_in;
        CmdBusOut       : out cmd_bus_out;
        
        AudioIn         : in  std_logic_vector(17 downto 0);
        AudioInValid    : in  std_logic;
        
        AudioOut        : out std_logic_vector(17 downto 0);
        AudioOutValid   : out std_logic
    );
end Chorus;

architecture rtl of Chorus is

    -- Memory map.
    constant ADDR_ENABLE        : natural : 0;
    constant ADDR_EFFECT_LEVEL  : natural : 1;
    constant ADDR_NUM_VOICES    : natural : 2;
    constant ADDR_WIDTH         : natural : 3;
    constant ADDR_RATE          : natural : 4;
    constant ADDR_DELAY         : natural : 5;

    signal VariableDelay    : std_logic_vector(8 downto 0);
    signal WidthBySine      : std_logic_vector(13 downto 0);
    
    signal AudioDelay       : slv_18_vector(0 to 4);
    
    signal AudioP           : slv_18_vector(0 to 1);
    signal AudioValidP      : std_logic_vector(0 to 1);
    
    signal SineOut          : std_logic_vector(15 downto 0);
    
    signal AudioDelaySum12  : std_logic_vector(19 downto 0);
    signal AudioDelaySum34  : std_logic_vector(19 downto 0);
    signal AudioDelaySum    : std_logic_vector(17 downto 0);
    
    signal Registers            : slv_32_vector(0 to 5);
    alias Enable                : std_logic is Registers(ADDR_EFFECT_LEVEL)(0);
    alias EffectLevel           : std_logic_vector(3 downto 0) is Registers(ADDR_EFFECT_LEVEL)(3 downto 0);
    alias NumVoices             : std_logic_vector(1 downto 0) is Registers(ADDR_NUM_VOICES)(1 downto 0);
    alias Width                 : std_logic_vector(7 downto 0) is Registers(ADDR_WIDTH)(7 downto 0);
    alias Rate                  : std_logic_vector(1 downto 0) is Registers(ADDR_RATE)(1 downto 0);
    alias Delay                 : std_logic_vector(10 downto 0) is Registers(ADDR_DELAY)(10 downto 0);
    constant REG_MASKS          : slv_32_vector(0 to 4) := (
        ADDR_ENABLE         => (0 => '1', others => '0'),
        ADDR_EFFECT_LEVEL   => (EffectLevel'range => '1', others => '0'),
        ADDR_NUM_VOICES     => (NumVoices'range => '1', others => '0'),
        ADDR_WIDTH          => (Width'range => '1', others => '0'),
        ADDR_RATE           => (Rate'range => '1', others => '0'),
        ADDR_DELAY          => (Delay'range => '1', others => '0')
    );
    
    signal WriteP               : std_logic_vector(1 to CMD_ACK_DELAY);
    signal WriteEdge            : std_logic;
    signal AckP                 : std_logic_vector(1 to CMD_ACK_DELAY);
    
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
        
    regs : process (Clk)
        variable CmdAddr    : std_logic_vector(log2(Registers)+2-1 downto 2);
        begin
        if (rising_edge(Clk)) then
        
            -- Edge detect the write pulse
            WriteP <= CmdBusIn.Write & WriteP(WriteP'low to WriteP'high-1);
            WriteEdge <= WriteP(WriteP'high-1) and (not WriteP(WriteP'high));  -- TODO: Do I need to delay this more for a multicycle path??? Probably...otherwise this possibly gets there before address?
            
            AckP <= (CmdBusIn.Write or CmdBusIn.Read) & AckP(AckP'low to AckP'high-1);
            CmdBusOut.Ack <= AckP(AckP'high); -- TODO: can this be tied directly to Ack instead of one last register?

            CmdAddr := CmdBusIn.Address(CmdAddr'range);
            -- TODO: add mask so unused bits get synthed out.
            CmdBusOut.Data(31 downto 0) <= Registers(slv_to_unsigned_int(CmdAddr)) and REG_MASKS(slv_to_unsigned_int(CmdAddr));  -- TODO: Should this even be registered?
            
            -- TODO: pad data out????
            if (WriteEdge = '1') then
                Registers(slv_to_unsigned_int(CmdAddr)) <= CmdBusIn.Data(31 downto 0) and REG_MASKS(slv_to_unsigned_int(CmdAddr));
            end if;
 
        end if;
    end process regs;
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_duckhunt is
    Port (
        CLK100MHZ : in  STD_LOGIC;
        BTNC      : in  STD_LOGIC;  -- Reset/Restart
        BTNR      : in  STD_LOGIC;  -- Manual shoot (backup)
        PS2_CLK   : in  STD_LOGIC;
        PS2_DATA  : in  STD_LOGIC;
        LED       : out STD_LOGIC_VECTOR(15 downto 0);
        VGA_R     : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G     : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B     : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_HS    : out STD_LOGIC;
        VGA_VS    : out STD_LOGIC
    );
end top_duckhunt;

architecture Behavioral of top_duckhunt is

    -- Component declarations
    component vga_640x480 is
        port (
            clk25   : in  std_logic;
            rst     : in  std_logic;
            hsync   : out std_logic;
            vsync   : out std_logic;
            video_on: out std_logic;
            pixel_x : out unsigned(9 downto 0);
            pixel_y : out unsigned(8 downto 0)
        );
    end component;

    component ps2_mouse is
        port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            ps2_clk : in  std_logic;
            ps2_data: in  std_logic;
            dx      : out signed(7 downto 0);
            dy      : out signed(7 downto 0);
            left_btn: out std_logic;
            new_packet : out std_logic
        );
    end component;

    -- Clock signals
    signal clk25      : std_logic := '0';
    signal clk_counter: unsigned(1 downto 0) := (others => '0');
    
    -- Reset
    signal rst        : std_logic;
    signal rst_sync   : std_logic_vector(2 downto 0) := (others => '0');
    
    -- VGA signals
    signal video_on   : std_logic;
    signal pixel_x    : unsigned(9 downto 0);
    signal pixel_y    : unsigned(8 downto 0);
    
    -- Mouse signals
    signal mouse_dx   : signed(7 downto 0);
    signal mouse_dy   : signed(7 downto 0);
    signal mouse_left : std_logic;
    signal mouse_pkt  : std_logic;
    signal mouse_left_prev : std_logic := '0';
    
    -- Cursor position
    signal cursor_x   : unsigned(9 downto 0) := to_unsigned(320, 10);
    signal cursor_y   : unsigned(8 downto 0) := to_unsigned(240, 9);
    
    -- Duck signals
    signal duck_x     : integer range -32 to 672 := 0;
    signal duck_y     : integer range 0 to 479 := 100;
    signal duck_vx    : integer range -10 to 10 := 3;
    signal duck_vy    : integer range -5 to 5 := 1;
    signal duck_alive : std_logic := '1';
    constant DUCK_SIZE : integer := 20;
    
    -- Game state
    type game_state_t is (PLAYING, GAME_OVER);
    signal game_state : game_state_t := PLAYING;
    
    -- Score and lives
    signal score      : unsigned(7 downto 0) := (others => '0');
    signal lives      : unsigned(1 downto 0) := "11"; -- 3 lives
    signal shoot_pulse: std_logic := '0';
    
    -- Timers
    signal tick_counter: unsigned(23 downto 0) := (others => '0');
    signal move_tick  : std_logic := '0';
    signal respawn_counter: integer range 0 to 180 := 0;
    signal offscreen_counter: integer range 0 to 60 := 0;
    
    -- LFSR for randomness
    signal lfsr : std_logic_vector(15 downto 0) := x"ACE1";
    
    -- Display signals
    constant CURSOR_SIZE : integer := 10;
    signal draw_cursor   : std_logic;
    signal draw_duck     : std_logic;
    signal draw_lives    : std_logic;
    signal draw_score_digit : std_logic;
    signal draw_gameover : std_logic;
    
    -- Speed level
    signal speed_level : integer range 1 to 8 := 1;
    signal hits_for_speedup : integer range 0 to 4 := 0;

begin

    ----------------------------------------------------------------
    -- CLOCK GENERATION
    ----------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            clk_counter <= clk_counter + 1;
            if clk_counter = 1 then
                clk25 <= not clk25;
                clk_counter <= (others => '0');
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- RESET SYNCHRONIZER
    ----------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            rst_sync <= rst_sync(1 downto 0) & BTNC;
        end if;
    end process;
    rst <= rst_sync(2);

    ----------------------------------------------------------------
    -- VGA CONTROLLER
    ----------------------------------------------------------------
    vga_inst: vga_640x480
        port map (
            clk25    => clk25,
            rst      => rst,
            hsync    => VGA_HS,
            vsync    => VGA_VS,
            video_on => video_on,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y
        );

    ----------------------------------------------------------------
    -- PS2 MOUSE CONTROLLER
    ----------------------------------------------------------------
    mouse_inst: ps2_mouse
        port map (
            clk        => CLK100MHZ,
            rst        => rst,
            ps2_clk    => PS2_CLK,
            ps2_data   => PS2_DATA,
            dx         => mouse_dx,
            dy         => mouse_dy,
            left_btn   => mouse_left,
            new_packet => mouse_pkt
        );

    ----------------------------------------------------------------
    -- CURSOR CONTROLLER
    ----------------------------------------------------------------
    process(CLK100MHZ)
        variable new_x : signed(10 downto 0);
        variable new_y : signed(9 downto 0);
    begin
        if rising_edge(CLK100MHZ) then
            if rst = '1' then
                cursor_x <= to_unsigned(320, 10);
                cursor_y <= to_unsigned(240, 9);
            elsif mouse_pkt = '1' then
                -- Update X
                new_x := signed('0' & cursor_x) + resize(mouse_dx, 11);
                if new_x < 0 then
                    cursor_x <= (others => '0');
                elsif new_x > 639 then
                    cursor_x <= to_unsigned(639, 10);
                else
                    cursor_x <= unsigned(new_x(9 downto 0));
                end if;
                
                -- Update Y (inverted)
                new_y := signed('0' & cursor_y) - resize(mouse_dy, 10);
                if new_y < 0 then
                    cursor_y <= (others => '0');
                elsif new_y > 479 then
                    cursor_y <= to_unsigned(479, 9);
                else
                    cursor_y <= unsigned(new_y(8 downto 0));
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- SHOOT PULSE GENERATOR
    ----------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            mouse_left_prev <= mouse_left;
            if (mouse_left = '1' and mouse_left_prev = '0') or BTNR = '1' then
                shoot_pulse <= '1';
            else
                shoot_pulse <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- LFSR (Random Number Generator)
    ----------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            lfsr <= lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
        end if;
    end process;

    ----------------------------------------------------------------
    -- MOVEMENT TICK (~60 Hz)
    ----------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            tick_counter <= tick_counter + 1;
            if tick_counter = 1666666 then
                move_tick <= '1';
                tick_counter <= (others => '0');
            else
                move_tick <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- GAME LOGIC
    ----------------------------------------------------------------
    process(CLK100MHZ)
        variable cx, cy : integer;
        variable hit : boolean;
    begin
        if rising_edge(CLK100MHZ) then
            if rst = '1' then
                -- Reset game
                game_state <= PLAYING;
                score <= (others => '0');
                lives <= "11"; -- 3 lives
                duck_alive <= '1';
                duck_x <= 0;
                duck_y <= 100;
                duck_vx <= 3;
                duck_vy <= 1;
                speed_level <= 1;
                hits_for_speedup <= 0;
                respawn_counter <= 0;
                offscreen_counter <= 0;
                
            elsif move_tick = '1' then
                case game_state is
                    when PLAYING =>
                        if duck_alive = '1' then
                            -- Move duck
                            duck_x <= duck_x + duck_vx;
                            duck_y <= duck_y + duck_vy;
                            
                            -- Vertical bounce
                            if duck_y < 20 then 
                                duck_vy <= abs(duck_vy);
                            elsif duck_y > 460 then 
                                duck_vy <= -abs(duck_vy);
                            end if;
                            
                            -- Check if duck goes offscreen
                            if duck_x < -DUCK_SIZE or duck_x > 640 then
                                offscreen_counter <= offscreen_counter + 1;
                                if offscreen_counter >= 30 then -- Half second
                                    -- Duck escaped! Lose a life
                                    if lives > 0 then
                                        lives <= lives - 1;
                                    end if;
                                    
                                    if lives = 1 then -- Will become 0
                                        game_state <= GAME_OVER;
                                    else
                                        -- Respawn duck
                                        duck_alive <= '1';
                                        if lfsr(0) = '0' then
                                            duck_x <= -DUCK_SIZE;
                                            duck_vx <= (1 + speed_level);
                                        else
                                            duck_x <= 640;
                                            duck_vx <= -(1 + speed_level);
                                        end if;
                                        duck_y <= to_integer(unsigned(lfsr(8 downto 1))) mod 400 + 40;
                                        duck_vy <= to_integer(signed(lfsr(3 downto 1))) - 3;
                                    end if;
                                    offscreen_counter <= 0;
                                end if;
                            else
                                offscreen_counter <= 0;
                            end if;
                            
                        else
                            -- Duck is dead, respawn after delay
                            if respawn_counter < 60 then
                                respawn_counter <= respawn_counter + 1;
                            else
                                duck_alive <= '1';
                                respawn_counter <= 0;
                                
                                -- Random spawn
                                if lfsr(0) = '0' then
                                    duck_x <= -DUCK_SIZE;
                                    duck_vx <= (1 + speed_level);
                                else
                                    duck_x <= 640;
                                    duck_vx <= -(1 + speed_level);
                                end if;
                                duck_y <= to_integer(unsigned(lfsr(8 downto 1))) mod 400 + 40;
                                duck_vy <= to_integer(signed(lfsr(3 downto 1))) - 3;
                            end if;
                        end if;
                        
                    when GAME_OVER =>
                        -- Stay in game over until reset
                        null;
                end case;
            end if;
            
            -- Hit detection
            if shoot_pulse = '1' and game_state = PLAYING and duck_alive = '1' then
                cx := to_integer(cursor_x);
                cy := to_integer(cursor_y);
                hit := false;
                
                if cx >= duck_x and cx < duck_x + DUCK_SIZE and
                   cy >= duck_y and cy < duck_y + DUCK_SIZE then
                    hit := true;
                end if;
                
                if hit then
                    -- Hit!
                    duck_alive <= '0';
                    score <= score + 1;
                    respawn_counter <= 0;
                    
                    -- Increase difficulty
                    hits_for_speedup <= hits_for_speedup + 1;
                    if hits_for_speedup >= 2 and speed_level < 8 then
                        speed_level <= speed_level + 1;
                        hits_for_speedup <= 0;
                    end if;
                else
                    -- Miss! Lose a life
                    if lives > 0 then
                        lives <= lives - 1;
                    end if;
                    
                    if lives = 1 then -- Will become 0
                        game_state <= GAME_OVER;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- LED display: Score on lower 8 bits, Lives on bits 9-10
    LED <= "00000" & std_logic_vector(lives) & "0" & std_logic_vector(score);

    ----------------------------------------------------------------
    -- DRAWING LOGIC
    ----------------------------------------------------------------
    -- Draw cursor (crosshair)
    draw_cursor <= '1' when (
        (to_integer(pixel_x) >= to_integer(cursor_x) - CURSOR_SIZE and 
         to_integer(pixel_x) <= to_integer(cursor_x) + CURSOR_SIZE and
         to_integer(pixel_y) = to_integer(cursor_y)) or
        (to_integer(pixel_y) >= to_integer(cursor_y) - CURSOR_SIZE and 
         to_integer(pixel_y) <= to_integer(cursor_y) + CURSOR_SIZE and
         to_integer(pixel_x) = to_integer(cursor_x))
    ) else '0';

    -- Draw duck
    draw_duck <= '1' when (
        duck_alive = '1' and
        to_integer(pixel_x) >= duck_x and
        to_integer(pixel_x) < duck_x + DUCK_SIZE and
        to_integer(pixel_y) >= duck_y and
        to_integer(pixel_y) < duck_y + DUCK_SIZE
    ) else '0';

    -- Draw lives (hearts at top-left)
    draw_lives <= '1' when (
        pixel_y < 20 and (
            (lives >= 1 and pixel_x >= 10 and pixel_x < 30) or
            (lives >= 2 and pixel_x >= 35 and pixel_x < 55) or
            (lives >= 3 and pixel_x >= 60 and pixel_x < 80)
        )
    ) else '0';

    -- Draw score digits (top-right, simple blocks for each point)
    draw_score_digit <= '1' when (
        pixel_y < 15 and 
        pixel_x >= 600 and 
        pixel_x < 600 + to_integer(score) * 4 and
        to_integer(score) > 0
    ) else '0';

    -- Draw GAME OVER (big red text area)
    draw_gameover <= '1' when (
        game_state = GAME_OVER and
        pixel_y >= 200 and pixel_y < 280 and
        pixel_x >= 200 and pixel_x < 440
    ) else '0';

    ----------------------------------------------------------------
    -- VGA COLOR OUTPUT
    ----------------------------------------------------------------
    process(video_on, game_state, draw_cursor, draw_duck, draw_lives, 
            draw_score_digit, draw_gameover)
    begin
        if video_on = '1' then
            if game_state = GAME_OVER then
                -- Game Over screen
                if draw_gameover = '1' then
                    -- Red GAME OVER box
                    VGA_R <= "1111";
                    VGA_G <= "0000";
                    VGA_B <= "0000";
                elsif draw_cursor = '1' then
                    VGA_R <= "1111";
                    VGA_G <= "1111";
                    VGA_B <= "1111";
                else
                    -- Dark background
                    VGA_R <= "0001";
                    VGA_G <= "0001";
                    VGA_B <= "0001";
                end if;
            else
                -- Playing state
                if draw_cursor = '1' then
                    -- White crosshair
                    VGA_R <= "1111";
                    VGA_G <= "1111";
                    VGA_B <= "1111";
                elsif draw_duck = '1' then
                    -- Yellow duck
                    VGA_R <= "1111";
                    VGA_G <= "1100";
                    VGA_B <= "0000";
                elsif draw_lives = '1' then
                    -- Red hearts
                    VGA_R <= "1111";
                    VGA_G <= "0000";
                    VGA_B <= "0000";
                elsif draw_score_digit = '1' then
                    -- Green score bar
                    VGA_R <= "0000";
                    VGA_G <= "1111";
                    VGA_B <= "0000";
                else
                    -- Sky blue background
                    VGA_R <= "0101";
                    VGA_G <= "1000";
                    VGA_B <= "1111";
                end if;
            end if;
        else
            VGA_R <= "0000";
            VGA_G <= "0000";
            VGA_B <= "0000";
        end if;
    end process;

end Behavioral;

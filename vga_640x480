library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_640x480 is
    port (
        clk25   : in  std_logic;  -- 25 MHz pixel clock
        rst     : in  std_logic;
        hsync   : out std_logic;
        vsync   : out std_logic;
        video_on: out std_logic;
        pixel_x : out unsigned(9 downto 0); -- 0..639
        pixel_y : out unsigned(8 downto 0)  -- 0..479
    );
end entity;

architecture rtl of vga_640x480 is
    constant H_ACTIVE : integer := 640;
    constant H_FP     : integer := 16;
    constant H_PULSE  : integer := 96;
    constant H_BP     : integer := 48;
    constant H_TOTAL  : integer := H_ACTIVE + H_FP + H_PULSE + H_BP; -- 800

    constant V_ACTIVE : integer := 480;
    constant V_FP     : integer := 10;
    constant V_PULSE  : integer := 2;
    constant V_BP     : integer := 33;
    constant V_TOTAL  : integer := V_ACTIVE + V_FP + V_PULSE + V_BP; -- 525

    signal hcount : integer range 0 to H_TOTAL-1 := 0;
    signal vcount : integer range 0 to V_TOTAL-1 := 0;
begin
    process(clk25)
    begin
        if rising_edge(clk25) then
            if rst = '1' then
                hcount <= 0;
                vcount <= 0;
            else
                if hcount = H_TOTAL-1 then
                    hcount <= 0;
                    if vcount = V_TOTAL-1 then
                        vcount <= 0;
                    else
                        vcount <= vcount + 1;
                    end if;
                else
                    hcount <= hcount + 1;
                end if;
            end if;
        end if;
    end process;

    hsync <= '0' when (hcount >= H_ACTIVE + H_FP and hcount < H_ACTIVE + H_FP + H_PULSE) else '1';
    vsync <= '0' when (vcount >= V_ACTIVE + V_FP and vcount < V_ACTIVE + V_FP + V_PULSE) else '1';

    video_on <= '1' when (hcount < H_ACTIVE and vcount < V_ACTIVE) else '0';

    pixel_x <= to_unsigned(hcount, pixel_x'length);
    pixel_y <= to_unsigned(vcount, pixel_y'length);

end architecture;

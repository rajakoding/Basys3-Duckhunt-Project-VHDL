library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ps2_mouse is
    port (
        clk     : in  std_logic;  -- system clock (e.g., 100 MHz)
        rst     : in  std_logic;
        ps2_clk : in  std_logic;  -- from PIC24 -> FPGA
        ps2_data: in  std_logic;
        -- outputs
        dx      : out signed(7 downto 0);
        dy      : out signed(7 downto 0);
        left_btn: out std_logic;
        new_packet : out std_logic  -- pulse when new 3-byte packet available
    );
end entity;

architecture rtl of ps2_mouse is
    signal ps2_clk_sync : std_logic_vector(2 downto 0) := (others => '1');
    signal ps2_data_sync: std_logic_vector(2 downto 0) := (others => '1');

    -- shift logic
    signal bitcount : integer range 0 to 10 := 0;
    signal shiftreg : std_logic_vector(10 downto 0) := (others => '1');
    signal byte_ready : std_logic := '0';
    signal byte_data  : std_logic_vector(7 downto 0) := (others => '0');

    -- packet assembly
    type pkt_state_type is (WAIT_BYTE1, WAIT_BYTE2, WAIT_BYTE3);
    signal pkt_state : pkt_state_type := WAIT_BYTE1;
    signal b1, b2, b3 : std_logic_vector(7 downto 0) := (others => '0');

    -- detect falling edge of ps2_clk
    signal ps2_clk_prev : std_logic := '1';
begin
    -- synchronize inputs to clk domain
    process(clk)
    begin
        if rising_edge(clk) then
            ps2_clk_sync <= ps2_clk_sync(1 downto 0) & ps2_clk;
            ps2_data_sync<= ps2_data_sync(1 downto 0) & ps2_data;
            ps2_clk_prev <= ps2_clk_sync(2);
        end if;
    end process;

    -- sampling on falling edge of PS2 clock (synchronized)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bitcount <= 0;
                shiftreg <= (others => '1');
                byte_ready <= '0';
            else
                byte_ready <= '0';
                -- falling edge detect of ps2_clk in sync domain
                if ps2_clk_sync(2) = '0' and ps2_clk_prev = '1' then
                    -- shift in data bit (LSB first)
                    shiftreg <= ps2_data_sync(2) & shiftreg(10 downto 1);
                    if bitcount = 10 then
                        -- full frame received (start,data(8),parity,stop)
                        -- extract data bits [8..1] are at shiftreg(8 downto 1)
                        byte_data <= shiftreg(8 downto 1);
                        byte_ready <= '1';
                        bitcount <= 0;
                    else
                        bitcount <= bitcount + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- assemble packets of 3 bytes
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pkt_state <= WAIT_BYTE1;
                b1 <= (others => '0'); b2 <= (others => '0'); b3 <= (others => '0');
                dx <= (others => '0'); dy <= (others => '0');
                left_btn <= '0';
                new_packet <= '0';
            else
                new_packet <= '0';
                if byte_ready = '1' then
                    case pkt_state is
                        when WAIT_BYTE1 =>
                            b1 <= byte_data;
                            pkt_state <= WAIT_BYTE2;
                        when WAIT_BYTE2 =>
                            b2 <= byte_data;
                            pkt_state <= WAIT_BYTE3;
                        when WAIT_BYTE3 =>
                            b3 <= byte_data;
                            -- produce outputs
                            -- b1 bits: [7:0] => Yov Xov Ysign Xsign 1 MB RB LB
                            left_btn <= b1(0);
                            -- dx,dy are 8-bit signed deltas (b2,b3)
                            dx <= signed(b2);
                            dy <= signed(b3);
                            new_packet <= '1';
                            pkt_state <= WAIT_BYTE1;
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;

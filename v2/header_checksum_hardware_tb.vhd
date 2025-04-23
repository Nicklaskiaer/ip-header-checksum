-------------------------------------------------------------------------------
--  Title   : HW test‑bench for header_checksum on Terasic DE10‑Standard board
--  Author  : ChatGPT (OpenAI o3)
--  Date    : 23‑Apr‑2025
--
--  Description :
--  * Push KEY0 once → sends a **good** IPv4 header (checksum should pass).
--  * Push KEY0 again → sends a **bad**  IPv4 header (checksum should fail).
--  * Hold KEY1      → synchronous reset (KEYs are active‑low on DE10).
--
--  Visual feedback on the 10 red LEDs (LEDR0‑9):
--      LEDR0        : current cksum_ok flag (lights when last packet OK)
--      LEDR4‑1      : ok‑packet counter  (bits 3‑0)
--      LEDR9‑5      : ko‑packet counter  (bits 4‑0)
--
--  This file is meant to be used as the **top‑level** for Quartus builds.
--  Pin assignments (excerpt, adjust to your board revision):
--      set_location_assignment PIN_AF14  -to CLOCK_50
--      set_location_assignment PIN_W26   -to KEY[0]   -- KEY0 (nSTART)
--      set_location_assignment PIN_Y26   -to KEY[1]   -- KEY1 (nRESET)
--      set_location_assignment PIN_U22   -to LEDR[0]
--      ... (continue for LEDR[9:1])
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hw_testbench_header_checksum is
    port(
        CLOCK_50 : in  std_logic;                        -- 50‑MHz system clock
        KEY      : in  std_logic_vector(1 downto 0);     -- KEY0=start, KEY1=reset (active‑low)
        LEDR     : out std_logic_vector(9 downto 0)      -- Red user LEDs
    );
end entity;

architecture rtl of hw_testbench_header_checksum is

    ---------------------------------------------------------------------------
    --  Component under test
    ---------------------------------------------------------------------------
    component header_checksum is
        port(
            clk           : in  std_logic;
            reset         : in  std_logic;               -- active‑high
            start_of_data : in  std_logic;
            data_in       : in  std_logic_vector(15 downto 0);
            cksum_calc    : out std_logic;
            cksum_ok      : out std_logic;
            cksum_ok_cnt  : out std_logic_vector(15 downto 0);
            cksum_ko_cnt  : out std_logic_vector(15 downto 0)
        );
    end component;

    ---------------------------------------------------------------------------
    --  Simple packet generator
    ---------------------------------------------------------------------------
    --  Good IPv4 header (20 bytes = 10 words) with zero checksum
    --  (Words are 16‑bit big‑endian, checksum pre‑computed to 0)
    constant GOOD_LEN : integer := 10;
    type word_array_t is array (0 to GOOD_LEN-1) of std_logic_vector(15 downto 0);
    constant GOOD_PKT : word_array_t := (
        x"4500", x"002C", x"1234", x"4000", x"4006", x"0000",  -- checksum word will be zero
        x"C0A8", x"0101",                                         -- 192.168.1.1
        x"C0A8", x"0102"                                          -- 192.168.1.2
    );

    --  BAD packet : identical but we flip one bit → checksum will not be zero
    constant BAD_LEN : integer := GOOD_LEN;
    constant BAD_PKT : word_array_t := (
        x"4501", x"002C", x"1234", x"4000", x"4006", x"0000",  -- first word differs (bit0 set)
        x"C0A8", x"0101",
        x"C0A8", x"0102"
    );

    ---------------------------------------------------------------------------
    --  Signals
    ---------------------------------------------------------------------------
    signal reset          : std_logic;                    -- active‑high
    signal key0_sync      : std_logic_vector(2 downto 0) := (others => '1');
    signal key0_rising    : std_logic;                    -- single‑cycle pulse on press

    signal send_good      : std_logic := '1';             -- toggles each press (start with good)
    signal sending        : std_logic := '0';             -- generator active flag
    signal word_cnt       : integer range 0 to GOOD_LEN := 0;

    signal start_of_data  : std_logic := '0';
    signal data_word      : std_logic_vector(15 downto 0) := (others => '0');

    --  DUT outputs
    signal cksum_calc     : std_logic;
    signal cksum_ok       : std_logic;
    signal ok_cnt, ko_cnt : std_logic_vector(15 downto 0);

    ---------------------------------------------------------------------------
    --  Clock divider (slow down traffic → ~2.5 MHz strobe)
    ---------------------------------------------------------------------------
    signal clk_div        : unsigned(4 downto 0) := (others => '0');
    signal tx_strobe      : std_logic;                    -- high for one SYSCLK every 32 cycles

begin

    ---------------------------------------------------------------------------
    --  Asynchronous reset (KEY1 low)
    ---------------------------------------------------------------------------
    reset <= not KEY(1);                                  -- KEY1 is active‑low

    ---------------------------------------------------------------------------
    --  Generate a 32‑cycle strobe for relaxed timing inside DUT
    ---------------------------------------------------------------------------
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset = '1' then
                clk_div  <= (others => '0');
            else
                clk_div  <= clk_div + 1;
            end if;
        end if;
    end process;
    tx_strobe <= '1' when clk_div = 0 else '0';

    ---------------------------------------------------------------------------
    --  Synchronise & edge‑detect KEY0 (start button)
    ---------------------------------------------------------------------------
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            key0_sync   <= key0_sync(1 downto 0) & KEY(0);
        end if;
    end process;
    key0_rising <= key0_sync(2) and not key0_sync(1);      -- high for one SYSCLK when pressed

    ---------------------------------------------------------------------------
    --  Packet generator state machine
    ---------------------------------------------------------------------------
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset = '1' then
                sending       <= '0';
                word_cnt      <= 0;
                start_of_data <= '0';
                data_word     <= (others => '0');
                send_good     <= '1';
            else
                ------------------------------------------------------------------
                --  Launch new transfer on KEY0 press (if not already sending)
                ------------------------------------------------------------------
                if key0_rising = '1' and sending = '0' then
                    sending   <= '1';
                    word_cnt  <= 0;
                    send_good <= not send_good;           -- toggle for next time
                end if;

                ------------------------------------------------------------------
                --  Drive data & strobe while sending
                ------------------------------------------------------------------
                if sending = '1' and tx_strobe = '1' then

                    start_of_data <= '1';                 -- valid for this SYSCLK

                    if send_good = '1' then
                        data_word <= GOOD_PKT(word_cnt);
                    else
                        data_word <= BAD_PKT(word_cnt);
                    end if;

                    if word_cnt = GOOD_LEN-1 then
                        sending  <= '0';                  -- done
                    end if;

                    word_cnt <= word_cnt + 1;

                else
                    start_of_data <= '0';                 -- idle
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    --  DUT instantiation
    ---------------------------------------------------------------------------
    dut: header_checksum
        port map(
            clk           => CLOCK_50,
            reset         => reset,
            start_of_data => start_of_data,
            data_in       => data_word,
            cksum_calc    => cksum_calc,
            cksum_ok      => cksum_ok,
            cksum_ok_cnt  => ok_cnt,
            cksum_ko_cnt  => ko_cnt
        );

    ---------------------------------------------------------------------------
    --  Map selected DUT outputs to on‑board LEDs
    ---------------------------------------------------------------------------
    LEDR(0)   <= cksum_ok;            -- last packet result
    LEDR(4 downto 1) <= ok_cnt(3 downto 0);
    LEDR(9 downto 5) <= ko_cnt(4 downto 0);

end architecture rtl;

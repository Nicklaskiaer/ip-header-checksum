-------------------------------------------------------------------------------
--  Title   : HW test-bench for header_checksum on Terasic DE10‑Standard board
--  Variant : 7‑segment version (replaces LEDs)
--  Author  : ChatGPT (OpenAI o3)
--  Date    : 23‑Apr‑2025
--
--  * KEY0 (active‑low)  → send packet (toggles GOOD/BAD).
--  * KEY1 (active‑low)  → global reset.
--
--  Six 7‑segment displays (HEX5..HEX0) show the 12‑bit OK / KO counters:
--     HEX2‑0  = OK‑count  (lowest 3 hex nibbles)
--     HEX5‑3  = KO‑count  (lowest 3 hex nibbles)
--  Each digit is active‑low (common‑anode) and shows 0‑F in hexadecimal.
--
--  Pin hints (adjust to your *.qsf):
--     set_location_assignment PIN_AF14  -to CLOCK_50      -- 50‑MHz clock
--     set_location_assignment PIN_W26   -to KEY[0]
--     set_location_assignment PIN_Y26   -to KEY[1]
--     # HEX0 example (segment a..g)
--     set_location_assignment PIN_W17   -to HEX0[0]
--     ...
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hw_testbench_header_checksum is
    port(
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0);            -- KEY0=start, KEY1=reset (both active‑low)
        HEX0     : out std_logic_vector(6 downto 0);
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0);
        HEX4     : out std_logic_vector(6 downto 0);
        HEX5     : out std_logic_vector(6 downto 0)
    );
end entity;

-------------------------------------------------------------------------------
architecture rtl of hw_testbench_header_checksum is
-------------------------------------------------------------------------------

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
    --  Hex‑digit → 7‑segment decoder (active‑low, g‑f‑e‑d‑c‑b‑a)
    ---------------------------------------------------------------------------
    function hex_to_7seg(nibble : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case nibble is
            when x"0" => seg := "1000000"; -- 0
            when x"1" => seg := "1111001"; -- 1
            when x"2" => seg := "0100100"; -- 2
            when x"3" => seg := "0110000"; -- 3
            when x"4" => seg := "0011001"; -- 4
            when x"5" => seg := "0010010"; -- 5
            when x"6" => seg := "0000010"; -- 6
            when x"7" => seg := "1111000"; -- 7
            when x"8" => seg := "0000000"; -- 8
            when x"9" => seg := "0010000"; -- 9
            when x"A" => seg := "0001000"; -- A
            when x"B" => seg := "0000011"; -- b
            when x"C" => seg := "1000110"; -- C
            when x"D" => seg := "0100001"; -- d
            when x"E" => seg := "0000110"; -- E
            when others=> seg := "0001110"; -- F (also default)
        end case;
        return seg;
    end function;

    ---------------------------------------------------------------------------
    --  Simple packet generator constants (same as LED version)
    ---------------------------------------------------------------------------
    constant WORDS : integer := 10;
    type word_arr  is array (0 to WORDS-1) of std_logic_vector(15 downto 0);

    constant GOOD_PKT : word_arr := (
        x"4500", x"002C", x"1234", x"4000", x"4006", x"0000",
        x"C0A8", x"0101", x"C0A8", x"0102"
    );

    constant BAD_PKT  : word_arr := (
        x"4501", x"002C", x"1234", x"4000", x"4006", x"0000",
        x"C0A8", x"0101", x"C0A8", x"0102"
    );

    ---------------------------------------------------------------------------
    --  Internal signals
    ---------------------------------------------------------------------------
    signal reset          : std_logic;                    -- active‑high
    signal key0_sync      : std_logic_vector(2 downto 0) := (others=>'1');
    signal key0_rise      : std_logic;

    signal send_good      : std_logic := '1';             -- toggles each press
    signal sending        : std_logic := '0';
    signal word_idx       : integer range 0 to WORDS := 0;

    signal start_of_data  : std_logic := '0';
    signal data_word      : std_logic_vector(15 downto 0) := (others=>'0');

    signal div_cnt        : unsigned(4 downto 0) := (others=>'0');
    signal tx_strobe      : std_logic;

    --  DUT outputs
    signal ok_cnt, ko_cnt : std_logic_vector(15 downto 0);
    signal cksum_ok, cksum_calc : std_logic;

begin
    ---------------------------------------------------------------------------
    --  Reset and key synchronisation
    ---------------------------------------------------------------------------
    reset <= not KEY(1);                                 -- KEY1 active‑low → active‑high reset

    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            key0_sync <= key0_sync(1 downto 0) & KEY(0);
        end if;
    end process;
    key0_rise <= key0_sync(2) and not key0_sync(1);

    ---------------------------------------------------------------------------
    --  Clock divider (÷32 → ~1.56 MHz strobe)
    ---------------------------------------------------------------------------
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset='1' then
                div_cnt <= (others=>'0');
            else
                div_cnt <= div_cnt + 1;
            end if;
        end if;
    end process;
    tx_strobe <= '1' when div_cnt=0 else '0';

    ---------------------------------------------------------------------------
    --  Packet generator FSM
    ---------------------------------------------------------------------------
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset='1' then
                sending       <= '0';
                word_idx      <= 0;
                start_of_data <= '0';
                data_word     <= (others=>'0');
                send_good     <= '1';
            else
                -- Launch on key press
                if key0_rise='1' and sending='0' then
                    sending   <= '1';
                    word_idx  <= 0;
                    send_good <= not send_good;
                end if;

                -- Drive DUT inputs while sending
                if sending='1' and tx_strobe='1' then
                    start_of_data <= '1';
                    if send_good='1' then
                        data_word <= GOOD_PKT(word_idx);
                    else
                        data_word <= BAD_PKT(word_idx);
                    end if;

                    if word_idx = WORDS-1 then
                        sending  <= '0';
                    end if;
                    word_idx <= word_idx + 1;
                else
                    start_of_data <= '0';
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
    --  Display lower 12 bits of counters on HEX5..HEX0 (active‑low)
    ---------------------------------------------------------------------------
    HEX0 <= hex_to_7seg(ok_cnt(3 downto 0));
    HEX1 <= hex_to_7seg(ok_cnt(7 downto 4));
    HEX2 <= hex_to_7seg(ok_cnt(11 downto 8));

    HEX3 <= hex_to_7seg(ko_cnt(3 downto 0));
    HEX4 <= hex_to_7seg(ko_cnt(7 downto 4));
    HEX5 <= hex_to_7seg(ko_cnt(11 downto 8));

end architecture rtl;

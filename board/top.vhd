library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        CLOCK_50 : in std_logic;
        KEY      : in std_logic_vector(1 downto 0);
        SW       : in std_logic_vector(9 downto 0);
        LEDR     : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of top is

    -- Signals for header_checksum entity
    signal reset          : std_logic;
    signal data_in        : std_logic_vector(7 downto 0);
    signal start_of_data  : std_logic;
    signal data_valid     : std_logic;
    signal cksum_calc     : std_logic;
    signal cksum_ok       : std_logic;
    signal cksum_ok_cnt   : std_logic_vector(15 downto 0);
    signal cksum_ko_cnt   : std_logic_vector(15 downto 0);

    -- Internal signals
    signal send_packet    : std_logic := '0';
    signal packet_counter : integer range 0 to 39 := 0; -- 20 bytes * 2 packets
    signal sending        : boolean := false;
    type packet_array is array (0 to 39) of std_logic_vector(7 downto 0);
    signal packets : packet_array := (
        -- Packet 1: Good packet (20 bytes)
        x"45", x"00", x"00", x"28", x"ab", x"cd", x"00", x"00", x"40", x"11",
        x"72", x"b8", x"c0", x"a8", x"01", x"02", x"c0", x"a8", x"01", x"01",
        -- Packet 2: Bad packet (TTL corrupted)
        x"45", x"00", x"00", x"28", x"ab", x"cd", x"00", x"00", x"41", x"11",
        x"72", x"b8", x"c0", x"a8", x"01", x"02", x"c0", x"a8", x"01", x"01"
    );

begin

    -- Map KEY buttons
    reset <= not KEY(0);        -- KEY0 = Reset (active low)
    send_packet <= not KEY(1);  -- KEY1 = Send packets (active low)

    -- Instance of your checksum unit
    uut: entity work.header_checksum
        port map (
            clk           => CLOCK_50,
            reset         => reset,
            data_in       => data_in,
            start_of_data => start_of_data,
            data_valid    => data_valid,
            cksum_calc    => cksum_calc,
            cksum_ok      => cksum_ok,
            cksum_ok_cnt  => cksum_ok_cnt,
            cksum_ko_cnt  => cksum_ko_cnt
        );

    -- Packet sending process
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset = '1' then
                packet_counter <= 0;
                sending <= false;
                data_valid <= '0';
                start_of_data <= '0';
            elsif send_packet = '1' and not sending then
                sending <= true;
                packet_counter <= 0;
            elsif sending then
                data_in <= packets(packet_counter);
                data_valid <= '1';
                if packet_counter = 0 or packet_counter = 20 then
                    start_of_data <= '1'; -- New packet start
                else
                    start_of_data <= '0';
                end if;
                packet_counter <= packet_counter + 1;
                if packet_counter = 40 then -- All packets sent
                    sending <= false;
                    data_valid <= '0';
                    start_of_data <= '0';
                end if;
            else
                data_valid <= '0';
                start_of_data <= '0';
            end if;
        end if;
    end process;

    -- Output results on LEDs
    LEDR(7 downto 0) <= cksum_ok_cnt(7 downto 0); -- Good packets count (lower 8 bits)
    LEDR(8) <= cksum_ok;                          -- Light if last packet was good
    LEDR(9) <= cksum_calc;                        -- Light when checksum calculated

end architecture;

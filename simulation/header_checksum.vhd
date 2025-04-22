library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_checksum is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        data_in       : in  std_logic_vector(7 downto 0);
        start_of_data : in  std_logic;  -- high for 1 cycle on first byte
        data_valid    : in  std_logic;  -- high when data_in is valid
        cksum_calc    : out std_logic;  -- high when checksum done
        cksum_ok      : out std_logic;  -- high if checksum correct
        cksum_ok_cnt  : out std_logic_vector(15 downto 0); -- passing packets count
        cksum_ko_cnt  : out std_logic_vector(15 downto 0)  -- failing packets count
    );
end entity;

architecture behavioral of header_checksum is
    signal sum           : unsigned(16 downto 0) := (others => '0'); -- 17 bits to handle carry
    signal byte_counter  : integer := 0; 
    signal temp_word     : std_logic_vector(15 downto 0) := (others => '0');
    signal header_done   : boolean := false;
    signal pass_counter  : unsigned(15 downto 0) := (others => '0');
    signal fail_counter  : unsigned(15 downto 0) := (others => '0');
    signal cksum_calc_i  : std_logic := '0';
    signal cksum_ok_i    : std_logic := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            sum          <= (others => '0');
            byte_counter <= 0;
            temp_word    <= (others => '0');
            pass_counter <= (others => '0');
            fail_counter <= (others => '0');
            cksum_calc_i <= '0';
            cksum_ok_i   <= '0';
        elsif rising_edge(clk) then
            cksum_calc_i <= '0'; -- default

            if start_of_data = '1' then
                sum <= (others => '0');
                byte_counter <= 0;
                header_done <= false;
            end if;

            if data_valid = '1' then
                if byte_counter mod 2 = 0 then
                    -- first byte (high)
                    temp_word(15 downto 8) <= data_in;
                else
                    -- second byte (low)
                    temp_word(7 downto 0) <= data_in;
                    -- add to sum
                    sum <= unsigned(temp_word) + sum;

                    -- handle carry immediately (wrap around)
                    if sum(16) = '1' then
                        sum <= unsigned("0" & sum(15 downto 0)) + 1;
                    end if;
                end if;

                byte_counter <= byte_counter + 1;
                
                -- Assume header is exactly 20 bytes (minimum IP header)
                if byte_counter = 39 then -- 2 bytes per word, 20 bytes = 40 counts (0..39)
                    header_done <= true;
                end if;
            end if;

            if header_done = true then
                -- final carry wrap around if needed
                if sum(16) = '1' then
                    sum <= unsigned("0" & sum(15 downto 0)) + 1;
                end if;

                -- Checksum verification
                if sum(15 downto 0) = x"FFFF" then
                    cksum_ok_i <= '1'; -- PASS
                    if pass_counter /= x"FFFF" then
                        pass_counter <= pass_counter + 1;
                    end if;
                elsek
                    cksum_ok_i <= '0'; -- FAIL
                    if fail_counter /= x"FFFF" then
                        fail_counter <= fail_counter + 1;
                    end if;
                end if;

                cksum_calc_i <= '1'; -- signal that result is ready
                header_done <= false; -- reset
            end if;
        end if;
    end process;

    -- Assign outputs
    cksum_calc <= cksum_calc_i;
    cksum_ok   <= cksum_ok_i;
    cksum_ok_cnt <= std_logic_vector(pass_counter);
    cksum_ko_cnt <= std_logic_vector(fail_counter);

end architecture;


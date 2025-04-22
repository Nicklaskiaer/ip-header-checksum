library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_checksum is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        data_in       : in  std_logic_vector(7 downto 0);
        start_of_data : in  std_logic;
        data_valid    : in  std_logic;
        cksum_calc    : out std_logic;
        cksum_ok      : out std_logic;
        cksum_ok_cnt  : out std_logic_vector(15 downto 0);
        cksum_ko_cnt  : out std_logic_vector(15 downto 0)
    );
end entity header_checksum;

architecture behavioral of header_checksum is
    signal sum           : unsigned(16 downto 0) := (others => '0'); -- 17 bits for carry
    signal byte_counter  : unsigned(5 downto 0) := (others => '0'); -- up to 40 counts (0 to 39)
    signal temp_word     : std_logic_vector(15 downto 0) := (others => '0');
    signal working       : boolean := false;
    signal pass_counter  : unsigned(15 downto 0) := (others => '0');
    signal fail_counter  : unsigned(15 downto 0) := (others => '0');
    signal cksum_calc_i  : std_logic := '0';
    signal cksum_ok_i    : std_logic := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            sum           <= (others => '0');
            byte_counter  <= (others => '0');
            temp_word     <= (others => '0');
            working       <= false;
            pass_counter  <= (others => '0');
            fail_counter  <= (others => '0');
            cksum_calc_i  <= '0';
            cksum_ok_i    <= '0';
        elsif rising_edge(clk) then
            -- Default outputs
            cksum_calc_i <= '0';

            if start_of_data = '1' then
                -- New packet starting
                sum <= (others => '0');
                byte_counter <= (others => '0');
                working <= true;
            end if;

            if working = true then
                if data_valid = '1' then
                    -- Assemble words and add
                    if byte_counter(0) = '0' then
                        -- First byte (high)
                        temp_word(15 downto 8) <= data_in;
                    else
                        -- Second byte (low)
                        temp_word(7 downto 0) <= data_in;
                        -- Add to sum
                        sum <= sum + unsigned(temp_word);

                        -- Immediate carry wrap-around
                        if sum(16) = '1' then
                            sum <= ('0' & sum(15 downto 0)) + 1;
                        end if;
                    end if;
                    byte_counter <= byte_counter + 1;

                    -- End of IP header (20 bytes = 40 cycles: 0..39)
                    if byte_counter = 39 then
                        working <= false;
                        -- Final checksum verification
                        if sum(16) = '1' then
                            sum <= ('0' & sum(15 downto 0)) + 1;
                        end if;

                        if sum(15 downto 0) = x"FFFF" then
                            -- PASS
                            cksum_ok_i <= '1';
                            if pass_counter /= x"FFFF" then
                                pass_counter <= pass_counter + 1;
                            end if;
                        else
                            -- FAIL
                            cksum_ok_i <= '0';
                            if fail_counter /= x"FFFF" then
                                fail_counter <= fail_counter + 1;
                            end if;
                        end if;
                        cksum_calc_i <= '1'; -- Indicate calculation done
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Output connections
    cksum_calc <= cksum_calc_i;
    cksum_ok   <= cksum_ok_i;
    cksum_ok_cnt <= std_logic_vector(pass_counter);
    cksum_ko_cnt <= std_logic_vector(fail_counter);

end architecture behavioral;

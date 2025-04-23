library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.ALL;

entity header_checksum is
  port (
    clk : in std_logic;
    reset : in std_logic;
    start_of_data : in std_logic;
    data_in : in std_logic_vector(15 downto 0);
    cksum_calc : out std_logic;
    cksum_ok : out std_logic;
    cksum_ok_cnt : out std_logic_vector(15 downto 0);
    cksum_ko_cnt : out std_logic_vector(15 downto 0);
  ) ;
end entity header_checksum;

architecture header_checksum_arch of header_checksum is
    signal temp_cksum : std_logic_vector(19 downto 0);
    signal cksum : std_logic_vector(15 downto 0);
    signal ok_count, ko_count : std_logic_vector(15 downto 0);
    signal carry : std_logic_vector(3 downto 0);

begin

    Data_snatch: process(clk, reset)
    begin
        if reset = '1' then
        temp_cksum <= (others => '0');
        cksum <= (others => '0');
        ok_count <= (others => '0');
        ko_count <= (others => '0');
        carry <= (others => '0');

        elsif rising_edge(clk) then
            if start_of_data = '1' then
            -- Add the incoming data to the temporary checksum
            temp_cksum <= std_logic_vector(unsigned(temp_cksum) + unsigned(data_in));
            
            -- Handle carry bits
            carry <= temp_cksum(19 downto 16);
            temp_cksum(19 downto 16) <= (others => '0');
            temp_cksum(15 downto 0) <= std_logic_vector(unsigned(temp_cksum(15 downto 0)) + unsigned(carry));
            
            -- Update checksum
            cksum <= temp_cksum(15 downto 0);
            end if;
        end if;
    end process Data_snatch;
    -- Checksum calculation
    cksum_calc <= '1' when start_of_data = '1' else '0';
    -- Checksum OK/KO logic
    process(clk, reset)
    begin
        if reset = '1' then
            cksum_ok <= '0';
            cksum_ok_cnt <= (others => '0');
            cksum_ko_cnt <= (others => '0');

        elsif rising_edge(clk) then
            if cksum_calc = '1' then
                if cksum = "0000000000000000" then
                    cksum_ok <= '1';
                    ok_count <= std_logic_vector(unsigned(ok_count) + 1);
                else
                    cksum_ok <= '0';
                    ko_count <= std_logic_vector(unsigned(ko_count) + 1);
                end if;
            end if;
        end if;
    end process;
    -- Output assignments
    cksum_ok_cnt <= ok_count;
    cksum_ko_cnt <= ko_count;
end architecture header_checksum_arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all; -- important for std_logic_vector IO

entity header_checksum_tb is
end entity;

architecture behavior of header_checksum_tb is

    -- Component declaration
    component header_checksum is
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
    end component;

    -- Signals for DUT
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal data_in       : std_logic_vector(7 downto 0) := (others => '0');
    signal start_of_data : std_logic := '0';
    signal data_valid    : std_logic := '0';
    signal cksum_calc    : std_logic;
    signal cksum_ok      : std_logic;
    signal cksum_ok_cnt  : std_logic_vector(15 downto 0);
    signal cksum_ko_cnt  : std_logic_vector(15 downto 0);

    -- File related
    file input_file  : text open read_mode is "input_packet.txt";
    file output_file : text open write_mode is "output_result.txt";

    signal end_of_simulation : boolean := false;
begin

    -- Instantiate the checksum unit
    uut: header_checksum
        port map (
            clk           => clk,
            reset         => reset,
            data_in       => data_in,
            start_of_data => start_of_data,
            data_valid    => data_valid,
            cksum_calc    => cksum_calc,
            cksum_ok      => cksum_ok,
            cksum_ok_cnt  => cksum_ok_cnt,
            cksum_ko_cnt  => cksum_ko_cnt
        );

    -- Clock generation
    clk_process : process
    begin
        while not end_of_simulation loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stimulus: process
        variable line_in  : line;
        variable data_hex : std_logic_vector(7 downto 0);
        variable first_packet : boolean := true;
    begin
        wait for 20 ns;
        reset <= '0';

        while not endfile(input_file) loop
            readline(input_file, line_in);
            read(line_in, data_hex);

            -- start_of_data high for first byte of each packet
            if first_packet = true then
                start_of_data <= '1';
                first_packet := false;
            else
                start_of_data <= '0';
            end if;

            data_in <= data_hex;
            data_valid <= '1';
            wait until rising_edge(clk);
            data_valid <= '0';
            wait until rising_edge(clk);
        end loop;

        -- Wait for checksum calculation result
        wait until cksum_calc = '1';
        
        -- Write result to file
        variable line_out : line;
        write(line_out, string'("Checksum verification result: "));
        if cksum_ok = '1' then
            write(line_out, string'("PASS"));
        else
            write(line_out, string'("FAIL"));
        end if;
        writeline(output_file, line_out);

        -- Write counters
        write(line_out, string'("Packets Passed: "));
        write(line_out, to_integer(unsigned(cksum_ok_cnt)));
        writeline(output_file, line_out);

        write(line_out, string'("Packets Failed: "));
        write(line_out, to_integer(unsigned(cksum_ko_cnt)));
        writeline(output_file, line_out);

        -- End simulation
        end_of_simulation <= true;
        wait;
    end process;

end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.ALL;
use  IEEE.std_logic_textio.ALL;

library STD;
use std.textio.all;

entity header_checksum_tb is
end entity header_checksum_tb;

architecture testbench of header_checksum_tb is
    constant clk_period : time := 10 ns;
    
    component header_checksum
        port (
            clk : in std_logic;
            reset : in std_logic;
            start_of_data : in std_logic;
            data_in : in std_logic_vector(15 downto 0);
            cksum_calc : out std_logic;
            cksum_ok : out std_logic;
            cksum_ok_cnt : out std_logic_vector(15 downto 0);
            cksum_ko_cnt : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal start_of_data : std_logic := '0';
    signal data_in : std_logic_vector(15 downto 0) := (others => '0');
    signal cksum_calc : std_logic;
    signal cksum_ok : std_logic;
    signal cksum_ok_cnt : std_logic_vector(15 downto 0);
    signal cksum_ko_cnt : std_logic_vector(15 downto 0);

    DUT : header_checksum
        port map (
            clk => clk,
            reset => reset,
            start_of_data => start_of_data,
            data_in => data_in,
            cksum_calc => cksum_calc,
            cksum_ok => cksum_ok,
            cksum_ok_cnt => cksum_ok_cnt,
            cksum_ko_cnt => cksum_ko_cnt
        );

    reset_process : process
    begin
        reset <= '1';
        wait for 2*clk_period;
        reset <= '0';
        wait;
    end process reset_process;

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process clk_process;
    stimulus_process : process

    test : process
        in_file : text open read_mode is "input_packet.txt";
        out_file : text open write_mode is "output_simulation.txt";

        variable line_buffer : line;
        variable data_line : string(1 to 16);
        variable data_value : std_logic_vector(15 downto 0);
        variable cksum_ok_value : std_logic;
        variable cksum_ko_value : std_logic;
        variable cksum_ok_cnt_value : std_logic_vector(15 downto 0);
        variable cksum_ko_cnt_value : std_logic_vector(15 downto 0);
        variable data_in_value : std_logic_vector(15 downto 0);
        variable cksum_calc_value : std_logic;
        variable start_of_data_value : std_logic;
        variable reset_value : std_logic;
        variable clk_value : std_logic;
        variable i : integer;
        variable data_in_value : std_logic_vector(15 downto 0);
    begin
        -- Read the input data from the file
        while not endfile(in_file) loop
            readline(in_file, line_buffer);
            read(line_buffer, data_line);
            data_in_value := to_stdlogicvector(data_line);
            write(line_buffer, string'("Data: "));
            write(line_buffer, data_in_value);
            writeline(out_file, line_buffer);

            -- Apply the input data to the DUT
            start_of_data <= '1';
            data_in <= data_in_value;
            wait for clk_period;

            -- Check the output values
            cksum_ok_value := cksum_ok;
            cksum_ko_value := cksum_ko;
            cksum_ok_cnt_value := cksum_ok_cnt;
            cksum_ko_cnt_value := cksum_ko_cnt;
            
            write(line_buffer, string'("Checksum OK: "));
            write(line_buffer, cksum_ok_value);
            writeline(out_file, line_buffer);
            
            write(line_buffer, string'("Checksum KO: "));
            write(line_buffer, cksum_ko_value);
            writeline(out_file, line_buffer);
        end loop;
        write(line_buffer, string'("Checksum OK Count: "));
        write(line_buffer, cksum_ok_cnt_value);
        writeline(out_file, line_buffer);
        write(line_buffer, string'("Checksum KO Count: "));
        write(line_buffer, cksum_ko_cnt_value);
        writeline(out_file, line_buffer);
    end process;

end architecture testbench;
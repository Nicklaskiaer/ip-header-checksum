--TESTBENCH FOR header_checksum

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library STD;
use STD.textio.all;


entity hardware_TB is
end entity;


architecture hardware_TB_arch of hardware_TB is
	
	component header_checksum is
			port(
			Clock				:	in 		std_logic;	
			reset				:	in 		std_logic;	
			start_of_data		:	in		std_logic;	
			data_in				:	in		std_logic_vector(7 downto 0);
			cksum_calc			:	out		std_logic;
			cksum_ok			:	out		std_logic;
			cksum_ok_cnt		:	out		std_logic_vector(15 downto 0);
			cksum_ko_cnt		:	out		std_logic_vector(15 downto 0)
		);
	end component;
	
	
	signal Clock_TB: 			std_logic;
	signal reset_TB: 			std_logic;
	signal start_of_data_TB: 	std_logic;
	signal data_in_TB: 			std_logic_vector(7 downto 0);
	signal cksum_calc_TB: 		std_logic;
	signal cksum_ok_TB: 		std_logic;
	signal cksum_ok_cnt_TB: 	std_logic_vector(15 downto 0);
	signal cksum_ko_cnt_TB: 	std_logic_vector(15 downto 0);

	begin
	
		DUT : header_checksum port map (Clock=>Clock_TB, reset=>reset_TB,start_of_data=>start_of_data_TB, 
													data_in=>data_in_TB,cksum_calc=>cksum_calc_TB, cksum_ok=>cksum_ok_TB, 
													cksum_ok_cnt=>cksum_ok_cnt_TB, cksum_ko_cnt=>cksum_ko_cnt_TB);

	-- clock cycle at 20ns										
	Process
		begin
		Clock_TB <= '0';
		wait for 10 ns;
		CLock_TB <= '1';
		wait for 10 ns;
	end process;
	
	STIMULUS : Process (Clock_TB)
		
		variable current_read_line 							: line;
		variable current_write_line							: line;
		variable current_read_line_field_START_OF_DATA 		: std_logic;
		variable current_read_line_field_DATA 				: std_logic_vector(7 downto 0);
		variable start										: bit := '0';
		variable written									: bit	:= '0';
		
		file Fin 	:	TEXT open READ_MODE is "packets.txt";
		file Fout	:	TEXT open WRITE_MODE is "results.txt";

		begin
				if rising_edge(Clock_TB) then
					if start='0' then
						reset_TB <= '0';
						start := not start;
					else 
						reset_TB <= '1';
					end if;
									
					if not endfile(Fin) then
						Readline(Fin, current_read_line);
						hread(current_read_line, current_read_line_field_DATA);
						read(current_read_line, current_read_line_field_START_OF_DATA);
				
						-- Assign given input
						start_of_data_TB <= current_read_line_field_START_OF_DATA;
						data_in_TB <= current_read_line_field_DATA;
					else
						if written='0' then
							write(current_read_line, string'("Report of IP's in file"));
							writeline(Fout, current_read_line);
							
							write(current_read_line, string'("Number of succesfull IPs: "));
							write(current_read_line, to_integer(unsigned(cksum_ok_cnt_TB)));
							writeline(Fout, current_read_line);

							write(current_read_line, string'("Number of unsuccesfull IPs: "));
							write(current_read_line, to_integer(unsigned(cksum_ko_cnt_TB)));
							writeline(Fout, current_read_line);
							written := '1';
						end if;
					end if;
				end if;
			end process;
			
					
	
end hardware_TB_arch;

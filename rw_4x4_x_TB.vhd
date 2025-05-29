--TESTBENCH FOR header_checksum

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;



entity rw_4x4_x_TB is
end entity;


architecture rw_4x4_x_TB_arch of rw_4x4_x_TB is
	component rw_4x4_syn is
		port	(clock		:	in		std_logic;
				 address		:	in 	std_logic_vector(11 downto 0);
				 data_out	:	out	std_logic_vector(8 downto 0));
	end component;
	
	signal		Clock_TB					:	std_logic;								-- clock signal
	signal 		data_out_signal 		:	std_logic_vector(8 downto 0) := x"00"&'0'; -- data from memory instance
	signal 		address_signal 		: std_logic_vector(11 downto 0):=x"000"; 
	signal 		data						: std_logic_vector(7 downto 0) := x"00";
	signal 		data_sof					: std_logic := '0';

	
	
	
	begin
	
		DUT : rw_4x4_syn port map (Clock=>Clock_TB, 
											address => address_signal, 
											data_out => data_out_signal);
		

		

	-- clock cycle at 20ns										
	Process
		begin
		Clock_TB <= '0';
		wait for 10 ns;
		CLock_TB <= '1';
		wait for 10 ns;
	end process;		



	Address_choser : process (clock_tb)
		variable start : bit:='1';
		begin

			if (clock_TB'event and clock_tb='1') then
					if start='1' then
						address_signal <= x"000";
						start := not start;
					else
						address_signal <= address_signal + "1";
						data <= data_out_signal (8 downto 1);
						data_sof <= data_out_signal(0);
					end if;
			
		end if;
				
	end process;	
					
	
end rw_4x4_x_TB_arch;

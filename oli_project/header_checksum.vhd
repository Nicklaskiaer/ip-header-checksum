library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity header_checksum is
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
end entity;

architecture header_checksum_arch of header_checksum is

	signal data_last	 			: std_logic_vector(7 downto 0);
	signal count, done			: std_logic;
	signal number_of_data		: integer;
	signal flip						: std_logic := '0';
	signal sum_with_carry		: std_logic_vector(16 downto 0) := '0'&x"0000";
	signal sum						: std_logic_vector(15 downto 0);
	signal cksum_ok_cnt_signal	: std_logic_vector(15 downto 0) := x"0000";
	signal cksum_ko_cnt_signal	: std_logic_vector(15 downto 0) := x"0000";

	
begin
	cksum_ok_cnt <= cksum_ok_cnt_signal;
	cksum_ko_cnt <= cksum_ko_cnt_signal;

	
	CHECKSUM : process (Clock)
		variable temp_data : std_logic_vector(15 downto 0);

		begin

			if (Clock'event and Clock='1') then
				if Reset='0' then
					sum <= x"0000";
					cksum_ok_cnt_signal <= x"0000";
					cksum_ko_cnt_signal <= x"0000";
					count <= '0';
					number_of_data <= 0;
					sum_with_carry <= '0'&x"0000";
					cksum_calc <= '0';
					cksum_ok <= '0';
					done <= '0';
					data_last <= x"f3";
				else
					if start_of_data='1' then
						sum <= x"0000";
						count <= '1';
						number_of_data <= 0;
						flip <= '0';
					end if;
					
					
					if (count='1' or start_of_data='1') then
						if flip='0' then
							data_last <= data_in;
							flip <= not flip;
							sum <= sum_with_carry(16)+sum_with_carry(15 downto 0);  -- take care of carry bits
						else
							temp_data := data_last & data_in; 
							sum_with_carry <= ('0'&sum) + ('0'&temp_data); -- Add sum and data+last_data
							flip <= not flip;
							number_of_data <= number_of_data + 1;
						end if;
					end if;
				end if;
				
						
				if (number_of_data=10) then 
						done <= '1';
					if (flip='1') then
						cksum_calc <= '1';
						if (sum=x"ffff") then
							cksum_ok <= '1';
							cksum_ok_cnt_signal <= cksum_ok_cnt_signal + '1';
						else
							cksum_ok <= '0';
							cksum_ko_cnt_signal <= cksum_ko_cnt_signal + '1';
						end if;
					else
						cksum_ok <= '0';
					end if;
				elsif (number_of_data=11) then 
					sum <= x"0000";
					sum_with_carry <= "0"&x"0000";
					count <= '0';
					cksum_ok <= '0';
					cksum_calc <= '0';
					number_of_data <= 0;
					flip <= '0';
				end if;
				
				
			end if;
	end process;

			
end header_checksum_arch;
--TESTBENCH FOR header_checksum

library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 
use ieee.std_logic_unsigned.all;

library STD;
use STD.textio.all;

entity de10_hardware_TB is
end entity;

architecture de10_hardware_TB_arch of de10_hardware_TB is
	
	component DE10_LITE_Empty_Top is
		port(
				ADC_CLK_10:	in 	std_logic;
				KEY: in std_logic_vector(1 downto 0);		
				LEDR: out std_logic_vector(7 downto 0);
				HEX0: out bit_vector(7 downto 0);
				HEX1: out bit_vector(7 downto 0);
				HEX2: out bit_vector(7 downto 0);
				HEX3: out bit_vector(7 downto 0)
			);
	end component;

	signal	Clock_TB: std_logic;
	signal	KEY_TB: std_logic_vector(1 downto 0) := "11";
	signal	HEX0_TB: bit_vector(7 downto 0);		
	signal	HEX1_TB: bit_vector(7 downto 0);
	signal	HEX2_TB: bit_vector(7 downto 0);
	signal	HEX3_TB: bit_vector(7 downto 0);
	signal	LEDR_TB: std_logic_vector(7 downto 0);
	signal	start: bit := '1';
	signal	start1: bit := '1';
	
	begin
	
		DUT : DE10_LITE_Empty_Top port map (
			ADC_CLK_10=>Clock_TB,
			KEY   => KEY_TB,
			HEX0 => HEX0_TB,
			HEX1 => HEX1_TB,
			HEX2 => HEX2_TB,
			HEX3 => HEX3_TB,
			LEDR => LEDR_TB
			);
	
	process (clock_tb)
		begin		
			if (clock_tb'event and clock_tb='1') then
				if start='1' then
					KEY_tb(1)<='0'; -- reset
					KEY_TB(0)<='0'; -- start data input
					start <= not start;
				elsif (start1='1') then
					KEY_tb(1) <= '1';
					KEY_tb(0) <= '1';
				end if;
			end if;
		end process;
	
	-- clock cycle at 20ns										
	Process
		begin
		Clock_TB <= '0';
		wait for 10 ns;
		CLock_TB <= '1';
		wait for 10 ns;
	end process;
	
end de10_hardware_TB_arch;


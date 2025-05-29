
--=======================================================
--  Entity decleration
--=======================================================

    --DE10_LITE_Empty_Top: 
    --
	-------------- CLOCK ----------
	--input 		          		ADC_CLK_10,
	--input 		          		MAX10_CLK1_50,
	--input 		          		MAX10_CLK2_50,
    --
	-------------- SDRAM ----------
	--output		    [12:0]		DRAM_ADDR,
	--output		     [1:0]		DRAM_BA,
	--output		          		DRAM_CAS_N,
	--output		          		DRAM_CKE,
	--output		          		DRAM_CLK,
	--output		          		DRAM_CS_N,
	--inout 		    [15:0]		DRAM_DQ,
	--output		          		DRAM_LDQM,
	--output		          		DRAM_RAS_N,
	--output		          		DRAM_UDQM,
	--output		          		DRAM_WE_N,
    --
	-------------- SEG7 ----------
	--output		     [7:0]		HEX0,
	--output		     [7:0]		HEX1,
	--output		     [7:0]		HEX2,
	--output		     [7:0]		HEX3,
	--output		     [7:0]		HEX4,
	--output		     [7:0]		HEX5,
    --
	-------------- KEY ----------
	--input 		     [1:0]		KEY,
    --
	-------------- LED ----------
	--output		     [9:0]		LEDR,
    --
	-------------- SW ----------
	--input 		     [9:0]		SW,
    --
	-------------- VGA ----------
	--output		     [3:0]		VGA_B,
	--output		     [3:0]		VGA_G,
	--output		          		VGA_HS,
	--output		     [3:0]		VGA_R,
	--output		          		VGA_VS,
    --
	-------------- Accelerometer ----------
	--output		          		GSENSOR_CS_N,
	--input 		     [2:1]		GSENSOR_INT,
	--output		          		GSENSOR_SCLK,
	--inout 		          		GSENSOR_SDI,
	--inout 		          		GSENSOR_SDO,
    --
	-------------- Arduino ----------
	--inout 		    [15:0]		ARDUINO_IO,
	--inout 		          		ARDUINO_RESET_N,
    --
	-------------- GPIO, GPIO connect to GPIO Default ----------
	--inout 		    [35:0]		GPIO

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity DE10_LITE_Empty_Top is
	port(
			ADC_CLK_10		:	in 	std_logic;
			KEY				:	in		std_logic_vector(1 downto 0);		
			LEDR				:	out 	std_logic_vector(7 downto 0);
			HEX0				:	out	bit_vector(7 downto 0);
			HEX1				: 	out	bit_vector(7 downto 0);
			HEX2				:	out	bit_vector(7 downto 0);
			HEX3				:	out	bit_vector(7 downto 0)

		);
end entity;



	
--=======================================================
-- Architecture declaration
--=======================================================


architecture header_checksum_arch of DE10_LITE_Empty_Top is

	component header_checksum is
		port(
				Clock				:	in 	std_logic;								-- clock signal
				reset				:	in 	std_logic;								--reset
				start_of_data	:	in		std_logic;								-- start of ip packet on data_in, i.e. first byte of header		
				data_in			:	in		std_logic_vector(7 downto 0);		-- actual IP packet data
				cksum_calc		:	out	std_logic;								-- raised 1. cycle when cksum calc result is available on cksum_ok
				cksum_ok			:	out	std_logic;								-- Shows if checksum is valid. (only used when cksum_calc ='1')
				cksum_ok_cnt	:	out	std_logic_vector(15 downto 0);	-- count number of good checksums
				cksum_ko_cnt	:	out	std_logic_vector(15 downto 0)		-- count number of bad checksums
			);
	end component;
	
	component rw_4x4_syn is
		port	(
				clock				:	in		std_logic;
				address			:	in 	std_logic_vector(11 downto 0);
				data_out			:	out	std_logic_vector(8 downto 0));
	end component;
	
	component display_8_bit_value is
	
		port (
				data				:	in 	std_logic_vector(3 downto 0);
				HEX				:	out 	bit_vector(7 downto 0)
			);
	end component;

	---------------------------------------
	
	signal data_out_signal 		: std_logic_vector(8 downto 0) := x"00"&'0'; -- data from memory instance
	
	signal address_signal 		: std_logic_vector(11 downto 0):=x"000"; 
	signal data_0					: std_logic_vector(3 downto 0) := x"0";
	signal data_1					: std_logic_vector(3 downto 0) := x"0";
	signal data_2					: std_logic_vector(3 downto 0) := x"0";
	signal data_3					: std_logic_vector(3 downto 0) := x"0";
	signal counter_OK				: std_logic_vector(15 downto 0)  := x"0000";
	signal counter_KO				: std_logic_vector(15 downto 0)  := x"0000";
	
	signal data_to_checksum		: std_logic_vector(7 downto 0) := x"00";
	signal data_sof				: std_logic:= '0';
	
	signal start					: std_logic:= '0'; -- signal used to indicate wheter or not start of data loading should happen!
	

	
begin
	
	instance_rw_4x4_syn : rw_4x4_syn port map ( -- Instance of memory
									clock => ADC_CLK_10, 
									address => address_signal, 
									data_out => data_out_signal
									);
	
	
	instance_header_checksum : header_checksum port map ( -- instance of headsum checker
																		Clock => ADC_CLK_10, 
																		reset => KEY(1), 
																		start_of_data => data_Sof, 
																		data_in => data_to_checksum,
																		cksum_calc => LEDR(0), 
																		cksum_ok => LEDR(1), 
																		cksum_ok_cnt => counter_OK, 
																		cksum_ko_cnt => counter_KO
																		);
																		
	
	instance_0_display_8_bit_value : display_8_bit_value port map(data => data_0, HEX => HEX0);
	instance_1_display_8_bit_value : display_8_bit_value port map(data => data_1, HEX => HEX1);
	instance_2_display_8_bit_value : display_8_bit_value port map(data => data_2, HEX => HEX2);
	instance_3_display_8_bit_value : display_8_bit_value port map(data => data_3, HEX => HEX3);
	

																						
																	
	Address_choser : process (ADC_CLK_10)
		begin
			if (ADC_CLK_10'event and ADC_CLK_10='1') then
			
				if (KEY(1) = '0') then -- reset!
					address_signal 	<= x"000";
					data_0				<= x"0";	
					data_1				<= x"0";	
					data_2				<= x"0";	
					data_3				<= x"0";
					data_to_checksum	<= x"00";	
					data_sof				<= '0';
					start					<= '0';
					
				elsif (key(0) = '0' or start = '1') then -- start data loading!
					start <= '1';
					
					data_0 <= counter_OK(3 downto 0);
					data_1				<= x"0";
					--data_1 <= to_bitvector(counter_OK(7 downto 4));
					data_2 <= counter_KO(3 downto 0);
					data_3				<= x"0";
					--data_3 <= to_bitvector(counter_KO(7 downto 4));
				

					data_to_checksum <= data_out_signal(8 downto 1);
					data_sof <= data_out_signal(0);
					if (address_signal < x"FF0") then
						address_signal <= address_signal + "1";
					end if;
				end if;
		end if;
				
	end process;
			
end header_checksum_arch;
	





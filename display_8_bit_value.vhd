--=======================================================
--  Entity decleration
--=======================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity display_8_bit_value is
    port (
        data : in  std_logic_vector(3 downto 0);
        HEX  : out bit_vector(7 downto 0)
    );
end entity;

--=======================================================
-- Architecture declaration
--=======================================================
architecture rtl of display_8_bit_value is
    signal F : bit_vector(7 downto 0);
begin
    with data select
			F <= 	("00111111") when "0000", --"0"
					("00000110") when "0001", --"1"
					("01011011") when "0010", --"2"
					("01001111") when "0011", --"3"
					("01100110") when "0100", --"4"
					("01101101") when "0101", --"5"
					("01111101") when "0110", --"6"
					("00000111") when "0111", --"7"
					("01111111") when "1000", --"8"
					("01101111") when "1001", --"9"
					("01110111") when "1010", --"A"
					("01111100") when "1011", --"b"
					("01011000") when "1100", --"c"
					("01011110") when "1101", --"d"
					("01111001") when "1110", --"E"
					("01110001") when "1111", --"F"
					("00111111") when others; -- default "0"

		HEX <= not F;
end;
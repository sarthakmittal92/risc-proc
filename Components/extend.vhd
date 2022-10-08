library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extend is
	generic(
        widthOfInput: integer := 6;
		widthOfOutput: integer := 16
    );
	port(
		input: in std_logic_vector(widthOfInput - 1 downto 0);
		output: out std_logic_vector(widthOfOutput - 1 downto 0)
    );
end entity;

architecture rtl of extend is
begin
	
	output(widthOfInput - 1 downto 0) <= input;
	
	extend: for i in widthOfInput to widthOfOutput - 1 generate
		output(i) <= input(widthOfInput - 1);
	end generate;
	
end architecture;
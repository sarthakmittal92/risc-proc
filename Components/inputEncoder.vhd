library ieee;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

entity inputEncoder is
	generic(
        widthOfInput: integer := 16
    );
	port(
		input: in std_logic_vector(0 to widthOfInput - 1);
		output: out std_logic_vector(0 to integer(ceil(log2(real(widthOfInput)))) - 1);
		valid: out std_logic
    );
end entity;

architecture rtl of inputEncoder is

	signal temporary: std_logic_vector(0 to output'length - 1);
    
begin

	main: process(input)
	begin

		temporary <= (others => '0');

		for i in 0 to widthOfInput - 1 loop
			if input(i) = '1' then
				temporary <= std_logic_vector(to_unsigned(i,output'length));
			end if;
		end loop;

	end process;
	
	output <= temporary;
	valid <= '0' when (to_integer(unsigned(temporary)) = 0 and input(0) = '0') else '1';
	
end architecture;
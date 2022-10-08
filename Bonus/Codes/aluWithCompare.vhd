library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.add.all;

entity alu is
	generic(
        lengthOfWord: integer := 16
    );
	port(
		input1, input2: in std_logic_vector(lengthOfWord-1 downto 0);
		output: out std_logic_vector(lengthOfWord-1 downto 0);
		cin: in std_logic;
		sel: in std_logic_vector(1 downto 0);
		CY, OV, Z: out std_logic
    );
end entity;

architecture rtl of alu is

	signal output_temp: std_logic_vector(lengthOfWord-1 downto 0);
	signal output_add: std_logic_vector(lengthOfWord-1 downto 0);
	signal C: std_logic_vector(lengthOfWord downto 1);
	signal compare, is_zero: std_logic;

begin
	
	ADD0: GenericAdder
		generic map(lengthOfWord,4)
		port map(
			A => input1,
            B => input2,
			cin => cin,
            S => output_add,
            Cout => C
        );
			
	CY <= C(lengthOfWord);
	OV <= (C(lengthOfWord) xor C(lengthOfWord - 1));
	
	process(input1,input2,sel,output_add)
	begin

		if (sel(1) = '1') then
			output_temp <= output_add;
		else
			output_temp <= input1 nand input2;
		end if;

	end process;
	
	compare <= '1' when (input1 = input2) else '0';
	is_zero <= '1' when (to_integer(unsigned(output_temp)) = 0) else '0';
	Z <= is_zero when (sel(0) = '0') else compare;
	output <= output_temp;
		
end architecture;
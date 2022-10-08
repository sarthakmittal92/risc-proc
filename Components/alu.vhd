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
		input1, input2: in std_logic_vector(lengthOfWord - 1 downto 0);
		output: out std_logic_vector(lengthOfWord - 1 downto 0);
		cin, sel: in std_logic;
		CY, Z: out std_logic
    );
end entity;

architecture behave of alu is

	signal temporary: std_logic_vector(lengthOfWord - 1 downto 0);
	signal addResult: std_logic_vector(lengthOfWord - 1 downto 0);
	signal C: std_logic_vector(lengthOfWord downto 1);
    
begin
	
	ADD0: GenericAdder
		generic map(lengthOfWord,4)
		port map(
			A => input1,
            B => input2,
			cin => cin,
            S => addResult,
            Cout => C
        );
			
	CY <= C(lengthOfWord);
	
	process(input1,input2,sel,addResult)
	begin

		if (sel = '0') then
			temporary <= addResult;
		else
			temporary <= input1 nand input2;
		end if;

	end process;
	
	Z <= '1' when (to_integer(unsigned(temporary)) = 0) else '0';
	output <= temporary;
		
end architecture;
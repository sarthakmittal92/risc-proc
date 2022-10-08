library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity RegFile is
	generic(
		lengthOfWord: integer := 16;
		noOfWords: integer := 8
    );
	port(
		data_in: in std_logic_vector(lengthOfWord - 1 downto 0);
		data_out1, data_out2, R7, R0: out std_logic_vector(lengthOfWord - 1 downto 0);
		sel_in, sel_out1, sel_out2: in std_logic_vector(integer(ceil(log2(real(noOfWords)))) - 1 downto 0);
		clk, wr_ena, reset: in std_logic
    );
end entity;

architecture rtl of RegFile is
    
	type ourBus is array(noOfWords - 1 downto 0) of std_logic_vector(lengthOfWord - 1 downto 0);
	signal reg_out: ourBus;
	signal ena: std_logic_vector(noOfWords - 1 downto 0);
	signal data_out: std_logic_vector(lengthOfWord - 1 downto 0);
	
begin
	
	GEN_REG: for i in 0 to noOfWords - 1 generate
		REG: Register
			generic map(lengthOfWord)
			port map(
                clk => clk,
                ena => ena(i), 
				Din => data_in,
                Dout => reg_out(i),
                clr => reset
            );
	end generate GEN_REG;
	
	in_decode: process(sel_in, wr_ena)
	begin

		ena <= (others => '0');
		ena(to_integer(unsigned(sel_in))) <= wr_ena;
        	
	end process;
	
	data_out1 <= reg_out(to_integer(unsigned(sel_out1)));
	data_out2 <= reg_out(to_integer(unsigned(sel_out2)));
	R7 <= reg_out(noOfWords - 1);
	R0 <= reg_out(0);
	
end architecture;
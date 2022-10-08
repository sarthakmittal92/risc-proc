library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package basic is

	component OneBitFullAdder is
		port(
			a, b, c0: in std_logic;
			c1, s: out std_logic
        );
	end component;
	
	component divideClock is
		generic(
            ratio: integer := 5
        );
		port(
			clk_in: in std_logic;
			clk_out: out std_logic
        );		
	end component;
	
	component Register is
        generic (
            widthOfData : integer
        );
        port(
            clk, ena, clr: in std_logic;
            Din: in std_logic_vector(widthOfData - 1 downto 0);
            Dout: out std_logic_vector(widthOfData - 1 downto 0)
        );
	end component;

	component TwoBitAdder is
		port(
			a0, a1, b0, b1, c0: in std_logic;
			s0, s1, c2: out std_logic
        );
	end component;

	component EightBitAdder is
		port(
			A, B: in std_logic_vector(7 downto 0);
			S: out std_logic_vector(7 downto 0);
			c0: in std_logic;
			c8: out std_logic
        );
	end component;

	component SixteenBitSub is
		port(
			A, B: in std_logic_vector(15 downto 0);
			S: out std_logic_vector(15 downto 0);
			c16: out std_logic
        );
	end component;

	component isEqualTo is
		generic (
            widthOfData : integer := 16
        );
		port (
			A, B: in std_logic_vector(widthOfData - 1 downto 0);
			R: out std_logic
        );
	end component;
	
	component isGreaterThan is
        generic (
            widthOfData : integer := 16
        );
        port (
            A, B: in std_logic_vector(widthOfData - 1 downto 0);
            R: out std_logic
        );
	end component;
	
	component FourBitDecr is
        port(
            A : in std_logic_vector(3 downto 0);
            B : out std_logic_vector(3 downto 0)
        );
	end component;

	component FourBitMux is
		generic(
            widthOfInput: integer := 16
        );
		port(
			inp1, inp2, inp3, inp4: in std_logic_vector(widthOfInput - 1 downto 0) := (others => '0');
			sel: in std_logic_vector(1 downto 0);
			output: out std_logic_vector(widthOfInput - 1 downto 0)
        );
	end component;

	component EightBitMux is
		generic(
            widthOfInput: integer := 16
        );
		port(
			inp1, inp2, inp3, inp4, inp5, inp6, inp7, inp8: in std_logic_vector(widthOfInput - 1 downto 0) := (others => '0');
			sel: in std_logic_vector(2 downto 0);
			output: out std_logic_vector(widthOfInput - 1 downto 0)
        );
	end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FourBitDecr is
	port(
		A : in std_logic_vector(3 downto 0);
		B : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl1 of FourBitDecr is

	signal c1, c2, c3 : std_logic;
	
begin

	B(0) <= (not A(0));	
	c1 <= (A(0));		
	
	B(1) <= ((A(1) and c1) or ((not A(1)) and (not c1)));
	c2 <= (A(1) or c1);
	
	B(2) <= ((A(2) and c2) or ((not A(2)) and (not c2)));
	c3 <= (A(2) or c2);
	
	B(3) <= ((A(3) and c3) or ((not A(3)) and (not c3)));
	
end architecture;
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OneBitFullAdder is
	port(
		a, b, c0: in std_logic;
		c1, s: out std_logic
    );
end entity;

architecture rtl2 of OneBitFullAdder is

	signal abxor: std_logic;

begin

	abxor <= (((not a) and b) or (a and (not b)));
	s <= (((not abxor) and c0) or (abxor and (not c0)));
	c1 <= (((a and b) or (a and c0)) or (c0 and b));

end architecture;	 	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity TwoBitAdder is
	port(
		a0, a1, b0, b1, c0: in std_logic;
		s0, s1, c2: out std_logic
    );
end entity;

architecture rtl3 of TwoBitAdder is

	signal c1: std_logic;

begin

	full1: OneBitFullAdder
        port map(
            a => a0,
            b=> b0,
            s => s0,
            c0 => c0,
            c1 => c1
        );
    
	full2: OneBitFullAdder
        port map(
            a => a1,
            b=> b1,
            s => s1,
            c0 => c1,
            c1 => c2
        );

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity EightBitAdder is
	port(
		A, B: in std_logic_vector(7 downto 0);
		S: out std_logic_vector(7 downto 0);
		c0: in std_logic;
		c8: out std_logic
    );
end entity;

architecture rtl4 of EightBitAdder is

	signal c2, c4, c6: std_logic;
	
begin
	
	full21: TwoBitAdder
        port map(
            a0 => A(0),
            a1 => A(1),
            b0 => B(0),
            b1 => B(1),
            c0 => c0,
            c2 => c2,
            s0 => S(0),
            s1 => S(1)
        );
    
	full22: TwoBitAdder
        port map(
            a0 => A(2),
            a1 => A(3),
            b0 => B(2),
            b1 => B(3),
            c0 => c2,
            c2 => c4,
            s0 => S(2),
            s1 => S(3)
        );
    
	full23: TwoBitAdder
        port map(
            a0 => A(4),
            a1 => A(5),
            b0 => B(4),
            b1 => B(5),
            c0 => c4,
            c2 => c6,
            s0 => S(4),
            s1 => S(5)
        );
    
	full24: TwoBitAdder
        port map(
            a0 => A(6),
            a1 => A(7),
            b0 => B(6),
            b1 => B(7),
            c0 => c6,
            c2 => c8,
            s0 => S(6),
            s1 => S(7)
        );

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity isGreaterThan is
	generic(
        widthOfData : integer := 16
    );
	port(
		A, B: in std_logic_vector(widthOfData - 1 downto 0);
		R: out std_logic
    );
end entity;

architecture rtl5 of isGreaterThan is

	signal not_equal, temp2: std_logic_vector(widthOfData - 1 downto 0);

begin
	
	not_equal <= ((A and (not B)) or ((not A) and B));
	temp2(widthOfData - 1) <= (not not_equal(widthOfData - 1)) or A(widthOfData - 1); 
	
    gen: for i in widthOfData - 2 downto 0 generate
		temp2(i) <= ((A(i) or (not not_equal(i))) and temp2(i+1)); 
	end generate;
	
	R <= (temp2(0) and not_equal(0));

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity isEqualTo is
	generic(
        widthOfData : integer := 16
    );
	port (
		A, B: in std_logic_vector(widthOfData - 1 downto 0);
		R: out std_logic
    );
end entity;

architecture rtl6 of isEqualTo is

	signal int, temp: std_logic_vector(widthOfData - 1 downto 0);

begin

	int <= ((A and (not B)) or ((not A) and B));
	temp(0) <= int(0);

    gen: for i in 1 to widthOfData - 1 generate
        temp(i) <= temp(i - 1) or int(i);
    end generate; 
    
    R <= not temp(widthOfData - 1);

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Register is
	generic(
        widthOfData : integer
    );
	port(
		clk, ena, clr: in std_logic;
		Din: in std_logic_vector(widthOfData - 1 downto 0);
		Dout: out std_logic_vector(widthOfData - 1 downto 0)
    );
end entity;

architecture rtl7 of Register is
begin

	process(clk, clr)	
	begin

		if(clk'event and clk='1') then
			if (ena='1') then
				Dout <= Din;
			end if;
		end if;

		if(clr = '1') then
			Dout <= (others => '0');
		end if;

	end process;
	
end architecture;		

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity SixteenBitSub is
	port(
		A, B: in std_logic_vector(15 downto 0);
		S: out std_logic_vector(15 downto 0);
		c16: out std_logic
    );
end entity;

architecture rtl8 of SixteenBitSub is

	signal notB: std_logic_vector(15 downto 0);
	signal cint : std_logic;

begin
	
	notB <= not B;
	
	adder1: EightBitAdder
        port map(
            A => A(7 downto 0),
            B => notB(7 downto 0),
            c0 => '1',
            c8 => cint,
            S => S(7 downto 0)
        );
    
	adder2: EightBitAdder
        port map(
            A => A(15 downto 8),
            B => notB(15 downto 8),
            c0 => cint,
            c8 => c16,
            S => S(15 downto 8)
        );
	
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity divideClock is
	generic(
        ratio: integer := 5
    );
	port(
		clk_in: in std_logic;
		clk_out: out std_logic
    );		
end entity;

architecture rtl9 of divideClock is

	signal inf, outf: std_logic_vector(ratio - 1 downto 0);
	
begin

	inf <= std_logic_vector(unsigned(outf) + 1);

	process(clk_in)
	begin
	
		if(clk_in = '1') then
			outf <= inf;
		end if;

	end process;

	clk_out <= outf(ratio  -  1);
	
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FourBitMux is
	generic(
        widthOfInput: integer := 16
    );
	port(
		inp1, inp2, inp3, inp4: in std_logic_vector(widthOfInput - 1 downto 0) := (others => '0');
		sel: in std_logic_vector(1 downto 0);
		output: out std_logic_vector(widthOfInput - 1 downto 0)
    );
end entity;

architecture rtl10 of FourBitMux is
begin

	output <= inp1 when (sel = "00") else
        inp2 when (sel = "01") else
        inp3 when (sel = "10") else
        inp4;

end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EightBitMux is
	generic(
        widthOfInput: integer := 16
    );
	port(
		inp1, inp2, inp3, inp4, inp5, inp6, inp7, inp8: in std_logic_vector(widthOfInput - 1 downto 0) := (others => '0');
		sel: in std_logic_vector(2 downto 0);
		output: out std_logic_vector(widthOfInput - 1 downto 0)
    );
end entity;

architecture behave of EightBitMux is
begin

	output <= inp1 when (sel = "000") else
		inp2 when (sel = "001") else
		inp3 when (sel = "010") else
		inp4 when (sel = "011") else
		inp5 when (sel = "100") else
		inp6 when (sel = "101") else
		inp7 when (sel = "110") else
		inp8;

end;
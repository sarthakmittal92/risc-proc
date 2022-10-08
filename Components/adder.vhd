-- creating packages
-- https://www.nandland.com/vhdl/examples/example-package.html

-- generic values
-- https://fpgatutorial.com/vhdl-generic-generate/#:~:text=In%20VHDL%2C%20generics%20are%20a,a%20component%20on%20the%20fly.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package add is

	component CarryLookAheadAdder is
		port(
			a, b, cin: in std_logic;
			s, p, g: out std_logic
        );
	end component;
	
	component NextCarry is
		generic(
            lengthOfGroup: integer := 4
        );
		port(
			P, G: in std_logic_vector(lengthOfGroup - 1 downto 0);
			cin: in std_logic;
			Cout: out std_logic_vector(lengthOfGroup - 1 downto 0)
        );
	end component;
	
	component GenericAdder is
		generic(
			lengthOfWord: integer := 16;
			lengthOfGroup: integer := 4
        );
		port(
			A, B: in std_logic_vector(lengthOfWord - 1 downto 0);
			S: out std_logic_vector(lengthOfWord - 1 downto 0);
			cin: in std_logic;
			Cout: out std_logic_vector(lengthOfWord - 1 downto 0)
        );
	end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CarryLookAheadAdder is
	port(
		a, b, cin: in std_logic;
		s, p, g: out std_logic
    );
end entity;

architecture rtl1 of CarryLookAheadAdder is
begin
	
	g <= a and b;
	p <= a or b;
	s <= a xor b xor cin;
	
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity NextCarry is
	generic(
        lengthOfGroup: integer := 4
    );
	port(
		P, G: in std_logic_vector(lengthOfGroup - 1 downto 0);
		cin: in std_logic;
		Cout: out std_logic_vector(lengthOfGroup - 1 downto 0)
    );
end entity;

architecture rtl2 of NextCarry is

	signal C: std_logic_vector(lengthOfGroup downto 0);

begin
	
	C(0) <= cin;
	logic:
	for i in 1 to lengthOfGroup generate
		C(i) <= G(i - 1) or (P(i - 1) and C(i - 1)); 
	end generate;

	Cout <= C(lengthOfGroup downto 1);

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library work;
use work.add.all;

entity GenericAdder is
	generic(
		lengthOfWord: integer := 16;
		lengthOfGroup: integer := 4
    );
	port(
		A, B: in std_logic_vector(lengthOfWord - 1 downto 0);
		S: out std_logic_vector(lengthOfWord - 1 downto 0);
		cin: in std_logic;
		Cout: out std_logic_vector(lengthOfWord - 1 downto 0)
    );
end entity;

architecture rtl3 of GenericAdder is

	signal C: std_logic_vector(lengthOfWord downto 0);
	signal P, G: std_logic_vector(lengthOfWord - 1 downto 0);

begin

	C(0) <= cin;
	
	adder_element: for i in 0 to lengthOfWord - 1 generate
		ADDX: CarryLookAheadAdder
			port map(
                a => A(i),
                b => B(i),
                cin => C(i),
                s => S(i),
                p => P(i),
                g => G(i)
            );
	end generate;
	
	carry_element: for i in 0 to (lengthOfWord / lengthOfGroup) - 1 generate
		CARRYX: NextCarry
			generic map(lengthOfGroup)
			port map(
                P => P((i + 1) * lengthOfGroup - 1 downto i * lengthOfGroup),
				G => G((i + 1) * lengthOfGroup - 1 downto i * lengthOfGroup),
				cin => C(i * lengthOfGroup),
                Cout => C((i + 1) * lengthOfGroup downto i * lengthOfGroup + 1)
            );
	end generate;
	
	Cout <= C(lengthOfWord downto 1);
	
end architecture;
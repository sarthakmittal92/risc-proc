library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end entity;

architecture rtl of testbench is

    component processor is
        port(
            reset, clk: in std_logic;
            Disp: out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk, reset: std_logic := '0';
	signal disp: std_logic_vector(15 downto 0);

begin

    process
    begin

        wait for 5 ns;
        clk <= not clk;
		
    end process;
    
    process
    begin

        reset <= '1';
        wait until (clk = '1');
        wait until (clk = '1');
        reset <= '0';
        wait;

    end process;

    instance: processor
    port map(
        reset => reset,
        clk => clk,
        Disp => disp
    );
    
end architecture;
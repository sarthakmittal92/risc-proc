library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bootload is 
	port(
		start, clk, reset, RX: in std_logic;
		address: out std_logic_vector(15 downto 0);
		data: out std_logic_vector(15 downto 0);
		enable, finish: out std_logic
    );
end entity;

architecture rtl1 of bootload is
    
	component DataBL is
		port(
			clk, reset, RX: in std_logic;
			T: in std_logic_vector(6 downto 0);
			S: out std_logic_vector(2 downto 0);
			address: out std_logic_vector(15 downto 0);
			data: out std_logic_vector(15 downto 0);
			enable: out std_logic
        );
	end component;
	
    component ControlBL is
		port(
			start, clk, reset: in std_logic;
			T: out std_logic_vector(6 downto 0);
			S: in std_logic_vector(2 downto 0);
			finish: out std_logic
        );
	end component;

	signal T: std_logic_vector(6 downto 0);
	signal S: std_logic_vector(2 downto 0);

begin

	DataPath: DataBL
        port map(
            clk => clk,
            reset => reset,
            RX => RX,
            T => T,
            S => S,
            address => address,
            data => data,
            enable => enable
        );
		
	ControlPath: ControlBL
        port map(
            clk => clk,
            reset => reset,
            start => start,
            T => T,
            S => S,
            finish => finish
        );
		
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ControlBL is
	port(
		start, clk, reset: in std_logic;
		T: out std_logic_vector(6 downto 0);
		S: in std_logic_vector(2 downto 0);
		finish: out std_logic
    );
end entity;

architecture rtl2 of ControlBL is

	type state is (S0, S1, S2_1, S2_2, S3_1, S3_2, S4);
	signal Q, nQ: state := S0;

begin

	clock: process(clk)
	begin

		if(clk'event and clk = '1') then	
			Q <= nQ;
		end if;

	end process;
	
	main: process(S, reset, start, Q)
	begin

		T <= (others => '0');
		finish <= '0';

		if (reset = '1') then
			nQ <= S0;
		else
			nQ <= Q;

			case Q is

				when S0 =>
					if (start = '1') then nQ <= S1;
					end if;
                
				when S1 =>
					if (S(0) = '1') then 
						if (S(1) = '1') then nQ <= S4;
						else 
							nQ <= S2_1;
							T(4) <= '1';
							T(5) <= '1';
						end if;
					end if;
                
				when S2_1 =>
					if (S(0) = '1') then 
						T(0) <= '1';
						nQ <= S2_2;
					end if;
                
				when S2_2 =>
					if (S(0) = '1') then 
						T(1) <= '1';
						nQ <= S3_1;
					end if;
                
				when S3_1 =>
					if (S(0) = '1') then
						T(2) <= '1';
						T(3) <= '1';
						T(5) <= '1';
						nQ <= S3_2;
					end if;
                
				when S3_2 =>
					if (S(0) = '1') then nQ <= S3_1;
						T(6) <= '1';
						T(3) <= '1';
						T(0) <= '1';
						T(1) <= '1';
						if (S(2) = '1') then nQ <= S1;
						end if;
					end if;
                
				when S4 =>
					finish <= '1';
					nQ <= S0;
                
				when others =>
					nQ <= S4;
                
			end case;
        
		end if;
    
	end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity DataBL is
	port(
		clk, reset, RX: in std_logic;
		T: in std_logic_vector(6 downto 0);
		S: out std_logic_vector(2 downto 0);
		address: out std_logic_vector(15 downto 0);
		data: out std_logic_vector(15 downto 0);
		enable: out std_logic
    );
end entity;

architecture data of DataBL is

	component UnivAsyncRecTrans is 
		port(
			data: out std_logic_vector(7 downto 0); 
			received: out std_logic;
			clock, reset: in std_logic;
			RX: in std_logic
        );
	end component;

	signal a_in, d_in, d_out, a_out: std_logic_vector(15 downto 0);
	signal DataForUART, c_in, c_out: std_logic_vector(7 downto 0);
	signal a_ena, d_ena, c_ena: std_logic;
    
begin

	a_in <= (DataForUART & "00000000") when (T(0) = '1' and T(1) = '0') else
        std_logic_vector(unsigned(a_out) + to_unsigned(1,16)) when (T(0) = '1' and T(1) = '1') else
        std_logic_vector(unsigned(a_out(15 downto 8) & DataForUART) - to_unsigned(1,16));
    
	a_ena <= T(0) or T(1);

	addr: Register
		generic map(16)
		port map(
			Din => a_in,
            Dout => a_out,
            clk => clk,
            ena => a_ena,
            clr => reset
        );
	
	d_in <= (DataForUART & "00000000") when (T(2) = '1') else
        (d_out(15 downto 8) & DataForUART);

	d_ena <= T(3);

	dat: Register
		generic map(16)
		port map(
			Din => d_in,
            Dout => d_out,
            clk => clk,
            ena => d_ena,
            clr => reset
        );
	
	c_in <= DataForUART when (T(4) = '1') else 
		std_logic_vector(unsigned(c_out) - to_unsigned(1,8));
    
	c_ena <= T(5);

	count: Register
		generic map(8)
		port map(
			Din => c_in,
            Dout => c_out,
            clk => clk,
            ena => c_ena,
            clr => reset
        );
	
	address <= a_out;
	data <= d_out;
	
	ena: process(clk)
	begin

		if(clk'event and clk = '1') then
			enable <= T(6);
		end if;

	end process;
	
	S(1) <= '1' when (DataForUART = "00000000") else '0';

	S(2) <= '1' when (c_out = "00000000") else '0';

	reception: UnivAsyncRecTrans
		port map(
            RX => RX,
            clock => clk,
            received => S(0),
            data => DataForUART,
            reset => reset
        );
			
end architecture;
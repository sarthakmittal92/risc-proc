library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.basic.all;

entity lmsm is 
	port(
		input: in std_logic_vector(7 downto 0);
		LM, SM ,clk, reset: in std_logic;
		AR2 : out std_logic_vector(2 downto 0);
		AR3 : out std_logic_vector(2 downto 0);
		clear, disable, RF_DO1_mux, ALU2_mux, AR3_mux, mem_in_mux, AR2_mux, input_mux: out std_logic
    );
end entity;

architecture rtl of lmsm is
    
    type state is (S1, S2, S3,S4);
    signal Q, nQ: state;
    signal set_zero,valid,invalid_next , enable :std_logic := '0';
    signal address :std_logic_vector(2 downto 0) := "000";

component lsm is
    
	generic(widthOfInput: integer := 8);
	port(
		input: in std_logic_vector(widthOfInput-1 downto 0);
		ena, clk, set_zero, reset: in std_logic;
		valid, invalid_next: out std_logic;
		address: out std_logic_vector(integer(ceil(log2(real(widthOfInput))))-1 downto 0)
    );
end component;

begin

 	LS: lsm
		generic map(8)
		port map(
            input => input,
            ena => enable,
            clk => clk, 
            reset => reset, 
            set_zero => set_zero, 
            valid => valid, 
            invalid_next => invalid_next,
            address => address
        );

	clock: process(clk)
	begin

		if (clk'event and clk = '1') then
			Q <= nQ;
		end if;

	end process;

	mealy: process(clk,reset,Q,LM,SM, address, valid, invalid_next)
	begin

		set_zero <= '0';
		input_mux <= '0';

		case Q is
            
			when S1 =>
				set_zero <= '0';
				clear <= '0';
				disable <= '0';
				enable <= LM or SM;  -- for LSM
				AR2 <= address;
				AR3 <= address;
				if(LM = '1') then 
					nQ <= S2;
				elsif(SM = '1') then
					nQ <= S3;	
				else 
					nQ <= S1;
					AR2 <= (others => '-');
					AR3 <= (others => '-');
				end if;

				RF_DO1_mux <= '0';
				AR2_mux <= '0';
				
				if (LM = '1') then 
					mem_in_mux <= '1'; 
					ALU2_mux <= '1';
					AR3_mux <= '1'; 
					input_mux <= '1';
					disable <= '1';   -- LM stops at IDRR
				else     			  -- control for RREX
					mem_in_mux <= '0'; 
					ALU2_mux <= '0';
					AR3_mux <= '0';
					input_mux <= '0';
				end if; 

			when S2 => 
				if(valid = '1') then
					set_zero <= '1';
					clear <= '0';
					nQ <= S2;
					disable <= '1';
					enable <= '0';

					input_mux <= '1';
					RF_DO1_mux <= '1';
					AR2_mux <= '0';
					mem_in_mux <= '1';
					ALU2_mux <= '1';
					AR3_mux <= '1';
					AR2 <= (others => '-');
					AR3 <= address;
				
				elsif (SM = '1') then
					enable <= '1';
					set_zero <= '0';
					clear <= '0';
					disable <= '0';
					nQ <= S3;

					input_mux <= '0';
					RF_DO1_mux <= '1';
					AR2_mux <= '0';
					mem_in_mux <= '1';
					ALU2_mux <= '1';
					AR3_mux <= '1';
					AR2 <= address;
					AR3 <= address;
					
				else  
					nQ <= S1;
					clear <= '1';				-- RREX reg clear
					disable <= '0';			
					enable <= '0';
					set_zero <= '1';
					--------------
					RF_DO1_mux <= '0';
					AR2_mux <= '0';
					mem_in_mux <= '0';
					ALU2_mux <= '0';
					AR3_mux <= '0';
					input_mux <= '0';
					AR2 <= (others => '-');
					AR3 <= (others => '-');
				
				end if;
				
			when S3 =>  
				set_zero <= '1';
				nQ <= S4;
				enable <= '0';
				clear <= '0';
				disable <= '0';

				RF_DO1_mux <= '0';
				AR2_mux <= '1';
				mem_in_mux <= '1';
				ALU2_mux <= '1';
				AR3_mux <= '0';
				AR2 <= address;
				AR3 <= (others => '-');
				
			when S4 => 
				if(valid = '1') then
					set_zero <= '1' ;
					nQ <= S4;
					disable <= '1'; -- disables PC reg in IFID, IDRR and RREX
					clear <= '0';
					enable <= '0';

					RF_DO1_mux <= '1';
					AR2_mux <= '1';
					mem_in_mux <= '1';
					ALU2_mux <= '1';
					AR3_mux <= '0';
					AR2 <= address;
					AR3 <= (others => '-');
				else  
					nQ <= S1;
					clear <= '0';		-- no clearing for SM
					disable <= '0';
					enable <= '0';

					RF_DO1_mux <= '0';
					AR2_mux <= '0';
					mem_in_mux <= '0';
					ALU2_mux <= '0';
					AR3_mux <= '0';
					AR2 <= (others => '-');
					AR3 <= (others => '-');
				end if;

		end case;

	end process;

end architecture;
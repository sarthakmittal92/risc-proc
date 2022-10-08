library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity decoder is
	port(
		INS: in std_logic_vector(15 downto 0);
		SE9_6, ID_PC, LS_PC, LLI: out std_logic; 
		LM, SM, LW, SE_DO2, BEQ: out std_logic;
		WB_mux, AR1, AR2, AR3, valid, Flag_C: out std_logic_vector(2 downto 0);
		ALU_C, Cond, WR: out std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of decoder is

	signal RA, RB, RC: std_logic_vector(0 to 2);
    
begin

	RA <= INS(11 downto 9);
	RB <= INS(8 downto 6);
	RC <= INS(5 downto 3);
	
	MAIN: process(INS, RA, RB, RC)
	begin

		-- Defaults
		SE9_6 <= '-';
		LS_PC <= '-';
		LLI <= '0';
		Cond <= INS(1 downto 0);
		ID_PC <= '0';
		BEQ <= '0';
		LM <= '0';
		SM <= '0';
		LW <= '0';
		SE_DO2 <= '0';
		WB_mux <= "000";
		ALU_C <= "10";
		Flag_C <= "111";
		WR <= "10";
		valid <= "111";
		
		AR1 <= RA;
		AR2 <= RB;
		AR3 <= RC;
		
		-- Conditional
		case INS(15 downto 12) is

			when "0000" => 			-- Add

			when "0001" =>			-- Add immediate
				SE9_6 <= '1';
				SE_DO2 <= '1';
				AR2 <= "---";
				AR3 <= RB;
				valid <= "101";
				Cond <= "00";
            
			when "0010" =>			-- Nand
				ALU_C <= "00";
				
			when "0011" =>			-- LHI
				SE9_6 <= '0';
				LS_PC <= '1';
				SE_DO2 <= '-';
				WB_mux <= "001";
				ALU_C <= "--";
				Flag_C <= "000";
				AR1 <= "---";
				AR2 <= "---";
				AR3 <= RA;
				valid <= "001";
				
			when "1011" => 			-- LLI
				SE9_6 <= '0';
				LLI <= '1';
				SE_DO2 <= '-';
				WB_mux <= "010";
				ALU_C <= "--";
				Flag_C <= "000";
				AR1 <= "---";
				AR2 <= "---";
				AR3 <= RA;
				valid <= "001";
				
			when "0100" =>			-- Load
				SE9_6 <= '1';
				LW <= '1';
				SE_DO2 <= '1';
				WB_mux <= "100";
				Flag_C <= "001";
				AR1 <= RB;
				AR2 <= "---";
				AR3 <= RA;
				valid <= "101";
				
			when "0101" => 			-- Store
				SE9_6 <= '1';
				SE_DO2 <= '1';
				WB_mux <= "---";
				Flag_C <= "000";
				WR <= "01";
				AR1 <= RB;
				AR2 <= RA;
				AR3 <= "---";
				valid <= "110";
				
			when "0110" => 			-- LM
				LM <= '1';
				SE_DO2 <= '-';
				WB_mux <= "100";
				Flag_C <= "000";
				AR2 <= "---";
				AR3 <= "---";
				valid <= "101";
				
			when "0111" =>			-- SM
				SM <= '1';
				SE_DO2 <= '-';
				WB_mux <= "---";
				Flag_C <= "000";
				WR <= "01";
				AR2 <= "---";
				AR3 <= "---";
				valid <= "110";
				
			when "1100" =>			-- BEQ
				SE9_6 <= '1';
				LS_PC <= '0';
				BEQ <= '1';
				WB_mux <= "---";
				ALU_C <= "01";
				Flag_C <= "000";
				WR <= "00";
				AR3 <= "---";
				valid <= "110";
				
			when "1000" =>			-- JAL
				SE9_6 <= '0';
				ID_PC <= '1';
				LS_PC <= '0';
				SE_DO2 <= '-';
				WB_mux <= "011";
				ALU_C <= "--";
				Flag_C <= "000";
				WR <= "10";
				AR1 <= "---";
				AR2 <= "---";
				AR3 <= RA;
				valid <= "001";
				
			when "1001" =>			-- JLR
				SE_DO2 <= '-';
				WB_mux <= "011";
				ALU_C <= "--";
				Flag_C <= "000";
				WR <= "10";
				AR1 <= RB;
				AR2 <= "---";
				AR3 <= RA;
				valid <= "101";
				
			when others =>

		end case;

	end process;

end architecture;
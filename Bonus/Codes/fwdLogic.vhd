library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fwdLogic is
	port( 
        IDRR_AR: in std_logic_vector(2 downto 0);
        IDRR_PC : in std_logic_vector(15 downto 0);
        IDRR_AR_valid : in std_logic;
        clk : in std_logic;
        
        RREX_mux_control : in std_logic_vector(2 downto 0);
        RREX_AR3_valid : in std_logic;
        RREX_AR3 : in std_logic_vector(2 downto 0);
        RREX_ALU_out : in std_logic_vector(15 downto 0);
        RREX_LS_PC : in std_logic_vector(15 downto 0);
        RREX_SE : in std_logic_vector(15 downto 0);
        RREX_PC_inc : in std_logic_vector(15 downto 0);	
        
        EXMM_mux_control : in std_logic_vector(2 downto 0);
        EXMM_AR3_valid : in std_logic;
        EXMM_AR3 : in std_logic_vector(2 downto 0);
        EXMM_ALU_out : in std_logic_vector(15 downto 0);
        EXMM_LS_PC : in std_logic_vector(15 downto 0);
        EXMM_SE : in std_logic_vector(15 downto 0);
        EXMM_PC_inc : in std_logic_vector(15 downto 0);
        EXMM_mem_out: in std_logic_vector(15 downto 0);
        
        MMWB_AR3_valid : in std_logic;
        MMWB_AR3 : in std_logic_vector(2 downto 0);
        MMWB_data : in std_logic_vector(15 downto 0);		  
        
        DO_fwd_control : out std_logic;
        DO_fwd_data : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of fwdLogic is

	signal EXMM_data, RREX_data : std_logic_vector(15 downto 0);

begin
			
	RREX_data <= RREX_ALU_out when (RREX_mux_control = "000") else
		RREX_LS_PC when (RREX_mux_control = "001") else
		RREX_SE when (RREX_mux_control = "010") else
		RREX_PC_inc when (RREX_mux_control = "011") else
		(others => '-');
			
	EXMM_data <= EXMM_ALU_out when (EXMM_mux_control = "000") else
		EXMM_LS_PC when (EXMM_mux_control = "001") else
		EXMM_SE when (EXMM_mux_control = "010") else
		EXMM_PC_inc when (EXMM_mux_control = "011") else
		EXMM_mem_out when (EXMM_mux_control = "100") else
		(others => '-');
	
	process(clk, RREX_data, EXMM_data, MMWB_data, IDRR_AR_valid, RREX_AR3_valid,
        EXMM_AR3_valid, MMWB_AR3_valid, IDRR_AR, IDRR_PC, RREX_AR3, EXMM_AR3, MMWB_AR3)

	begin

		DO_fwd_control <= '0';
		DO_fwd_data <= (others => '-');

		if (IDRR_AR_valid = '1') then
			DO_fwd_control <= '1';
			if (IDRR_AR = "111") then
				DO_fwd_data <= IDRR_PC;
			elsif ((RREX_AR3_valid = '1') and (IDRR_AR = RREX_AR3)) then
				DO_fwd_data <= RREX_data;
			elsif ((EXMM_AR3_valid = '1') and (IDRR_AR = EXMM_AR3)) then
				DO_fwd_data <= EXMM_data;
			elsif((MMWB_AR3_valid = '1') and (MMWB_AR3 = IDRR_AR)) then
				DO_fwd_data <= MMWB_data;
			else
				DO_fwd_control <= '0';
			end if;
		end if;

	end process;

end architecture;
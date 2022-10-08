library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hzdLogic is 
	port( 
		AR3_IDRR : in std_logic_vector(2 downto 0);
		IDRR_valid : in std_logic_vector(2 downto 0);
		SE_IDRR    : in std_logic_vector(15 downto 0);
		LS_PC_IDRR : in std_logic_vector(15 downto 0);
		DO1_IDRR   : in std_logic_vector(15 downto 0);
		opcode	    : in std_logic_vector(3 downto 0);
		clk: in std_logic;
		
		clear : out std_logic := '0';
		top_mux_RR_control : out std_logic;
		data_mux_RR: out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl1 of hzdLogic is

	signal LLI_R7_flush, LHI_R7_flush, JLR : std_logic := '0';
	signal clear_temp :std_logic := '0';

begin

	clear <= clear_temp;
	top_mux_RR_control   <= clear_temp;

	LHI_R7_flush <= '1' when(opcode = "0011" and AR3_IDRR = "111" and IDRR_valid(0) = '1') else '0';
	LLI_R7_flush <= '1' when(opcode = "1011" and AR3_IDRR = "111" and IDRR_valid(0) = '1') else '0';
	JLR  	     <= '1' when(opcode = "1001") else '0';
	data_mux_RR  <= SE_IDRR when(LLI_R7_flush = '1') else LS_PC_IDRR when(LHI_R7_flush = '1') else DO1_IDRR;
	clear_temp   <= LHI_R7_flush or LLI_R7_flush or JLR;

end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity stall is
	port( 
		decoder_AR1 : in std_logic_vector(2 downto 0);
		decoder_AR2 : in std_logic_vector(2 downto 0);
		IDRR_LW : in std_logic;
		IF_ID_cond : in std_logic_vector(1 downto 0);

		IDRR_AR3 : in std_logic_vector(2 downto 0);
		IDRR_valid : in std_logic_vector(2 downto 0);
		decoder_valid : in std_logic_vector(2 downto 0);
		opcode_IDRR, opcode_IF_ID : in std_logic_vector(3 downto 0);
		clk: in std_logic;
		
		disable_out : out std_logic := '0';
		SM_start_control : out std_logic := '0';
		clear : out std_logic := '0'
    );
end entity;

architecture rtl2 of stall is

	signal disable : std_logic := '0';

begin

	process(opcode_IDRR, opcode_IF_ID, clk, decoder_AR1, decoder_AR2, IDRR_LW, IDRR_valid,
        IDRR_AR3, decoder_valid, IF_ID_cond)
	begin

		SM_start_control <= '0';
		disable <= '0';

		if (IDRR_LW = '1') then
			if (opcode_IF_ID = "0101" and (decoder_AR2 = IDRR_AR3)) then
				disable <= '0';
			elsif (opcode_IF_ID = "0111") then
				if (decoder_AR1 = IDRR_AR3) then
					disable <= '1';
					SM_start_control <= '1';
				end if;
			elsif (((decoder_AR1 = IDRR_AR3) and decoder_valid(2) = '1') or ((decoder_AR2 = IDRR_AR3) and decoder_valid(1) = '1')) then
				disable <= '1';
			elsif (((opcode_IF_ID(3 downto 2) & opcode_IF_ID(0)) = "000") and (IF_ID_cond = "01")) then
				disable <= '1';
			end if;
		end if;

	end process;
	
	clear <= disable;
	disable_out <= disable;

end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hzdEX is
	port( 
		RREX_AR3, RREX_valid, RREX_mux_control  : in std_logic_vector(2 downto 0);
		RREX_opcode : in std_logic_vector(3 downto 0);
		EXMM_FC, MMWB_FC : in std_logic;
		RREX_C : in std_logic_vector(1 downto 0);
		EXMM_F, MMWB_F, F, alu_F : in std_logic_vector(2 downto 0);
		ALU_out, PC_inc, SE_PC : in  std_logic_vector(15 downto 0);
		beq_is_taken, beq_bit: in std_logic;
		table_toggle : out std_logic;
		pass_beq_taken : out std_logic;
		top_EX_mux_data : out std_logic_vector(15 downto 0);
		top_EX_mux : out std_logic;
		flush,clear_current : out std_logic;
		clk : in std_logic
    );
end entity;

architecture rtl3 of hzdEX is

	signal R7_update : std_logic := '0';
	signal valid_flags : std_logic_vector(2 downto 0);
	signal cond_ar_ins : std_logic := '0';
	signal false_cond_ar : std_logic := '0';
	signal ar_ins : std_logic := '0';
	signal tmp_table_toggle : std_logic := '0';

begin

	ar_ins <= ((not RREX_opcode(3)) and (not RREX_opcode(2))) and (not (RREX_opcode(0) and RREX_opcode(1))); 
	cond_ar_ins <= '1' when ((RREX_C /= "00") and (ar_ins = '1')) else '0';
	false_cond_ar <= '1' when ((cond_ar_ins = '1') and (((RREX_C = "01") and (valid_flags(0) = '0')) or ((RREX_C = "10") and (valid_flags(1) = '0')) or ((RREX_C = "11") and (valid_flags(2) = '0')))) else '0';
	
	process (clk, MMWB_F, MMWB_FC, EXMM_F, EXMM_FC, F)
	begin

		valid_flags <= F;
		if (EXMM_FC = '1') then
			valid_flags <= EXMM_F;
		elsif (MMWB_FC = '1') then
			valid_flags <= MMWB_F;
		end if;
    
	end process;
	
	clear_current <= false_cond_ar;
	
	process (false_cond_ar, RREX_AR3, RREX_valid, RREX_mux_control, ar_ins, ALU_out, beq_bit,
        beq_is_taken, alu_F, PC_inc, SE_PC)
	begin

		R7_update <= '0';
		tmp_table_toggle <= '0';
		top_EX_mux_data <= (others => '0');

		if (RREX_AR3 = "111" and RREX_valid(0) = '1' and ar_ins = '1') then
			if (false_cond_ar = '0') then
				R7_update <= '1';
				top_EX_mux_data <= ALU_out;
			end if;
		elsif (beq_bit = '1') then
			if (beq_is_taken = '1' and alu_F(0) = '0') then --beq not taken but taken
				R7_update <= '1';
				top_EX_mux_data <= PC_inc;
				tmp_table_toggle <= '1';
			elsif (beq_is_taken = '0' and alu_F(0) = '1') then 
				R7_update <= '1';
				top_EX_mux_data <= SE_PC;
				tmp_table_toggle <= '1';
			end if;	
		end if;

	end process;
	
	flush <= R7_update;
	top_EX_mux <= R7_update;
	table_toggle <= tmp_table_toggle;
	pass_beq_taken <= beq_is_taken xor tmp_table_toggle;
	
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hzdMM is 
	port( 
		EXMM_AR3,EXMM_valid,EXMM_mux_control : in std_logic_vector(2 downto 0);
		EXMM_flags : in std_logic_vector(2 downto 0);
		m_out : in std_logic_vector(15 downto 0);
		MM_flags_out : out std_logic_vector(2 downto 0);
		top_MM_mux : out std_logic;
		clear : out std_logic
    );
end entity;

architecture rtl4 of hzdMM is 
begin

	top_MM_mux <= '1' when (EXMM_AR3 = "111" and EXMM_valid(0) = '1' and EXMM_mux_control = "100") else '0';
	clear 	   <= '1' when (EXMM_AR3 = "111" and EXMM_valid(0) = '1' and EXMM_mux_control = "100") else '0';
	MM_flags_out(2 downto 1) <= EXMM_flags(2 downto 1);
	MM_flags_out(0) <= '1' when (m_out = "0000000000000000" and EXMM_mux_control = "100") else '0';

end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hzdCondWB is 
	port( 
		AR3_MMWB: in std_logic_vector(2 downto 0);
		MMWB_LS_PC, MMWB_PC_inc : in std_logic_vector(15 downto 0);
		
		MMWB_valid		  : in std_logic_vector (2 downto 0);

		r7_write, top_WB_mux_control, clear: out std_logic;
		r7_select 	: out std_logic_vector(1 downto 0);
		top_WB_mux_data : out std_logic_vector(15 downto 0);

		is_taken	: in std_logic;
		opcode		: in std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl5 of hzdCondWB is

	signal JLR_flush, JAL_flush, flush: std_logic;

begin 

	JLR_flush <= '1' when ( opcode = "1001" and AR3_MMWB = "111" and MMWB_valid(0) = '1') else '0';
	JAL_flush <= '1' when ( opcode = "1000" and AR3_MMWB = "111" and MMWB_valid(0) = '1') else '0';
 	
	flush <= (JLR_flush or JAL_flush);
	clear 	       	   <= flush;
	top_WB_mux_control <= flush; 
	top_WB_mux_data    <= MMWB_PC_inc when (flush = '1') else 
        (others => '0');
	
  	r7_select <= "00"  when(opcode = "1001") else "10" when( is_taken = '1' or opcode = "1000") else "01";

	r7_write <= '0'  when(AR3_MMWB = "111" and MMWB_valid(0) = '1') else '1';  -- Since PC+1 will be written using Reg write

end architecture;
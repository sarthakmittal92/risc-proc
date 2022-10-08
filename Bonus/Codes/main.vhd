library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.basic.all;
use work.pipeReg.all;

entity processor is
	port(
		clk, reset: in std_logic;
		Disp: out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of processor is

	component romSim is
		generic(
            noOfWords: integer := 256;
			lengthOfWord: integer := 16
        );
		port(
			address: in std_logic_vector(lengthOfWord-1 downto 0);
			data_out: out std_logic_vector(lengthOfWord-1 downto 0);
			rd_ena ,clk : in std_logic
        );
	end component;
	
	component branchLookUp is
		port(
			clk, reset, is_BEQ, toggle: in std_logic;
			new_PC_in, PC_in, BA_in: in std_logic_vector(15 downto 0);
			BA: out std_logic_vector(15 downto 0);
			is_taken: out std_logic;
			address_in: in std_logic_vector(2 downto 0);
			address_out: out std_logic_vector(2 downto 0)
        );
	end component;
	
	component decoder is
		port(
			INS: in std_logic_vector(0 to 15);
			SE9_6, ID_PC, LS_PC, LLI: out std_logic; 
			LM, SM, LW, SE_DO2, BEQ: out std_logic;
			WB_mux, AR1, AR2, AR3, valid, Flag_C: out std_logic_vector(2 downto 0);
			ALU_C, Cond, WR: out std_logic_vector(1 downto 0)
        );
	end component;
	
	component extend is
		generic(
            widthOfOutput: integer := 16
        );
		port(
			input: in std_logic_vector(widthOfOutput-1 downto 0);
			output: out std_logic_vector(widthOfOutput-1 downto 0);
			sel_6_9, bypass: in std_logic
        );
	end component;
	
	component lmsm is 
		port(
			input: in std_logic_vector(7 downto 0);
			LM, SM ,clk, reset: in std_logic;
			AR2 : out std_logic_vector(2 downto 0);
			AR3 : out std_logic_vector(2 downto 0);
			clear, disable, RF_DO1_mux, ALU2_mux, AR3_mux, mem_in_mux, AR2_mux, input_mux: out std_logic
        );
	end component;
	
	component fwdLogic is 
		port(
            IDRR_AR: in std_logic_vector(2 downto 0);
            IDRR_PC : in std_logic_vector(15 downto 0);
            IDRR_AR_valid : in std_logic;
            clk : in std_logic;

            RREX_mux_control : in std_logic_vector(2 downto 0);
            RREX_AR3_valid : in std_logic;
            RREX_AR3 : in std_logic_vector(2 downto 0);
            RREX_ALU_out : in std_logic_vector(15 downto 0); -- ALU output
            RREX_LS_PC : in std_logic_vector(15 downto 0);
            RREX_SE : in std_logic_vector(15 downto 0);
            RREX_PC_inc : in std_logic_vector(15 downto 0);	

            EXMM_mux_control : in std_logic_vector(2 downto 0);
            EXMM_AR3_valid : in std_logic;
            EXMM_AR3 : in std_logic_vector(2 downto 0);
            EXMM_ALU_out : in std_logic_vector(15 downto 0); -- EXMM reg
            EXMM_LS_PC : in std_logic_vector(15 downto 0);
            EXMM_SE : in std_logic_vector(15 downto 0);
            EXMM_PC_inc : in std_logic_vector(15 downto 0);
            EXMM_mem_out: in std_logic_vector(15 downto 0); -- mem output

            MMWB_AR3_valid : in std_logic;
            MMWB_AR3 : in std_logic_vector(2 downto 0);
            MMWB_data : in std_logic_vector(15 downto 0);	

            DO_fwd_control : out std_logic;
            DO_fwd_data : out std_logic_vector(15 downto 0)
        );
	end component;

	component hzdLogic is 
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
	end component;
	
	component stall is 
		port( 
			decoder_AR1 : in std_logic_vector(2 downto 0);
			decoder_AR2 : in std_logic_vector(2 downto 0);
			IDRR_LW : in std_logic;
			IFID_cond : in std_logic_vector(1 downto 0);

			IDRR_AR3 : in std_logic_vector(2 downto 0);  -- LW (IDRR)
			IDRR_valid : in std_logic_vector(2 downto 0);
			decoder_valid : in std_logic_vector(2 downto 0);
			opcode_IDRR, opcode_IFID : in std_logic_vector(3 downto 0);
			clk: in std_logic;

			disable_out : out std_logic := '0';
			SM_start_control : out std_logic := '0';
			clear : out std_logic := '0'
        );
	end component;

	component regFile is
		generic(
			lengthOfWord: integer := 16;
			noOfWords: integer := 8
        );
		port(
			data_in, R7_in: in std_logic_vector(lengthOfWord-1 downto 0);
			data_out1, data_out2, R0: out std_logic_vector(lengthOfWord-1 downto 0);
			sel_in, sel_out1, sel_out2: in std_logic_vector(integer(ceil(log2(real(noOfWords))))-1 downto 0);
			clk, wr_ena, R7_ena, reset: in std_logic
        );
	end component;	
	
	component alu is
		generic(
            lengthOfWord: integer := 16
        );
		port(
			input1, input2: in std_logic_vector(lengthOfWord-1 downto 0);
			output: out std_logic_vector(lengthOfWord-1 downto 0);
			cin: in std_logic;
			sel: in std_logic_vector(1 downto 0);
			CY, OV, Z: out std_logic
        );
	end component;
	
	component hzdEX is 
		port( 
			RREX_AR3, RREX_valid, RREX_mux_control  : in std_logic_vector(2 downto 0);
			RREX_opcode : in std_logic_vector(3 downto 0);
			EXMM_FC, MMWB_FC : in std_logic;
			RREX_C : in std_logic_vector(1 downto 0);	-- cond
			EXMM_F, MMWB_F, F, alu_F : in std_logic_vector(2 downto 0);  -- EXMM flags (from hzdMM)
			ALU_out, PC_inc, SE_PC : in  std_logic_vector(15 downto 0);
			beq_is_taken, beq_bit: in std_logic;
			table_toggle : out std_logic;
			pass_beq_taken : out std_logic;
			top_EX_mux_data : out std_logic_vector(15 downto 0);
			top_EX_mux : out std_logic;
			flush,clear_current : out std_logic;
			clk : in std_logic
        );
	end component;
	
	component ramSim is
		generic(
			lengthOfWord: integer := 16;
			noOfWords: integer := 256
        );
		port(
			data_in: in std_logic_vector(lengthOfWord-1 downto 0);
			data_out : out std_logic_vector(lengthOfWord-1 downto 0);
			address: in std_logic_vector(lengthOfWord-1 downto 0);
			clk, wr_ena, rd_ena, reset: in std_logic
        );	
	end component;
	
	component mmFwd is
		port( 
			EXMM_AR2, MMWB_AR3 : in std_logic_vector(2 downto 0);
			op_MMWB, op_EXMM : in std_logic_vector(3 downto 0);
			EXMM_AR2_valid, MMWB_AR3_valid : in std_logic;
			mem_fwd_mux : out std_logic;
			clk : in std_logic
        );
	end component;

	component hzdMM is 
		port( 
			EXMM_AR3,EXMM_valid,EXMM_mux_control : in std_logic_vector(2 downto 0);
			EXMM_flags : in std_logic_vector(2 downto 0);
			m_out : in std_logic_vector(15 downto 0);
			MM_flags_out : out std_logic_vector(2 downto 0);
			top_MM_mux : out std_logic;
			clear : out std_logic
        );
	end component;
	
	component hzdCondWB is 
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
	end component;

	signal BEQ_PC, JAL_PC: std_logic_vector(15 downto 0);
	signal unflush_out : std_logic_vector(0 downto 0);
	
	signal PC_in, PC_out, IM_AI, IM_DO, PCpp, BA: std_logic_vector(15 downto 0);
	signal PC_ena, is_BEQ, toggle, is_taken: std_logic;
	signal disable_IFID, clear_control_IFID, disable_IDRR, clear_control_IDRR: std_logic;
	signal BLUT_index_in, BLUT_index_out: std_logic_vector(2 downto 0);
	signal BLUT_ID, BLUT_RR: std_logic_vector(3 downto 0);
	
	signal PC_ID, PCpp_ID, INS_ID, SE_PC_ID, SE_ID: std_logic_vector(15 downto 0);	
	signal ALU_C_ID, Cond_ID, WR_ID: std_logic_vector(1 downto 0);
	signal LM_ID, LM_RR, lmsm_IDRR: std_logic_vector(7 downto 0);
	signal SE9_6, ID_PC, LLI, SM: std_logic;
	signal AR1_ID, AR2_ID, AR3_ID, FC_ID: std_logic_vector(2 downto 0);
	signal CL_ID, CL_RR: std_logic_vector(11 downto 0);
	signal SM_start_control, SM_block : std_logic;
	
	signal PC_RR, PCpp_RR, SE_PC_RR, SE_RR: std_logic_vector(15 downto 0);
	signal OP_RR: std_logic_vector(3 downto 0);
	signal ALU_C_RR, Cond_RR, WR_RR: std_logic_vector(1 downto 0);
	signal AR1_RR, AR2_RR, AR3_RR, AR2_DD, AR3_DD, FC_RR: std_logic_vector(2 downto 0);
	signal clear_lmsm, ALU2_mux, mem_in_mux, disable_lmsm, RF_DO1_mux, AR2_mux,AR3_mux, lmsm_input_sel: std_logic;
	signal LS_PC_RR, LS_RR, DO1_RR, DO2_RR : std_logic_vector (15 downto 0);
	signal hzdLogic_clear, top_mux_RR_control, stall_disable, stall_clear : std_logic; 
	signal top_mux_RR_data ,top_mux_RR: std_logic_vector(15 downto 0);
	
	signal AR2_RF : std_logic_vector(2 downto 0);
	signal DO1_RF, DO2_RF, F1_mux: std_logic_vector(15 downto 0);
	signal clear_control_RREX, disable_RREX: std_logic;
		
	signal CL_EX : std_logic_vector(12 downto 0);
	signal AR2_EX, AR3_EX, FC_EX, AR3_before_EX : std_logic_vector(2 downto 0);
	signal ALU_out, LS_PC_EX, SE_EX, PCpp_EX, DO1_EX, DO2_EX, top_mux_EX_data: std_logic_vector(15 downto 0);
	signal ALU_C_EX, Cond_EX, WR_EX : std_logic_vector(1 downto 0);
	signal fwd1_control, fwd2_control, reset_temp : std_logic;
	signal fwd1_data, fwd2_data, top_mux_EX: std_logic_vector(15 downto 0);
	signal BLUT_EX, OP_EX: std_logic_vector(3 downto 0);
	signal is_taken_EX, top_mux_EX_control, hzdEX_flush, hzdEX_clear_current: std_logic;
	
	signal SE_DO2, ALU2_input: std_logic_vector(15 downto 0);
	signal flags_EX, flags_user : std_logic_vector(2 downto 0);
		
	signal CL_MM : std_logic_vector(8 downto 0);
	signal AR3_MM, AR2_MM : std_logic_vector(2 downto 0);
	signal ALU_out_MM, LS_PC_MM, SE_MM, PCpp_MM, mem_out, DO1_MM, DO2_MM, top_mux_MM: std_logic_vector(15 downto 0);
	signal FC_MM, flags_MM, flags_MM_hazard: std_logic_vector(2 downto 0);
	signal clear_control_EXMM, hzdMM_clear, top_mux_MM_control, fwd_mux_control_MM : std_logic;
	signal WR_MM : std_logic_vector(1 downto 0);
	signal BLUT_MM, OP_MM : std_logic_vector(3 downto 0);
	signal mem_address, mem_data: std_logic_vector(15 downto 0);
	
	signal CL_WB : std_logic_vector(7 downto 0);
	signal AR3_WB, FC_WB, flags_WB : std_logic_vector(2 downto 0);
	signal D3_data, R7_in, LS_PC_WB, SE_WB, ALU_out_WB, mem_out_WB, DO1_WB, PCpp_WB: std_logic_vector(15 downto 0);
	signal WR_WB : std_logic_vector(1 downto 0);
	signal clear_control_MMWB : std_logic;
	signal BLUT_WB, OP_WB : std_logic_vector(3 downto 0);

	signal R7_write, top_mux_WB_control, hazard_WB_clear : std_logic;
	signal r7_select : std_logic_vector(1 downto 0);
	signal top_mux_WB_data : std_logic_vector(15 downto 0);
	
	signal concatenation_BLUT_IFID, concatenation_BLUT_EXMM: std_logic_vector(3 downto 0);
	signal concatenation_CL_RREX: std_logic_vector(12 downto 0);
	signal concatenation_CL_EXMM: std_logic_vector(8 downto 0);
	signal concatenation_CL_MMWB: std_logic_vector(7 downto 0);
	
	signal R7_write_temp: std_logic;

begin

	--------------------- IF --------------------------

	PC: Register
		generic map(16)
		port map(
			clk => clk,
            clr => reset,
            ena => PC_ena,
			Din => PC_in,
            Dout => PC_out
        );
	
	PC_ena	<= not(stall_disable or disable_lmsm);
	
	PCpp <= std_logic_vector(unsigned(PC_out) + to_unsigned(1,16));
	IM_AI <= PC_out;
	
	IM: romSim
		port map(
			address => IM_AI,
            data_out => IM_DO,
			rd_ena => '1',
            clk => clk
        );
	
	BLUT: branchLookUp
		port map(
            clk => clk,
            reset => reset,
            is_BEQ => is_BEQ,
            toggle => toggle,
            new_PC_in => PC_ID,
            PC_in => PC_out,
            BA_in => SE_PC_ID,
            is_taken => is_taken, 
            BA => BA,
            address_in => BLUT_index_in,
            address_out => BLUT_index_out
        );
		
	BEQ_PC <= PCpp when (is_taken = '0') else BA;
	
	--------------------- IF/ID pipeReg --------------------------

	concatenation_BLUT_IFID <= BLUT_index_out & is_taken;

	pipe_IFID: IFID
		port map(
            PC_in => PC_out,
            Inst_in => IM_DO,
            PC_inc_in => PCpp,
            clk => clk,
            clear => reset,
            clear_control => clear_control_IFID, 
            disable => disable_IFID,
            BLUT_in => concatenation_BLUT_IFID,
            Inst_out => INS_ID,
            PC_out => PC_ID,
            PC_inc_out => PCpp_ID,
            BLUT_out => BLUT_ID,
            unflush_out => unflush_out
        );

	clear_control_IFID <= (not disable_IDRR) and (ID_PC or hzdLogic_clear or hzdEX_flush or hzdMM_clear or hazard_WB_clear);	-- to clear IFID in case of JAL
	disable_IFID <= stall_disable or disable_lmsm;
	
	--------------------- ID --------------------------
	
	decode_ins: decoder
		port map(
			INS => INS_ID,
            SE9_6 => SE9_6,
            ID_PC => ID_PC,
            LS_PC => CL_ID(0),
			LLI => LLI,
            LM => CL_ID(2),
            SM => SM,
            LW => CL_ID(3), 
			SE_DO2 => CL_ID(4),
            BEQ => CL_ID(1),
            WB_mux => CL_ID(7 downto 5),
			AR1 => AR1_ID,
            AR2 => AR2_ID,
            AR3 => AR3_ID,
            valid => CL_ID(10 downto 8),
			ALU_C => ALU_C_ID,
            Flag_C => FC_ID,
            Cond => Cond_ID,
            WR => WR_ID
        );
	
	SE: extend
		port map(
			input => INS_ID,
            output => SE_ID, 
			sel_6_9 => SE9_6,
            bypass => LLI
        );
	
	lmsm_IDRR <= LM_RR when  (lmsm_input_sel = '1') else LM_ID; 			
	SE_PC_ID <= std_logic_vector(unsigned(PC_ID) + unsigned(SE_ID));
	JAL_PC <= BEQ_PC when (ID_PC = '0') else SE_PC_ID;
	is_BEQ <= CL_ID(1);
	CL_ID(11) <= unflush_out(0);
	
	--------------------- ID/RR pipeReg --------------------------
	
	LM_ID <= INS_ID(7 downto 0);

	pipe_IDRR: IDRR
		port map(
			PC_in => PC_ID,
            SE_PC_in => SE_PC_ID,
            SE_in => SE_ID,
			CL_in => CL_ID,
            ALU_C_in => ALU_C_ID,
            FC_in => FC_ID,
			Cond_in => Cond_ID,
            Write_in => WR_ID,
            AR1_in => AR1_ID,
			AR2_in => AR2_ID,
            AR3_in => AR3_ID,
            PC_inc_in => PCpp_ID, 
			LM_in => LM_ID,
            clk => clk,
            clear => reset, 
			clear_control => clear_control_IDRR,
            disable => disable_IDRR,
			PC_out => PC_RR,
            SE_PC_out => SE_PC_RR,
            SE_out => SE_RR, 
			CL_out => CL_RR,
            ALU_C_out => ALU_C_RR,
            FC_out => FC_RR, 
			Cond_out => Cond_RR,
            Write_out => WR_RR,
            AR1_out => AR1_RR,
            AR2_out => AR2_RR,
            AR3_out => AR3_RR,
			PC_inc_out => PCpp_RR,
            LM_out => LM_RR,
            op_in => INS_ID(15 downto 12),
			op_out => OP_RR,
            BLUT_in => BLUT_ID,
            BLUT_out => BLUT_RR
        );
			
	
	clear_control_IDRR <= (not disable_RREX) and (hzdLogic_clear or stall_clear or hzdEX_flush or hzdMM_clear or hazard_WB_clear); 
	disable_IDRR <= disable_lmsm;
	
	--------------------- RR --------------------------

	-- LMSM
	SM_block <= (not SM_start_control) and SM;
	lmsm_inst: lmsm
		port map(
            input => lmsm_IDRR,
            LM => CL_RR(2),
            SM => SM_block,
            clk => clk,
            reset => reset,
            AR2 =>AR2_DD,
            AR3 =>AR3_DD,
            clear => clear_lmsm,
            disable => disable_lmsm,
            input_mux => lmsm_input_sel,
            RF_DO1_mux => RF_DO1_mux,
            AR2_mux => AR2_mux,
            AR3_mux => AR3_mux,
            mem_in_mux => mem_in_mux,
            ALU2_mux => ALU2_mux
        );
	
	-- Fwd
	fwdingBlock1 : fwdLogic
		port map(
            IDRR_AR => AR1_RR,
            IDRR_AR_valid => CL_RR(10),
            IDRR_PC => PC_RR,
            clk => clk, 
            RREX_mux_control => CL_EX(5 downto 3),
            RREX_AR3_valid => CL_EX(6),
            RREX_AR3 => AR3_EX, 
            RREX_ALU_out => ALU_out,
            RREX_LS_PC => LS_PC_EX,
            RREX_SE => SE_EX,
            RREX_PC_inc => PCpp_EX,
            EXMM_mux_control => CL_MM(3 downto 1),
            EXMM_AR3_valid => CL_MM(4),
            EXMM_AR3 => AR3_MM,
            EXMM_ALU_out => ALU_out_MM,
            EXMM_LS_PC => LS_PC_MM,
            EXMM_SE => SE_MM,
            EXMM_PC_inc => PCpp_MM,
            EXMM_mem_out => mem_out,
            MMWB_AR3_valid => CL_WB(4),
            MMWB_AR3 => AR3_WB,
            MMWB_data => D3_data,
            DO_fwd_control => fwd1_control,
            DO_fwd_data => fwd1_data
        );
	
	fwdingBlock2 : fwdLogic
		port map(
            IDRR_AR => AR2_RR,
            IDRR_AR_valid => CL_RR(9),
            IDRR_PC => PC_RR,
            clk => clk, 
            RREX_mux_control => CL_EX(5 downto 3),
            RREX_AR3_valid => CL_EX(6),
            RREX_AR3 => AR3_EX, 
            RREX_ALU_out => ALU_out,
            RREX_LS_PC => LS_PC_EX,
            RREX_SE => SE_EX,
            RREX_PC_inc => PCpp_EX,
            EXMM_mux_control => CL_MM(3 downto 1),
            EXMM_AR3_valid => CL_MM(4),
            EXMM_AR3 => AR3_MM,
            EXMM_ALU_out => ALU_out_MM,
            EXMM_LS_PC => LS_PC_MM,
            EXMM_SE => SE_MM,
            EXMM_PC_inc => PCpp_MM,
            EXMM_mem_out => mem_out,
            MMWB_AR3_valid => CL_WB(4),
            MMWB_AR3 => AR3_WB,
            MMWB_data => D3_data,
            DO_fwd_control => fwd2_control,
            DO_fwd_data => fwd2_data
        );	
		
	-- Hzd
	hzdLogic_inst: hzdLogic
		port map(
            AR3_IDRR => AR3_RR,
            IDRR_valid => CL_RR(10 downto 8),
            SE_IDRR => SE_RR,
            LS_PC_IDRR => LS_PC_RR,
            DO1_IDRR => DO1_RR,
            opcode => OP_RR,
            clk => clk,
            clear => hzdLogic_clear,
            top_mux_RR_control => top_mux_RR_control,
            data_mux_RR => top_mux_RR_data
        );
		
	-- stall
	stall_inst: stall
		port map(
            decoder_AR1 => AR1_ID,
            decoder_AR2 => AR2_ID,
            IDRR_LW => CL_RR(3),
            IFID_cond => Cond_ID,
            IDRR_AR3 => AR3_RR,
            IDRR_valid => CL_RR(10 downto 8),
            decoder_valid => CL_ID(10 downto 8),
            opcode_IDRR => OP_RR,
            opcode_IFID => INS_ID(15 downto 12),
            clk => clk,
            disable_out => stall_disable,
            SM_start_control => SM_start_control,
            clear => stall_clear
        );
	
	-- left shift
	LS_RR <= SE_RR(8 downto 0) & "0000000";
	
    -- Muxes

	-- PC
	LS_PC_RR <= LS_RR when(CL_RR(0) = '1') else SE_PC_RR;
	-- top
	top_mux_RR <= top_mux_RR_data when (top_mux_RR_control = '1') else JAL_PC;
	-- AR2
	AR2_RF <= AR2_DD when(AR2_mux = '1') else AR2_RR;
	-- F1
	F1_mux <= fwd1_data when(fwd1_control = '1') else DO1_RF;
	--F2
	DO2_RR <= fwd2_data when(fwd2_control = '1') else DO2_RF;
	-- LMSM
	DO1_RR <= ALU_out when(RF_DO1_mux = '1') else F1_mux;
	
	-- regFile
	RegisterFile: regFile
		port map(
            data_in => D3_data,
            R7_in => R7_in,
            data_out1 => DO1_RF,
            data_out2 => DO2_RF,
            R0 => Disp,
            sel_in => AR3_WB,
            sel_out1 => AR1_RR,
            sel_out2 => AR2_RF,
            clk => clk,
            wr_ena => WR_WB(1),
            R7_ena => R7_write, 
            reset => reset
        );

	--------------------- RR/EX pipeReg --------------------------

	concatenation_CL_RREX <= (CL_RR(11) & ALU2_mux & mem_in_mux & AR3_mux & CL_RR(10 downto 3) & CL_RR(1));
	pipe_RREX: RREX
		port map(
            LS_PC_in => LS_PC_RR,
            SE_in => SE_RR,
            CL_in => concatenation_CL_RREX,
            ALU_C_in => ALU_C_RR,
            FC_in => FC_RR,
            Cond_in => Cond_RR,
            Write_in => WR_RR,
            DO1_in => DO1_RR,
            DO2_in => DO2_RR, 
            AR2_in => AR2_RR,
            AR3_in => AR3_RR,
            PC_inc_in => PCpp_RR,
            clk => clk,
            clear => reset,
            clear_control => clear_control_RREX,
            disable => disable_RREX,
            lmsm_en => RF_DO1_mux,
            LS_PC_out => LS_PC_EX,
            SE_out => SE_EX,
            CL_out => CL_EX,
            ALU_C_out => ALU_C_EX,
            FC_out => FC_EX, 
            Cond_out => Cond_EX,
            Write_out => WR_EX,
            DO1_out => DO1_EX,
            DO2_out => DO2_EX,
            AR2_out => AR2_EX,
            AR3_out => AR3_before_EX,
            PC_inc_out => PCpp_EX,
            BLUT_in => BLUT_RR,
            BLUT_out => BLUT_EX,
            op_in => OP_RR,
            op_out => OP_EX
        );
	
	disable_RREX <= disable_lmsm and (not CL_RR(2));
	clear_control_RREX <= clear_lmsm or hzdEX_flush or hzdMM_clear or hazard_WB_clear;
	
	--------------------- EX --------------------------

	-- Muxes

	-- SE_DO2
	SE_DO2 <= SE_EX when(CL_EX(2) = '1') else
        DO2_EX;
	-- ALU2 inp
	ALU2_input <= "0000000000000001" when(CL_EX(11) = '1') else
        SE_DO2;

	-- ALU 
	ALU_instance: alu
		port map(
			input1 => DO1_EX,
            input2 => ALU2_input,
            output => ALU_out,
            cin => '0',
            sel => ALU_C_EX,
			CY => flags_EX(1),
            OV => flags_EX(2),
            Z => flags_EX(0)
        );
    
    -- Muxes
			
	-- top
	top_mux_EX <= top_mux_EX_data when(top_mux_EX_control = '1') else
        top_mux_RR;
	-- LMSM
	AR3_EX <= AR3_DD when(CL_EX(9) = '1') else
        AR3_before_EX;
	
	-- Hzd
	hzdEX_instance: hzdEX
		port map(
			RREX_AR3 => AR3_EX,
            RREX_valid => CL_EX(8 downto 6),
            RREX_mux_control =>CL_EX(5 downto 3), 
			RREX_opcode => OP_EX,
            EXMM_FC => FC_MM(0),
            MMWB_FC => FC_WB(0),
            RREX_C => Cond_EX,
            EXMM_F => flags_MM,
			MMWB_F => flags_WB,
            F => flags_user,
            alu_F => flags_EX,
            ALU_out => ALU_out,
            PC_inc => PCpp_EX,
            SE_PC => LS_PC_EX, 
			beq_is_taken => BLUT_EX(0),
            beq_bit => CL_EX(0),
            table_toggle => toggle,
            pass_beq_taken =>is_taken_EX, 
			top_EX_mux_data =>top_mux_EX_data,
            top_EX_mux => top_mux_EX_control,
            flush => hzdEX_flush,
            clear_current => hzdEX_clear_current, 
			clk => clk
        );
	
	-- lookup address
	BLUT_index_in <= BLUT_EX(3 downto 1);
	
	--------------------- EX/MM pipeReg --------------------------

	concatenation_CL_EXMM <= (CL_EX(12) & CL_EX(10) & CL_EX(8 downto 6) & CL_EX(5 downto 3) & CL_EX(0));
	concatenation_BLUT_EXMM <= (BLUT_EX(3 downto 1) & is_taken_EX);

	pipe_EXMM: EXMM
		port map(
			LS_PC_in => LS_PC_EX,
            SE_in => SE_EX,
            CL_in => concatenation_CL_EXMM,
			FC_in => FC_EX,
            Write_in => WR_EX,
            Flags_in => flags_EX,
            ALU_out_in => ALU_out,
            DO1_in => DO1_EX,
            DO2_in => DO2_EX,
			AR2_in => AR2_EX,
            AR3_in => AR3_EX,
            PC_inc_in => PCpp_EX,
            clk => clk, clear => reset,
            clear_control => clear_control_EXMM,
			clear_conditional => hzdEX_clear_current,
            LS_PC_out => LS_PC_MM,
            SE_out => SE_MM,
            CL_out => CL_MM,
            FC_out => FC_MM,
            Write_out => WR_MM, 
			Flags_out => flags_MM,
            ALU_out_out => ALU_out_MM,
            DO1_out => DO1_MM,
            DO2_out => DO2_MM,
            AR2_out => AR2_MM,
            AR3_out => AR3_MM, 
			PC_inc_out => PCpp_MM,
            BLUT_in => concatenation_BLUT_EXMM,
            BLUT_out => BLUT_MM,
            op_in => OP_EX,
            op_out => OP_MM
        );
	
	clear_control_EXMM <= hzdMM_clear or hazard_WB_clear;

	--------------------- MM --------------------------

    -- Muxes

	-- address
	mem_address <= DO1_MM when(CL_MM(7) = '1') else
        ALU_out_MM;
	-- fwding
	mem_data <= mem_out_WB when(fwd_mux_control_MM = '1') else
        DO2_MM;
	-- top
	top_mux_MM <= mem_out when(top_mux_MM_control = '1') else
        top_mux_EX;
	
	-- mem
	data_memory_instance: ramSim
		port map(
			data_in => mem_data,
            data_out => mem_out,
            address => mem_address,
            clk => clk,
			wr_ena => WR_MM(0),
            rd_ena => '1',
            reset => reset
        );
	
	-- hzd
	hzdMM_instance : hzdMM
		port map(
			EXMM_AR3 => AR3_MM,
            EXMM_valid => CL_MM(6 downto 4),
            EXMM_mux_control => CL_MM(3 downto 1),
			EXMM_flags => flags_MM,
            m_out => mem_out,
            MM_flags_out => flags_MM_hazard,
            top_MM_mux => top_mux_MM_control,
			clear => hzdMM_clear
        );
	
	-- mem fwd
	memory_fwding_instance : mmFwd
		port map(
			EXMM_AR2 => AR2_MM,
            MMWB_AR3 => AR3_WB,
            op_MMWB => OP_WB,
            op_EXMM => OP_MM,
			EXMM_AR2_valid => CL_MM(5),
            MMWB_AR3_valid => CL_WB(4),
            mem_fwd_mux => fwd_mux_control_MM,
			clk => clk
        );
	
	--------------------- MM/WB pipeReg --------------------------

	concatenation_CL_MMWB <= CL_MM(8) & CL_MM(6 downto 0);
	pipe_MMWB: MMWB
		port map(
			LS_PC_in => LS_PC_MM,
            SE_in => SE_MM,
            CL_in => concatenation_CL_MMWB,
            FC_in => FC_MM, Write_in => WR_MM,
			Flags_in => flags_MM_hazard,
            ALU_out_in => ALU_out_MM,
            Mem_out_in => mem_out,
            DO1_in => DO1_MM,
			AR3_in => AR3_MM,
            PC_inc_in => PCpp_MM,
            clk => clk,
            clear => reset,
            clear_control => clear_control_MMWB,
			LS_PC_out => LS_PC_WB,
            SE_out => SE_WB,
            CL_out => CL_WB,
            FC_out => FC_WB,
            Write_out => WR_WB,
			Flags_out => flags_WB,
            ALU_out_out => ALU_out_WB,
            Mem_out_out => mem_out_WB,
            DO1_out => DO1_WB,
			AR3_out => AR3_WB,
            PC_inc_out => PCpp_WB,
            BLUT_in => BLUT_MM,
            BLUT_out => BLUT_WB,
            op_in => OP_MM,
            op_out => OP_WB
        );
	
	clear_control_MMWB <= hazard_WB_clear;

	--------------------- WB --------------------------

    -- Muxes

	-- write back
	D3_data <= ALU_out_WB when(CL_WB(3 downto 1) = "000") else
        LS_PC_WB when(CL_WB(3 downto 1) = "001") else
        SE_WB when(CL_WB(3 downto 1) = "010") else
        PCpp_WB when(CL_WB(3 downto 1) = "011") else
        mem_out_WB;
	-- R7 inp
	R7_in <= DO1_WB when(r7_select = "00") else 
		PCpp_WB when(r7_select = "01") else
		LS_PC_WB;		
	R7_Write <= CL_WB(7) and R7_write_temp;

	-- hzd
	hazard_WB_instance : hzdCondWB
		port map(
			AR3_MMWB => AR3_WB,
            MMWB_LS_PC => LS_PC_WB,
            MMWB_PC_inc => PCpp_WB,
            MMWB_valid => CL_WB(6 downto 4),
			r7_write => R7_write_temp,
            r7_select => r7_select,
            top_WB_mux_control => top_mux_WB_control,
            clear => hazard_WB_clear,  
			top_WB_mux_data => top_mux_WB_data,
            is_taken => BLUT_WB(0),
            opcode => OP_WB
        ); 

    -- Muxes

	-- top
	PC_in <= top_mux_WB_data when(top_mux_WB_control = '1') else
        top_mux_MM;

	-- flags reg

	OV_instance: Register
		generic map(1)
		port map(
			clk => clk,
            clr => reset,
            ena => FC_WB(2),
			Din => flags_WB(2 downto 2),
            Dout => flags_user(2 downto 2)
        );

	C_instance: Register
		generic map(1)
		port map(
			clk => clk,
            clr => reset,
            ena => FC_WB(1),
			Din => flags_WB(1 downto 1),
            Dout => flags_user(1 downto 1)
        );
			
	Z_instance: Register
		generic map(1)
		port map(
			clk => clk,
            clr => reset,
            ena => FC_WB(0),
			Din => flags_WB(0 downto 0),
            Dout => flags_user(0 downto 0)
        );
		
end architecture;
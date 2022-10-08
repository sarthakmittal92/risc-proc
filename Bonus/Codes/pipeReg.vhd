library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pipeReg is

	component IFID is
		port(
			PC_in: in std_logic_vector(15 downto 0);
			Inst_in: in std_logic_vector(15 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;
			-- To clear control signals of IFID
            -- ADI immediate(0) should be used
			-- only last bit of opcode is set  
			disable : in std_logic;

			PC_out: out std_logic_vector(15 downto 0);
			Inst_out: out std_logic_vector(15 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			unflush_out : out std_logic_vector(0 downto 0);

			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0)
        );
	end component;

	component IDRR is  
		generic(
            ctrlLength: integer := 12
        );
		port( 
			PC_in: in std_logic_vector(15 downto 0);
			SE_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(ctrlLength-1 downto 0);
			-- Control bits 
			-- LS_PC
            -- BEQ
            -- LM
            -- LW
            -- SE_DO2
            -- WB_mux (x3)
            -- valid (x3)
            -- unflush
			ALU_C_in: in std_logic_vector(1 downto 0); -- MSB for add, LSB for comp
			FC_in: in std_logic_vector(2 downto 0);    -- flags
			Cond_in: in std_logic_vector(1 downto 0); 
			Write_in: in std_logic_vector(1 downto 0); -- MSB for regFile, LSB for mem
			AR1_in: in std_logic_vector(2 downto 0);
			AR2_in: in std_logic_vector(2 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			LM_in : std_logic_vector(7 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;  -- only control bits cleared
			disable : in std_logic;

			PC_out: out std_logic_vector(15 downto 0);
			SE_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(ctrlLength-1 downto 0);
			ALU_C_out: out std_logic_vector(1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Cond_out: out std_logic_vector(1 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			AR1_out: out std_logic_vector(2 downto 0);
			AR2_out: out std_logic_vector(2 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			LM_out : out std_logic_vector(7 downto 0);

			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);

			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0)
        );
	end component;

	component RREX is  
		generic(
            ctrlLength: integer := 13
        );
		port( 
			LS_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(ctrlLength-1 downto 0);
			-- Control bits 
			-- BEQ
            -- LW
            -- SE_DO2
            -- WB_mux (x3)
            -- valid (x3)
            -- lmsm_control (x3)
            -- unflush
			ALU_C_in: in std_logic_vector(1 downto 0);
			FC_in: in std_logic_vector(2 downto 0);  -- flags
			Cond_in: in std_logic_vector(1 downto 0);
			Write_in: in std_logic_vector(1 downto 0);
			DO1_in: in std_logic_vector(15 downto 0);
			DO2_in: in std_logic_vector(15 downto 0);
			AR2_in: in std_logic_vector(2 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;
			disable : in std_logic;
			lmsm_en : in std_logic;

			LS_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(ctrlLength-1 downto 0);
			ALU_C_out: out std_logic_vector(1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Cond_out: out std_logic_vector(1 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			DO1_out: out std_logic_vector(15 downto 0);
			DO2_out: out std_logic_vector(15 downto 0);
			AR2_out: out std_logic_vector(2 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);

			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);

			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0)
        );	
	end component;

	component EXMM is 
		generic(
            ctrlLength: integer := 9
        );
		port( 
			LS_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(ctrlLength-1 downto 0);
			-- Control bits 
			-- BEQ
            -- WB_mux (x3)
            -- valid (x3)
            -- lmsm_control
            -- unflush
			FC_in: in std_logic_vector(2 downto 0);
			Write_in: in std_logic_vector(1 downto 0);
			Flags_in: in std_logic_vector(2 downto 0);  -- flags
			ALU_out_in: in std_logic_vector(15 downto 0);
			DO1_in: in std_logic_vector(15 downto 0);
			DO2_in: in std_logic_vector(15 downto 0);
			AR2_in: in std_logic_vector(2 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control, clear_conditional : in  std_logic;

			LS_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(ctrlLength-1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			Flags_out: out std_logic_vector(2 downto 0);
			ALU_out_out: out std_logic_vector(15 downto 0);
			DO1_out: out std_logic_vector(15 downto 0);
			DO2_out: out std_logic_vector(15 downto 0);
			AR2_out: out std_logic_vector(2 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);

			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);

			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0)
        );
	end component;

	component MMWB is 
		generic(
            ctrlLength: integer := 8
        );
		port( 
			LS_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(ctrlLength-1 downto 0);
			-- Control bits
			-- BEQ
            -- WB_mux (x3)
            -- valid (x3)
            -- unflush
			FC_in: in std_logic_vector(2 downto 0);
			Write_in: in std_logic_vector(1 downto 0);  
			Flags_in: in std_logic_vector(2 downto 0);
			ALU_out_in: in std_logic_vector(15 downto 0);
			Mem_out_in: in std_logic_vector(15 downto 0);
			DO1_in: in std_logic_vector(15 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;

			LS_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(ctrlLength-1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			Flags_out: out std_logic_vector(2 downto 0);
			ALU_out_out: out std_logic_vector(15 downto 0);
			Mem_out_out: out std_logic_vector(15 downto 0);
			DO1_out: out std_logic_vector(15 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);

			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);

			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0)
        );
	end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity IFID is
	port(
        PC_in: in std_logic_vector(15 downto 0);
        Inst_in: in std_logic_vector(15 downto 0);
        PC_inc_in:in std_logic_vector(15 downto 0);
        clk: in std_logic;
        clear: in std_logic;
        clear_control : in std_logic;
        -- To clear control signals of IFID
        -- ADI immediate(0) should be used
        -- only last bit of opcode is set  
        disable : in std_logic;

        PC_out: out std_logic_vector(15 downto 0);
        Inst_out: out std_logic_vector(15 downto 0);
        PC_inc_out:out std_logic_vector(15 downto 0);
        unflush_out : out std_logic_vector(0 downto 0);

        BLUT_in: in std_logic_vector(3 downto 0);
        BLUT_out: out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl1 of IFID is

    signal enable_temp, clear_temp : std_logic := '1';
    signal Inst_temp     : std_logic_vector(15 downto 0);

begin

	enable_temp <= not disable;
	PC_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => PC_in,
            Dout => PC_out,
            clr => clear
        );
		
	Inst_temp <= "0001000000000000" when (clear_control = '1') else Inst_in; -- ADI (add 0 to R0)        	 
	Inst_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => Inst_temp,
            Dout => Inst_out,
            clr => clear
        );
	        	 
	PC_inc_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => PC_inc_in,
            Dout => PC_inc_out,
            clr => clear
        );
				 
	BLUT_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => enable_temp,
            clr => clear, 
			Din => BLUT_in,
            Dout => BLUT_out
        );
	
	clear_temp <= clear or clear_control;
	UNFLUSH_REG: Register
		generic map(1)
		port map(
			clk => clk,
            ena => enable_temp,
            clr => clear_temp, 
			Din => "1",
            Dout => unflush_out
        );

end architecture; 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity IDRR is  
    generic(
        ctrlLength: integer := 12
    );
    port( 
        PC_in: in std_logic_vector(15 downto 0);
        SE_PC_in: in std_logic_vector(15 downto 0);
        SE_in: in std_logic_vector(15 downto 0);
        CL_in : in std_logic_vector(ctrlLength-1 downto 0);
        -- Control bits 
        -- LS_PC
        -- BEQ
        -- LM
        -- LW
        -- SE_DO2
        -- WB_mux (x3)
        -- valid (x3)
        -- unflush
        ALU_C_in: in std_logic_vector(1 downto 0); -- MSB for add, LSB for comp
        FC_in: in std_logic_vector(2 downto 0);    -- flags
        Cond_in: in std_logic_vector(1 downto 0); 
        Write_in: in std_logic_vector(1 downto 0); -- MSB for regFile, LSB for mem
        AR1_in: in std_logic_vector(2 downto 0);
        AR2_in: in std_logic_vector(2 downto 0);
        AR3_in: in std_logic_vector(2 downto 0);
        PC_inc_in:in std_logic_vector(15 downto 0);
        LM_in : std_logic_vector(7 downto 0);
        clk: in std_logic;
        clear: in std_logic;
        clear_control : in std_logic;  -- only control bits cleared
        disable : in std_logic;

        PC_out: out std_logic_vector(15 downto 0);
        SE_PC_out: out std_logic_vector(15 downto 0);
        SE_out: out std_logic_vector(15 downto 0);
        CL_out : out std_logic_vector(ctrlLength-1 downto 0);
        ALU_C_out: out std_logic_vector(1 downto 0);
        FC_out: out std_logic_vector(2 downto 0);
        Cond_out: out std_logic_vector(1 downto 0);
        Write_out: out std_logic_vector(1 downto 0);
        AR1_out: out std_logic_vector(2 downto 0);
        AR2_out: out std_logic_vector(2 downto 0);
        AR3_out: out std_logic_vector(2 downto 0);
        PC_inc_out:out std_logic_vector(15 downto 0);
        LM_out : out std_logic_vector(7 downto 0);

        BLUT_in: in std_logic_vector(3 downto 0);
        BLUT_out: out std_logic_vector(3 downto 0);

        op_in: in std_logic_vector(3 downto 0);
        op_out: out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl2 of IDRR is

    signal enable_temp : std_logic := '1';
    signal clear_temp  : std_logic := '0';

begin

	enable_temp <= not disable;
	PC_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => PC_in,
            Dout => PC_out,
            clr => clear
        );
    
	SE_PC: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp,
            Din => SE_PC_in,
            Dout => SE_PC_out,
            clr => clear
        );
    
	SE: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => SE_in,
            Dout => SE_out,
            clr => clear
        );
	
	clear_temp <= (clear or clear_control);
	CL: Register
		generic map(ctrlLength)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => CL_in,
            Dout => CL_out,
            clr => clear_temp
        );
	
	ALU_C: Register
		generic map(2)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => ALU_C_in,
            Dout => ALU_C_out,
            clr => clear
        );
    
	FC: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => FC_in,
            Dout => FC_out,
            clr => clear_temp
        );
    
	Cond: Register
		generic map(2)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => Cond_in,
            Dout => Cond_out,
            clr => clear
        );
    
	Write: Register
		generic map(2)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => Write_in,
            Dout => Write_out,
            clr => clear_temp
        ); 
	    
	AR1: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => AR1_in,
            Dout => AR1_out,
            clr => clear
        ); 
	
	AR2: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => AR2_in,
            Dout => AR2_out,
            clr => clear
        );  
	        	 
	AR3: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => AR3_in,
            Dout => AR3_out,
            clr => clear
        );  
	        	     	 
	PC_inc_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp,
            Din => PC_inc_in,
            Dout => PC_inc_out,
            clr => clear
        );

	LM_REG: Register
		generic map(8)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => LM_in,
            Dout => LM_out,
            clr => clear
        );
				 
	BLUT_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => enable_temp,
            clr => clear_temp, 
			Din => BLUT_in,
            Dout => BLUT_out
        );
	
	OP_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => enable_temp,
            clr => clear, 
			Din => op_in,
            Dout => op_out
        );
			
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity RREX is  
    generic(
        ctrlLength: integer := 13
    );
    port( 
        LS_PC_in: in std_logic_vector(15 downto 0);
        SE_in: in std_logic_vector(15 downto 0);
        CL_in : in std_logic_vector(ctrlLength-1 downto 0);
        -- Control bits 
        -- BEQ
        -- LW
        -- SE_DO2
        -- WB_mux (x3)
        -- valid (x3)
        -- lmsm_control (x3)
        -- unflush
        ALU_C_in: in std_logic_vector(1 downto 0);
        FC_in: in std_logic_vector(2 downto 0);  -- flags
        Cond_in: in std_logic_vector(1 downto 0);
        Write_in: in std_logic_vector(1 downto 0);
        DO1_in: in std_logic_vector(15 downto 0);
        DO2_in: in std_logic_vector(15 downto 0);
        AR2_in: in std_logic_vector(2 downto 0);
        AR3_in: in std_logic_vector(2 downto 0);
        PC_inc_in:in std_logic_vector(15 downto 0);
        clk: in std_logic;
        clear: in std_logic;
        clear_control : in std_logic;
        disable : in std_logic;
        lmsm_en : in std_logic;

        LS_PC_out: out std_logic_vector(15 downto 0);
        SE_out: out std_logic_vector(15 downto 0);
        CL_out : out std_logic_vector(ctrlLength-1 downto 0);
        ALU_C_out: out std_logic_vector(1 downto 0);
        FC_out: out std_logic_vector(2 downto 0);
        Cond_out: out std_logic_vector(1 downto 0);
        Write_out: out std_logic_vector(1 downto 0);
        DO1_out: out std_logic_vector(15 downto 0);
        DO2_out: out std_logic_vector(15 downto 0);
        AR2_out: out std_logic_vector(2 downto 0);
        AR3_out: out std_logic_vector(2 downto 0);
        PC_inc_out:out std_logic_vector(15 downto 0);

        BLUT_in: in std_logic_vector(3 downto 0);
        BLUT_out: out std_logic_vector(3 downto 0);

        op_in: in std_logic_vector(3 downto 0);
        op_out: out std_logic_vector(3 downto 0)
    );	
end entity;

architecture rtl3 of RREX is

    signal enable_temp :std_logic := '1';
    signal clear_temp  :std_logic := '0';
    signal lmsm_en_temp :std_logic := '1';

begin

	enable_temp <= not disable;
	lmsm_en_temp <= (enable_temp or lmsm_en);

	LS_PC: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => LS_PC_in,
            Dout => LS_PC_out,
            clr => clear
        );
    
	SE: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => SE_in,
            Dout => SE_out,
            clr => clear
        );
	
	clear_temp <= clear or clear_control;
	CL: Register
		generic map(ctrlLength)
		port map(
            clk => clk,
            ena => lmsm_en_temp, 
            Din => CL_in,
            Dout => CL_out,
            clr => clear_temp
        );
	
	ALU_C: Register
		generic map(2)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => ALU_C_in,
            Dout => ALU_C_out,
            clr => clear
        );
    
	FC: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => FC_in,
            Dout => FC_out,
            clr => clear_temp
        );
    
	Cond: Register
		generic map(2)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => Cond_in,
            Dout => Cond_out,
            clr => clear
        ); 
    
	Write: Register
		generic map(2)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => Write_in,
            Dout => Write_out,
            clr => clear_temp
        ); 
	
	DO1: Register
		generic map(16)
		port map(
            clk => clk,
            ena => lmsm_en_temp, 
            Din => DO1_in,
            Dout => DO1_out,
            clr => clear
        ); 
	
	DO2: Register
		generic map(16)
		port map(
            clk => clk,
            ena => lmsm_en_temp, 
            Din => DO2_in,
            Dout => DO2_out,
            clr => clear
        ); 
    
	AR2: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => AR2_in,
            Dout => AR2_out,
            clr => clear
        );  	
	
	AR3: Register
		generic map(3)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => AR3_in,
            Dout => AR3_out,
            clr => clear
        );      
	        	 	 
	PC_inc_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => enable_temp, 
            Din => PC_inc_in,
            Dout => PC_inc_out,
            clr => clear
        );
				 
	BLUT_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => enable_temp,
            clr => clear_temp, 
			Din => BLUT_in,
            Dout => BLUT_out
        );
			
	OP_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => enable_temp,
            clr => clear, 
			Din => op_in,
            Dout => op_out
        );

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity EXMM is 
    generic(
        ctrlLength: integer := 9
    );
    port( 
        LS_PC_in: in std_logic_vector(15 downto 0);
        SE_in: in std_logic_vector(15 downto 0);
        CL_in : in std_logic_vector(ctrlLength-1 downto 0);
        -- Control bits 
        -- BEQ
        -- WB_mux (x3)
        -- valid (x3)
        -- lmsm_control
        -- unflush
        FC_in: in std_logic_vector(2 downto 0);
        Write_in: in std_logic_vector(1 downto 0);
        Flags_in: in std_logic_vector(2 downto 0);  -- flags
        ALU_out_in: in std_logic_vector(15 downto 0);
        DO1_in: in std_logic_vector(15 downto 0);
        DO2_in: in std_logic_vector(15 downto 0);
        AR2_in: in std_logic_vector(2 downto 0);
        AR3_in: in std_logic_vector(2 downto 0);
        PC_inc_in:in std_logic_vector(15 downto 0);
        clk: in std_logic;
        clear: in std_logic;
        clear_control, clear_conditional : in  std_logic;

        LS_PC_out: out std_logic_vector(15 downto 0);
        SE_out: out std_logic_vector(15 downto 0);
        CL_out : out std_logic_vector(ctrlLength-1 downto 0);
        FC_out: out std_logic_vector(2 downto 0);
        Write_out: out std_logic_vector(1 downto 0);
        Flags_out: out std_logic_vector(2 downto 0);
        ALU_out_out: out std_logic_vector(15 downto 0);
        DO1_out: out std_logic_vector(15 downto 0);
        DO2_out: out std_logic_vector(15 downto 0);
        AR2_out: out std_logic_vector(2 downto 0);
        AR3_out: out std_logic_vector(2 downto 0);
        PC_inc_out:out std_logic_vector(15 downto 0);

        BLUT_in: in std_logic_vector(3 downto 0);
        BLUT_out: out std_logic_vector(3 downto 0);

        op_in: in std_logic_vector(3 downto 0);
        op_out: out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl4 of EXMM is

    signal clear_temp, clear_temp_unflush :std_logic := '0';

begin

	LS_PC: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => LS_PC_in,
            Dout => LS_PC_out,
            clr => clear
        );
    
	SE: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => SE_in,
            Dout => SE_out,
            clr => clear
        );
	
	clear_temp <= clear or clear_control or clear_conditional;
	clear_temp_unflush <= clear or clear_control;
	
	CL: Register
		generic map(ctrlLength-1)
		port map(
            clk => clk,
            ena => '1', 
            Din => CL_in(ctrlLength-2 downto 0),
            Dout => CL_out(ctrlLength-2 downto 0),
            clr => clear_temp
        );
	        	 
	unflush: Register
		generic map(1)
		port map(
            clk => clk,
            ena => '1',
            Din => CL_in(ctrlLength -1 downto ctrlLength -1),
            Dout => CL_out(ctrlLength -1 downto ctrlLength -1),
            clr => clear_temp_unflush
        );
	
	FC: Register
		generic map(3)
		port map(
            clk => clk,
            ena => '1', 
            Din => FC_in,
            Dout => FC_out,
            clr => clear_temp
        );
 
	Write: Register
		generic map(2)
		port map(
            clk => clk,
            ena => '1', 
            Din => Write_in,
            Dout => Write_out,
            clr => clear_temp
        ); 
	    
	Flags: Register
		generic map(3)
		port map(
            clk => clk,
            ena => '1', 
            Din => Flags_in,
            Dout => Flags_out,
            clr => clear
        );
    
	ALU_out: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => ALU_out_in,
            Dout => ALU_out_out,
            clr => clear
        );
	 
	DO1: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => DO1_in,
            Dout => DO1_out,
            clr => clear
        ); 
	
	DO2: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => DO2_in,
            Dout => DO2_out,
            clr => clear
        ); 
    
	AR2: Register
		generic map(3)
		port map(
            clk => clk,
            ena => '1', 
            Din => AR2_in,
            Dout => AR2_out,
            clr => clear
        );   
				 
	AR3: Register
		generic map(3)
		port map(
            clk => clk,
            ena => '1', 
            Din => AR3_in,
            Dout => AR3_out,
            clr => clear
        );      
	        	 	 
	PC_inc_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => PC_inc_in,
            Dout => PC_inc_out,
            clr => clear
        );
				 
	BLUT_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => '1',
            clr => clear_temp, 
			Din => BLUT_in,
            Dout => BLUT_out
        );
	
	OP_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => '1',
            clr => clear, 
			Din => op_in,
            Dout => op_out
        );

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity MMWB is 
    generic(
        ctrlLength: integer := 8
    );
    port( 
        LS_PC_in: in std_logic_vector(15 downto 0);
        SE_in: in std_logic_vector(15 downto 0);
        CL_in : in std_logic_vector(ctrlLength-1 downto 0);
        -- Control bits
        -- BEQ
        -- WB_mux (x3)
        -- valid (x3)
        -- unflush
        FC_in: in std_logic_vector(2 downto 0);
        Write_in: in std_logic_vector(1 downto 0);  
        Flags_in: in std_logic_vector(2 downto 0);
        ALU_out_in: in std_logic_vector(15 downto 0);
        Mem_out_in: in std_logic_vector(15 downto 0);
        DO1_in: in std_logic_vector(15 downto 0);
        AR3_in: in std_logic_vector(2 downto 0);
        PC_inc_in:in std_logic_vector(15 downto 0);
        clk: in std_logic;
        clear: in std_logic;
        clear_control : in std_logic;

        LS_PC_out: out std_logic_vector(15 downto 0);
        SE_out: out std_logic_vector(15 downto 0);
        CL_out : out std_logic_vector(ctrlLength-1 downto 0);
        FC_out: out std_logic_vector(2 downto 0);
        Write_out: out std_logic_vector(1 downto 0);
        Flags_out: out std_logic_vector(2 downto 0);
        ALU_out_out: out std_logic_vector(15 downto 0);
        Mem_out_out: out std_logic_vector(15 downto 0);
        DO1_out: out std_logic_vector(15 downto 0);
        AR3_out: out std_logic_vector(2 downto 0);
        PC_inc_out:out std_logic_vector(15 downto 0);

        BLUT_in: in std_logic_vector(3 downto 0);
        BLUT_out: out std_logic_vector(3 downto 0);

        op_in: in std_logic_vector(3 downto 0);
        op_out: out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl5 of MMWB is

    signal clear_temp :std_logic := '0';

begin

	LS_PC: Register
		generic map(16)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => LS_PC_in,
            Dout => LS_PC_out,
            clr => clear
        );
    
	SE: Register
		generic map(16)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => SE_in,
            Dout => SE_out,
            clr => clear
        );
	
	clear_temp <= clear or clear_control;

	CL: Register
		generic map(ctrlLength)
		port map(
            clk => clk,
            ena => '1', 
            Din => CL_in,
            Dout => CL_out,
            clr => clear_temp
        );
	
	FC: Register
		generic map(3)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => FC_in,
            Dout => FC_out,
            clr => clear_temp
        );
  
	Write: Register
		generic map(2)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => Write_in,
            Dout => Write_out,
            clr => clear_temp
        ); 
	    
	Flags: Register
		generic map(3)
		port map(
            clk => clk,
            ena => '1', 
            Din => Flags_in,
            Dout => Flags_out,
            clr => clear
        );
    
	ALU_out: Register
		generic map(16)
		port map(
            clk => clk,
            ena => '1', 
            Din => ALU_out_in,
            Dout => ALU_out_out,
            clr => clear
        );
	     
	Mem_out: Register
		generic map(16)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => Mem_out_in,
            Dout => Mem_out_out,
            clr => clear
        );
	 	
	DO1: Register
		generic map(16)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => DO1_in,
            Dout => DO1_out,
            clr => clear
        ); 
       	 	        	 
	AR3: Register
		generic map(3)
		port map(
            clk => clk,
            ena => '1', 
            Din => AR3_in,
            Dout => AR3_out,
            clr => clear
        );      
	        	 	 
	PC_inc_REG: Register
		generic map(16)
		port map(
            clk => clk,
            ena =>  '1', 
            Din => PC_inc_in,
            Dout => PC_inc_out,
            clr => clear
        );
				 
	BLUT_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => '1',
            clr => clear_control, 
			Din => BLUT_in,
            Dout => BLUT_out
        );
	
	OP_REG: Register
		generic map(4)
		port map(
			clk => clk,
            ena => '1',
            clr => clear, 
			Din => op_in,
            Dout => op_out
        );

end architecture;
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.basic.all;
use work.add.all;

entity DataPath is
	port(
        op_code: out std_logic_vector(3 downto 0);
        condition: out std_logic_vector(1 downto 0);
        clk, reset, RX, start: in std_logic;
        finish: out std_logic;
        T: in std_logic_vector(24 downto 0);
        S: out std_logic_vector(4 downto 0);
        P0: out std_logic_vector(15 downto 0)
    );
end entity;
	
architecture rtl of DataPath is

    component Register is
        generic(
            widthOfData : integer
        );
	    port(
            clk, ena, clr: in std_logic;
            Din: in std_logic_vector(widthOfData - 1 downto 0);
            Dout: out std_logic_vector(widthOfData - 1 downto 0)
        );
    end component;

	component extend is
		generic(
            widthOfinput: integer := 6;
			widthOfoutput: integer := 16
        );
		port(
			input: in std_logic_vector(widthOfinput - 1 downto 0);
			output: out std_logic_vector(widthOfoutput - 1 downto 0)
        );
	end component;

	component RegFile is
		generic(
			lengthOfWord: integer := 16;
			noOfWords: integer := 8
        );	
		port(
			data_in: in std_logic_vector(lengthOfWord - 1 downto 0);
			data_out1, data_out2, R7, R0: out std_logic_vector(lengthOfWord - 1 downto 0);
			sel_in, sel_out1, sel_out2: in std_logic_vector(integer(ceil(log2(real(noOfWords)))) - 1 downto 0);
			clk, wr_ena, reset: in std_logic
        );
	end component;

	component lmsm is
		generic(
            widthOfinput: integer := 8
        );
		port(
			input: in std_logic_vector(0 to widthOfinput - 1);
			ena, clk, set_zero, reset: in std_logic;
			valid, invalid_next: out std_logic;
			address: out std_logic_vector(0 to integer(ceil(log2(real(widthOfinput)))) - 1)
        );
	end component;

	component alu is
		generic(
            lengthOfWord: integer := 16
        );
		port(
			input1, input2: in std_logic_vector(lengthOfWord - 1 downto 0);
			output: out std_logic_vector(lengthOfWord - 1 downto 0);
			cin, sel: in std_logic;
			CY, Z: out std_logic
        );
	end component;
			
	component ram
		port(
			aclr: in std_logic := '0';
			address: in std_logic_vector(14 downto 0);
			clock: in std_logic := '1';
			data: in std_logic_vector(15 downto 0);
			wren: in std_logic;
			q: out std_logic_vector(15 downto 0)
        );
	end component;
	
	component bootload is 
		port(
			start, clk, reset, RX: in std_logic;
			address: out std_logic_vector(15 downto 0);
			data: out std_logic_vector(15 downto 0);
			enable, finish: out std_logic
        );
	end component;
	
	signal I, D1, D2, D3, SEs, SEl, LS, ALU_A, ALU_B, ALU_S, T1, T2: std_logic_vector(15 downto 0) := (others => '0');
	signal A_IM, A_DM, DO_IM, DO_DM, DI_DM, T1_in, E1, E2, PC, PC_in, R7, R0, d_boot, a_boot: std_logic_vector(15 downto 0) := (others => '0');
	signal A1, A2, A3, A3_int, PE: std_logic_vector(2 downto 0) := (others => '0');
	signal CY, Z, B_in, B: std_logic_vector(0 downto 0) := (others => '0');
	signal carry_ena, zero_ena, alu_op, b_ena, temp, wren, pc_ena, ena_boot: std_logic;

begin

	-- Bootloader
	bootload_instance: bootload
        port map(
            start => start,
            clk => clk,
            reset => reset,
            RX => RX, 
            data => d_boot,
            address => a_boot,
            enable => ena_boot,
            finish => finish
        );
	
	--  TRANSFER SIGNALS

    --  Memory Access
	--  T(0)		: memory address
	-- 		0 	- D2
	-- 		1 	- ALU_S
    --  T(5)		: memory write
    --  T(3)		: lmsm write
	--  T(4)		: lmsm set-zero

    --  Register Enablers
	--  T(1)		: instruction
	--  T(2)		: RegFile write
	--  T(7)		: T1
	--  T(8)		: T2
	--  T(9)		: PC
    
    --  T(10)	    : Flag setter

    --  Input Selectors
	--  T(11)	    : A2
	-- 		0 	- immediate (9)
	-- 		1	- PE
	--  T(13:12)	: A3
	-- 		00 - "111"
	-- 		01 - immediate (9)
	-- 		10 - PE
	-- 		11 - immediate (6)
	--  T(16:14)	: D3
	-- 		000 - PC
	-- 		001 - T1
	-- 		010 - LS
	-- 		011 - T2
	-- 		100 - R7
	-- 		101 - memory data
	--  T(19:17)	: ALU_B
	-- 		000 - 0
	-- 		001 - 1
	-- 		010 - E2
	-- 		011 - extend (6 to 16)
	-- 		100 - extend (9 to 16)
	--  T(21:20)	: ALU_A
	-- 		00	- T2
	-- 		01	- T1
	-- 		10	- E1
	-- 		11	- R7
	--  T(22)	    : PC_in (Mux signal)
	-- 		1 - ALU output
	-- 		0 - D1
	--  T(23)	    : T1
	-- 		1 - ALU output
	-- 		0 - D2

    -- Forwarding
	--  T(24)	    : op_code
	-- 		1 - Forwarded
	-- 		0 - From IR

	-- Memory Components

	-- Priority
	priority: lmsm
		port map(
            input => I(7 downto 0),
            ena => T(3),
            clk => clk,
            set_zero => T(4),
			reset => reset,
            invalid_next => S(0),
            address => PE
        );
    
    -- Memory
	mem: ram
    port map(
        q => DO_DM,
        data => DI_DM,
        address => A_DM(14 downto 0),
        wren => wren,
        aclr => reset,
        clock => clk
    );

    -- Arithmetic Components
			
	-- Extend 6 to 16
	extend_1: extend
		generic map(6,16)
		port map(
            input => I(5 downto 0),
            output => SEl
        );
		
	-- Extend 9 to 16
	extend_2: extend
		generic map(9,16)
		port map(
            input => I(8 downto 0),
            output => SEs
        );
		
	-- ALU
	alu_instance: alu
		port map(
            input1 => ALU_A,
            input2 => ALU_B,
            output => ALU_S,
            cin => '0',
			sel => alu_op,
            CY => CY(0),
            Z => Z(0)
        );
    
    -- Register Components
    
    -- Instruction Register
	instruction: Register
    generic map(16)
    port map(
        clk => clk,
        clr => reset,
        Din => DO_IM,
        Dout => I,
        ena => T(1)
    );

    -- Register File
    rf: RegFile
        port map(
            clk => clk,
            reset => reset,
            wr_ena => T(2),
            data_in => D3,
            R7 => R7,
            R0 => R0,
            data_out1 => D1,
            data_out2 => D2,
            sel_in => A3,
            sel_out1 => A1,
            sel_out2 => A2
        );
		
	-- Register 1
	T1_reg: Register
		generic map(16)
		port map(
            Din => T1_in,
            Dout => T1,
            ena => T(7),
            clk => clk,
            clr => reset
        );
		
	-- Register 2
	T2_reg: Register
		generic map(16)
		port map(
            Din => DO_DM,
            Dout => T2,
            ena => T(8),
            clr => reset,
            clk => clk
        );
		
	-- Register E1
	E1_reg: Register
		generic map(16)
		port map(
            Din => D1,
            Dout => E1,
            ena => '1',
            clr => reset,
            clk => clk
        );
		
	-- Register E2
	E2_reg: Register
		generic map(16)
		port map(
            Din => D2,
            Dout => E2,
            ena => '1',
            clr => reset,
            clk => clk
        );
    
    -- Flag Components
    
    -- Carry
	Carry: Register
    generic map(1)
    port map(
        Din => CY,
        Dout => S(1 downto 1),
        ena => carry_ena,
        clr => reset,
        clk => clk
    );
    
    -- Zero	
    Zero: Register
        generic map(1)
        port map(
            Din => Z,
            Dout => S(2 downto 2),
            ena => zero_ena,
            clr => reset,
            clk => clk
        );
		
	-- PC
	PC_reg: Register
		generic map(16)
		port map(
            Din => PC_in,
            Dout => PC,
            ena => pc_ena,
            clr => reset,
            clk => clk
        );
		
	-- B flip-flop (for R7)
	Bff: Register
		generic map(1)
		port map(
            Din => B_in,
            Dout => B,
            ena => b_ena,
            clr => reset,
            clk => clk
        );
		
    -- Enabler Signals

    -- Memory
	wren <= ena_boot when (start = '1') else
        T(5) when ((I(12) and I(14)) = '1') else '0';
    
    -- ALU Operator
	alu_op <= '1' when (I(15 downto 12) = "0010") else '0';

	-- PC
	pc_ena <= temp or T(9);

	-- Carry
	carry_ena <= '1' when ((I(15 downto 13) = "000") and (T(10) = '1')) else '0';

	-- Zero
	zero_ena <= '1' when (((I(15 downto 14) = "00") and ((I(13) and I(12)) = '0') and (T(10) = '1')) or I(15 downto 12) = "0100") else '0';

	-- Temporary
	temp <= (A3(2) and A3(1) and A3(0) and T(2));

	-- B reg
	b_ena <= T(9) or temp;

	-- B
	S(3) <= B(0) or temp;

    -- Stage/Instruction Operations
	
	-- Left shift
	LS <= I(8 downto 0) & "0000000" when (I(15) = '0') else  -- LHI
		"0000000" & I(8 downto 0);  -- LLI
	
	-- Equality
	S(4) <= '1' when (D1 = D2) else '0';

    -- RegFile Addresses
	
	-- RegFile address 1
	A1 <= I(8 downto 6);
		
	-- RegFile address 2
	A2 <= PE when (T(11) = '1') else
		I(11 downto 9);
	
	-- RegFile address 3
	A3_int <= "111" when (T(13 downto 12) = "00") else
		I(11 downto 9) when (T(13 downto 12) = "01") else
		PE when (T(13 downto 12) = "10") else
		I(5 downto 3);
	
	-- RegFile input
	D3 <= PC when (T(16 downto 14) = "000") else
		T1 when (T(16 downto 14) = "001") else
		LS when (T(16 downto 14) = "010") else
		T2 when (T(16 downto 14) = "011") else
		R7 when (T(16 downto 14) = "100") else
		DO_DM;
    
    -- ALU Inputs

	-- Writing to regB in ADI	
	A3 <= I(8 downto 6) when ((I(15 downto 12) = "0001") and (T(13 downto 12) = "11")) else A3_int;

	-- ALU B
	ALU_B <= (others => '0') when (T(19 downto 17) = "000") else
		std_logic_vector(to_unsigned(1,16)) when (T(19 downto 17) = "001") else
		E2 when (T(19 downto 17) = "010") else
		SEl when (T(19 downto 17) = "011") else
		SEs;
	
	-- ALU A
	ALU_A <= T2 when (T(21 downto 20)= "00") else
		T1 when (T(21 downto 20) = "01") else
		E1 when (T(21 downto 20) = "10") else
		R7;
    
	-- T1
	T1_in <= ALU_S when (T(23) = '1') else
		D2;
		
    -- PC
	PC_in <= D3 when (temp = '1') else
		ALU_S when (T(22) = '1') else
		D1;
		
    -- B
	B_in <= "1" when (temp = '1') else "0";

    -- Flag-dependent input

	A_IM <= R7 when (B = "1") else 
		D3;
	
	A_DM <= a_boot when (start = '1') else
		ALU_S when (T(0) = '1' and T(6) = '0') else
		T1 when (T(0) = '0' and T(6) = '1') else
		D2 when (T(0) = '1' and T(6) = '1') else
		A_IM;
	
	DI_DM <= d_boot when (start = '1') else
		D2;
		
    -- Sending to ControlPath

	-- op_code
	op_code <= I(15 downto 12) when (T(24) = '0') else
		DO_IM(15 downto 12);
    
	-- conditional execution
	condition <= I(1 downto 0);
	DO_IM <= DO_DM;
	P0 <= R0;
	
end architecture;
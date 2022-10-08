library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mmFwd is
	port(
        EXMM_AR2, MMWB_AR3 : in std_logic_vector(2 downto 0);
        op_MMWB, op_EXMM : in std_logic_vector(3 downto 0);
        EXMM_AR2_valid, MMWB_AR3_valid : in std_logic;
        mem_fwd_mux : out std_logic;
        clk : in std_logic
    );
end entity;

architecture rtl of mmFwd is

	signal ar_equal : std_logic := '0';

begin

	ar_equal <= (EXMM_AR2_valid and MMWB_AR3_valid)  when (EXMM_AR2 = MMWB_AR3) else '0';
	mem_fwd_mux <= ar_equal when((op_MMWB = "0100") and (op_EXMM = "0101")) else '0';

end architecture;
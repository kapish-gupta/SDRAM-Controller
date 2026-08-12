library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cmd_fifo is
end entity;

architecture sim of tb_cmd_fifo is
    constant CLK_PERIOD : time := 10 ns; 
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal wr_en : std_logic := '0';
    signal din   : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_en : std_logic := '0';
    signal dout  : std_logic_vector(3 downto 0);
    signal empty : std_logic;
    signal full  : std_logic;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.cmd_fifo
        generic map ( M => 4, N => 4 ) -- Smaller depth
        port map (
            i_rst => rst, i_clk => clk,
            i_wr_en => wr_en, i_din => din,
            i_rd_en => rd_en, o_dout => dout,
            o_empty => empty, o_full => full
        );

    -- Clock Generation
    clk <= not clk after CLK_PERIOD / 2;

    -- Stimulus Process
    stimulus: process
    begin
        -- Reset system
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- Write data into FIFO
        wr_en <= '1';
        din <= "0111"; -- ACTIVATE
        wait for CLK_PERIOD;
        din <= "0001"; -- READ
        wait for CLK_PERIOD;
        wr_en <= '0';
        
        wait for 30 ns;

        -- Read data from FIFO
        rd_en <= '1';
        wait for CLK_PERIOD * 2;
        rd_en <= '0';

        wait; -- Stop simulation
    end process;
end sim;
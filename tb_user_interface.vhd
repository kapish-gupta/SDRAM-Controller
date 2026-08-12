library ieee;
use ieee.std_logic_1164.all;

entity tb_user_interface is
end entity;

architecture sim of tb_user_interface is
    constant CLK_PERIOD : time := 10 ns; 
    
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal read_bank  : std_logic := '0';
    signal write_bank : std_logic := '0';
    signal cmd_out    : std_logic_vector(3 downto 0);
    signal cmd_valid  : std_logic;

begin
    -- Instantiate the User Interface
    uut: entity work.user_interface
        generic map ( freq_clk => 100 ) -- 100 MHz
        port map (
            clk => clk, 
            reset => reset,
            read_bank => read_bank, 
            write_bank => write_bank,
            cmd_out => cmd_out, 
            cmd_valid => cmd_valid
        );

    -- 100 MHz Clock Generation
    clk <= not clk after CLK_PERIOD / 2;

   
    stimulus: process
    begin
        -- 1. Apply Reset
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        
        -- 2. Wait for the 200us initialization sequence to finish!
        
        wait for 205 us; 

        -- 3. Perform a READ sequence
       
        read_bank <= '1';
        wait for 200 ns; 
        
        
        read_bank <= '0';
        wait for 100 ns; 

        -- 4. Perform a WRITE sequence
        write_bank <= '1';
        wait for 200 ns;
        
      
        write_bank <= '0';

        
        wait for 200 ns;
        
        -- End Simulation
        wait;
    end process;
end sim;
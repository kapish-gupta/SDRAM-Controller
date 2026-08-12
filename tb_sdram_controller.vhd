library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sdram_full_features is
end entity;

architecture sim of tb_sdram_full_features is
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz clock
    
    -- Inputs
    signal clk_user       : std_logic := '0';
    signal DQM_user       : std_logic := '0';
    signal reset_user     : std_logic := '1';
    signal cmd_in_user    : std_logic_vector(3 downto 0) := "0000";
    signal addr_in_user   : std_logic_vector(11 downto 0) := (others => '0');
    signal bank_addr_user : std_logic_vector(1 downto 0) := "00";
    
    -- Bidirectional (Inouts)
    signal data_user  : std_logic_vector(15 downto 0);
    signal data_sdram : std_logic_vector(15 downto 0);
    
    -- Tb Drivers for Inouts
    signal tb_data_user_drv  : std_logic_vector(15 downto 0) := (others => 'Z');
    signal tb_data_sdram_drv : std_logic_vector(15 downto 0) := (others => 'Z');

    -- Outputs
    signal clk_sdram        : std_logic;
    signal DQM_sdram        : std_logic;
    signal clk_enable_sdram : std_logic;
    signal cs, ras, cas, we : std_logic;
    signal addr_out_sdram   : std_logic_vector(11 downto 0);
    signal rd_en            : std_logic;
    signal bank_addr_sdram  : std_logic_vector(1 downto 0);

begin
    -- Instantiate your controller
    uut: entity work.sdram_controller
        generic map ( freq_clk => 100 )
        port map (
            clk_user         => clk_user,
            DQM_user         => DQM_user,
            reset_user       => reset_user,
            cmd_in_user      => cmd_in_user,
            addr_in_user     => addr_in_user,
            bank_addr_user   => bank_addr_user,
            data_user        => data_user,
            clk_sdram        => clk_sdram,
            DQM_sdram        => DQM_sdram,
            clk_enable_sdram => clk_enable_sdram,
            cs               => cs,
            ras              => ras,
            cas              => cas,
            we               => we,
            addr_out_sdram   => addr_out_sdram,
            data_sdram       => data_sdram,
            rd_en            => rd_en,
            bank_addr_sdram  => bank_addr_sdram
        );

    -- Drive tri-state buses
    data_user  <= tb_data_user_drv;
    data_sdram <= tb_data_sdram_drv;

    -- Generate Clock
    clk_user <= not clk_user after CLK_PERIOD / 2;

    -- Master Stimulus Process
    -- Master Stimulus Process
    stimulus: process
    begin
        
        -- 1. SYSTEM RESET & INITIALIZATION
       
        reset_user <= '1';
        wait for 50 ns;
        reset_user <= '0';
        
        -- Wait for the 200us internal timer to expire, plus MRS setup time
        wait for 205 us; 
        
     
        -- 2. FEATURE: ACTIVATE -> WRITE
      
        -- Wait for controller to be IDLE and ready
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "0111"; -- ACTIVATE
        addr_in_user <= x"123"; 
        bank_addr_user <= "01";
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
        -- Wait for controller to finish ACTIVATE and return to IDLE
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "0010"; -- WRITE
        addr_in_user <= x"045"; 
        tb_data_user_drv <= x"ABCD"; -- Push data onto bus
        wait for CLK_PERIOD;
        cmd_in_user <= "0000"; 
        tb_data_user_drv <= (others => 'Z'); -- Release bus immediately
        
       
        -- 3. FEATURE: PRECHARGE SINGLE BANK
      
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "0011"; 
        bank_addr_user <= "01";
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
      
        -- 4. FEATURE: ACTIVATE -> READ
      
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "0111"; -- ACTIVATE
        addr_in_user <= x"999"; 
        bank_addr_user <= "10";
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "0001"; -- READ
        addr_in_user <= x"088";
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
        -- Mocking SDRAM read data: 
        -- Based on your RTL, read capture happens when wait_counter = 1 in READ_BANK_WAIT
        -- This occurs exactly 2 clock cycles after the command is latched.
        wait for 2 * CLK_PERIOD; 
        tb_data_sdram_drv <= x"BEEF"; -- Mock SDRAM data
        wait for CLK_PERIOD;
        tb_data_sdram_drv <= (others => 'Z');
        
       
        -- 5. FEATURE: PRECHARGE ALL BANKS
       
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "1111"; 
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
        
        -- 6. FEATURE: MANUAL AUTO REFRESH
        
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "1000"; 
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
       
        -- 7. FEATURE: SELF-REFRESH ENTRY & EXIT
       
        wait until rising_edge(clk_user) and rd_en = '1';
        
        cmd_in_user <= "1001"; -- ENTRY
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
        -- Wait a bit while the RAM sleeps
        wait for 100 ns; 
        
        -- EXIT
        -- We CANNOT wait for rd_en here because the controller is asleep and rd_en is 0!
       
        wait until rising_edge(clk_user);
        cmd_in_user <= "1010"; 
        wait for CLK_PERIOD;
        cmd_in_user <= "0000";
        
      
        -- 8. FEATURE: INTERNAL TIMER AUTO-REFRESH
       
        -- Wait for the controller to fully wake up from Self-Refresh
        wait until rising_edge(clk_user) and rd_en = '1';
        
        -- Just idle for 15.1us to let your internal timer trigger a refresh
        wait for 15100 ns;
        
        wait for 500 ns;
        
        wait; -- End Simulation
    end process;
   
end sim;
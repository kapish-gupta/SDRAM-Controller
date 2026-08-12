library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_full is
end entity;

architecture sim of tb_top_full is
    constant CLK_PERIOD : time := 10 ns; 
    
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    
    signal read_bank          : std_logic := '0';
    signal write_bank         : std_logic := '0';
    signal addr_user_top      : std_logic_vector(11 downto 0) := "000000000000";
    signal bank_addr_user_top : std_logic_vector(1 downto 0) := "00";
    signal dqm_user           : std_logic := '0';
    
    signal data_user_top  : std_logic_vector(15 downto 0);
    signal data_sdram_top : std_logic_vector(15 downto 0);
    
    signal tb_data_user_drv  : std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
    signal tb_data_sdram_drv : std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";

    signal cs, ras, cas, we    : std_logic;
    signal addr_sdram_top      : std_logic_vector(11 downto 0);
    signal bank_addr_sdram_top : std_logic_vector(1 downto 0);
    signal clk_enable          : std_logic;
    signal dqm_sdram           : std_logic;
    signal clk_sdram_top       : std_logic;

begin
    uut: entity work.top
        port map (
            clk                 => clk, 
            reset               => reset,
            read_bank           => read_bank, 
            write_bank          => write_bank,
            cs                  => cs, 
            ras                 => ras, 
            cas                 => cas, 
            we                  => we,
            addr_sdram_top      => addr_sdram_top, 
            addr_user_top       => addr_user_top,
            bank_addr_sdram_top => bank_addr_sdram_top, 
            bank_addr_user_top  => bank_addr_user_top,
            clk_enable          => clk_enable, 
            dqm_sdram           => dqm_sdram, 
            dqm_user            => dqm_user,
            data_user_top       => data_user_top, 
            data_sdram_top      => data_sdram_top,
            clk_sdram_top       => clk_sdram_top
        );

    data_user_top  <= tb_data_user_drv;
    data_sdram_top <= tb_data_sdram_drv;

    clk <= not clk after CLK_PERIOD / 2;

    stimulus: process
    begin
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        
        wait for 205 us; 
        wait until rising_edge(clk);
        
        -- Write Command 1
        addr_user_top      <= "000010100101"; 
        bank_addr_user_top <= "10";
        tb_data_user_drv   <= x"1234"; 
        write_bank <= '1';
        wait for 1 us; 
        write_bank <= '0';
        tb_data_user_drv <= "ZZZZZZZZZZZZZZZZ"; 
        wait for 1 us;

        -- Write Command 2
        addr_user_top      <= "000011110000"; 
        bank_addr_user_top <= "11";
        tb_data_user_drv   <= x"ABCD"; 
        write_bank <= '1';
        wait for 1 us; 
        write_bank <= '0';
        tb_data_user_drv <= "ZZZZZZZZZZZZZZZZ"; 
        wait for 1 us;
        
        -- Read Command 1
        addr_user_top      <= "000010100101"; 
        bank_addr_user_top <= "10";
        read_bank <= '1';
        wait for 1 us; 
        read_bank <= '0';
        wait for 2 us;

        -- Read Command 2
        addr_user_top      <= "000011110000"; 
        bank_addr_user_top <= "11";
        read_bank <= '1';
        wait for 1 us; 
        read_bank <= '0';
        wait for 2 us;
        
        -- Write Command 3
        addr_user_top      <= "000000001111"; 
        bank_addr_user_top <= "00";
        tb_data_user_drv   <= x"9999"; 
        write_bank <= '1';
        wait for 1 us; 
        write_bank <= '0';
        tb_data_user_drv <= "ZZZZZZZZZZZZZZZZ"; 
        wait for 1 us;
        
        -- Read Command 3
        addr_user_top      <= "000000001111"; 
        bank_addr_user_top <= "00";
        read_bank <= '1';
        wait for 1 us; 
        read_bank <= '0';
        wait for 2 us;

        wait for 16 us;
        wait;
    end process;

    virtual_sdram: process
        variable mock_read_data : unsigned(15 downto 0) := x"8765";
    begin
        wait until rising_edge(clk);
        
        if (cs = '0' and ras = '1' and cas = '0' and we = '1') then
            tb_data_sdram_drv <= std_logic_vector(mock_read_data);
            wait for CLK_PERIOD; 
            tb_data_sdram_drv <= "ZZZZZZZZZZZZZZZZ";
            mock_read_data := mock_read_data + x"1111";
        end if;
    end process;

end sim;
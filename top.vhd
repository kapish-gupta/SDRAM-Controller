library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        clk        : in std_logic;
        reset      : in std_logic;

        read_bank  : in std_logic;
        write_bank : in std_logic;

        -- SDRAM pins
        cs, ras, cas, we : out std_logic;
		  
        addr_sdram_top             : out std_logic_vector(11 downto 0);
		  addr_user_top              : in std_logic_vector(11 downto 0) ;
		  
		  bank_addr_sdram_top    : out std_logic_vector(1 downto 0) ;
		  bank_addr_user_top    : in std_logic_vector(1 downto 0) ;
		  
		  clk_enable       : out std_logic ;
		  
		  
		  dqm_sdram              : out std_logic ;
		  
        dqm_user : in std_logic ; 
		  
		  data_user_top             : inout std_logic_vector(15 downto 0);
		   data_sdram_top             : inout std_logic_vector(15 downto 0);
		  
		  clk_sdram_top : out std_logic 
		  
		  
    );
	 
end entity;
architecture rtl of top is

    -- interconnect signals
    signal cmd_ui      : std_logic_vector(3 downto 0);
    signal cmd_valid_wr: std_logic;

    signal fifo_dout   : std_logic_vector(3 downto 0);
    signal fifo_empty  : std_logic;
	 signal fifo_full  : std_logic;
    signal fifo_rd_en  : std_logic;

begin

    -- fifo
    fifo_inst : entity work.cmd_fifo
        port map (
            i_rst => reset, 
				i_clk  => clk,
	
				i_wr_en => cmd_valid_wr ,
				i_din  => cmd_ui,
	
				i_rd_en => fifo_rd_en ,
				o_dout  => fifo_dout ,
	
				o_empty=>fifo_empty,
				o_full => fifo_full 
        );

    -- ui
    ui_inst : entity work.user_interface
        port map (
            clk   => clk ,      
            reset     => reset ,

            read_bank => read_bank ,
            write_bank =>write_bank ,

            cmd_out   => cmd_ui ,
            cmd_valid => cmd_valid_wr 
        );

    -- SDRAM CONTROLLER
    sdram_inst : entity work.sdram_controller
        port map (
            -- user controller input 
        clk_user        => clk,   
		  DQM_user        => dqm_user , 
        reset_user      => reset ,
        cmd_in_user     => fifo_dout ,
		  addr_in_user   => addr_user_top ,
		  bank_addr_user  => bank_addr_user_top ,
		  data_user       =>  data_user_top,
		
		
	 
	-- controller sdram output
	     clk_sdram       =>  clk_sdram_top ,
		  DQM_sdram       => dqm_sdram ,
	     clk_enable_sdram=>clk_enable ,
        cs              => cs,
        ras             => ras ,
        cas             =>cas, 
        we       	 	   =>we ,
        addr_out_sdram  =>addr_sdram_top ,
        data_sdram      =>  data_sdram_top,
		  rd_en           => fifo_rd_en,
	     bank_addr_sdram => bank_addr_sdram_top
            
        );

end rtl;













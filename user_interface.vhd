library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity user_interface is
    generic(
        freq_clk : integer := 100  -- MHz
    );
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;

        read_bank  : in  std_logic;
        write_bank : in  std_logic;

        cmd_out    : out std_logic_vector(3 downto 0);
        cmd_valid  : out std_logic
    );
end entity;

architecture rtl of user_interface is

    -- COMMANDS
    constant CMD_NOP       : std_logic_vector(3 downto 0) := "0000";
    constant CMD_ACTIVATE  : std_logic_vector(3 downto 0) := "0111";
    constant CMD_READ      : std_logic_vector(3 downto 0) := "0001";
    constant CMD_WRITE     : std_logic_vector(3 downto 0) := "0010";
    constant CMD_PRECHARGE : std_logic_vector(3 downto 0) := "0011";

    -- TIMINGS (CLK CYCLES)
    constant tRCD  : integer := (20 * freq_clk) / 1000;
    constant tCAS  : integer := (10 * freq_clk) / 1000;
    constant tRP   : integer := (20 * freq_clk) / 1000;
    constant t200u : integer := 201 * freq_clk;

    type state_type is (
        RESET_WAIT,
        IDLE,
        ACTIVATE,
        WAIT_RCD,
        READ_CMD,
        WRITE_CMD,
        WAIT_CAS,
        PRECHARGE,
        WAIT_RP,
        WAIT_RELEASE
    );

    signal state : state_type := IDLE;
    signal counter : integer range 0 to 65535 := 0;
    signal lock_sw : std_logic := '0';

begin

process(clk, reset)
begin
    if reset = '1' then
        state <= RESET_WAIT;
        counter <= 0;
        lock_sw <= '0';
        cmd_out <= CMD_NOP;
        cmd_valid <= '0';

    elsif rising_edge(clk) then

        cmd_out   <= CMD_NOP;
        cmd_valid <= '0';

        case state is

            -- POWER-UP STABILITY
            when RESET_WAIT =>
                if counter < t200u then
                    counter <= counter + 1;
                else
                    counter <= 0;
                    state <= IDLE;
                end if;

            -- WAIT FOR USER
            when IDLE =>
                if lock_sw = '0' then
                    if read_bank = '1' then
                        lock_sw <= '1';
                        state <= ACTIVATE;
                    elsif write_bank = '1' then
                        lock_sw <= '1';
                        state <= ACTIVATE;
                    end if;
                end if;

            -- ACTIVATE
            when ACTIVATE =>
                cmd_out   <= CMD_ACTIVATE;
                cmd_valid <= '1';
                counter <= tRCD;
                state <= WAIT_RCD;

            -- WAIT tRCD
            when WAIT_RCD =>
                if counter < tRCD then
                    counter <= counter + 1;
                else
                    counter <= 0;
                    if read_bank = '1' then
                        state <= READ_CMD;
                    else
                        state <= WRITE_CMD;
                    end if;
                end if;

            -- READ
            when READ_CMD =>
                cmd_out   <= CMD_READ;
                cmd_valid <= '1';
                counter <= 2;
                state <= WAIT_CAS;

            -- WRITE
            when WRITE_CMD =>
                cmd_out   <= CMD_WRITE;
                cmd_valid <= '1';
                counter <= 0;
                state <= WAIT_CAS;

            -- WAIT tCAS
            when WAIT_CAS =>
                if counter < tCAS then
                    counter <= counter + 1;
                else
                    counter <= 0;
                    state <= PRECHARGE;
                end if;

            -- PRECHARGE
            when PRECHARGE =>
                cmd_out   <= CMD_PRECHARGE;
                cmd_valid <= '1';
                counter <= tRP;
                state <= WAIT_RP;

            -- WAIT tRP
            when WAIT_RP =>
                if counter < tRP then
                    counter <= counter + 1;
                else
                    counter <= 0;
                    state <= WAIT_RELEASE;
                end if;

            -- RELEASE SWITCH
            when WAIT_RELEASE =>
                if read_bank = '0' and write_bank = '0' then
                    lock_sw <= '0';
                    state <= IDLE;
                end if;

            when others =>
                state <= IDLE;

        end case;
    end if;
end process;

end rtl;

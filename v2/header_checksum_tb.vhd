-------------------------------------------------------------------------------
--  Title   : Simulation test‑bench for header_checksum
--  Tool    : ModelSim / Questa‑Intel (Quartus Prime)
--  Author  : ChatGPT (OpenAI o3)
--  Date    : 30‑Apr‑2025
--
--  Purpose : Pure behavioural test‑bench (uses "wait" statements) intended
--            **only** for simulation – do NOT add this file to the synthesis
--            fileset in Quartus.
--
--  Scenario :
--      1. Apply reset.
--      2. Send one GOOD IPv4 header (checksum must pass).
--      3. Wait a short gap.
--      4. Send one BAD  IPv4 header (checksum must fail).
--      5. End simulation with an ASSERT (severity **failure** stops ModelSim
--         and returns exit code 1 – change to **note** if you prefer).
--
--  Observables :
--      * Waveform:  cksum_ok should pulse high once (good pkt) then stay low
--      * ok_cnt   should be 1;  ko_cnt should be 1 at the end.
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity header_checksum_tb is
end entity;

architecture tb of header_checksum_tb is

    ---------------------------------------------------------------------------
    --  Constants & stimulus data
    ---------------------------------------------------------------------------
    constant CLK_PERIOD : time := 20 ns;                 -- 50 MHz
    constant WORDS      : integer := 10;                 -- 20‑byte IPv4 header

    type word_array_t is array (0 to WORDS-1) of std_logic_vector(15 downto 0);

    --  GOOD packet (checksum pre‑folded → overall result 0)
    constant GOOD_PKT : word_array_t := (
        x"4500", x"002C", x"1234", x"4000", x"4006", x"0000",
        x"C0A8", x"0101", x"C0A8", x"0102"
    );

    --  BAD packet (one bit flipped)
    constant BAD_PKT  : word_array_t := (
        x"4501", x"002C", x"1234", x"4000", x"4006", x"0000",
        x"C0A8", x"0101", x"C0A8", x"0102"
    );

    ---------------------------------------------------------------------------
    --  Signals to/from DUT
    ---------------------------------------------------------------------------
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';              -- asserted at start
    signal start_of_data : std_logic := '0';
    signal data_in       : std_logic_vector(15 downto 0);
    signal cksum_calc    : std_logic;
    signal cksum_ok      : std_logic;
    signal ok_cnt        : std_logic_vector(15 downto 0);
    signal ko_cnt        : std_logic_vector(15 downto 0);

begin
    ---------------------------------------------------------------------------
    --  DUT instantiation (unit‑under‑test)
    ---------------------------------------------------------------------------
    UUT: entity work.header_checksum
        port map (
            clk           => clk,
            reset         => reset,
            start_of_data => start_of_data,
            data_in       => data_in,
            cksum_calc    => cksum_calc,
            cksum_ok      => cksum_ok,
            cksum_ok_cnt  => ok_cnt,
            cksum_ko_cnt  => ko_cnt
        );

    ---------------------------------------------------------------------------
    --  Clock generation
    ---------------------------------------------------------------------------
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    ---------------------------------------------------------------------------
    --  Stimulus
    ---------------------------------------------------------------------------
    stim_proc: process
    begin
        -----------------------------------------------------------------------
        --  1) Apply reset for three clock cycles
        -----------------------------------------------------------------------
        wait for 3*CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        --  2) Send GOOD packet (should set cksum_ok)
        -----------------------------------------------------------------------
        for i in 0 to WORDS-1 loop
            start_of_data <= '1';
            data_in       <= GOOD_PKT(i);
            wait for CLK_PERIOD;
        end loop;
        start_of_data <= '0';

        wait for 5*CLK_PERIOD;   -- idle gap

        -----------------------------------------------------------------------
        --  3) Send BAD packet (should clear cksum_ok)
        -----------------------------------------------------------------------
        for i in 0 to WORDS-1 loop
            start_of_data <= '1';
            data_in       <= BAD_PKT(i);
            wait for CLK_PERIOD;
        end loop;
        start_of_data <= '0';

        -----------------------------------------------------------------------
        --  4) Finish – check counters and report
        -----------------------------------------------------------------------
        wait for 10*CLK_PERIOD;
        assert unsigned(ok_cnt) = 1 and unsigned(ko_cnt) = 1
            report "Test **PASSED** – OK=1, KO=1" severity note;

        assert false report "Simulation finished" severity failure;
    end process;

end architecture;

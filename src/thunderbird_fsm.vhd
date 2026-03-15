--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 
--|                  ON    | 
--|                  R1    | 
--|                  R2    | 
--|                  R3    | 
--|                  L1    | 
--|                  L2    | 
--|                  L3    | 
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


--| Binary State Encoding key
--| --------------------
--| State | Encoding
--| --------------------
--| OFF   | 000
--| ON    | 001
--| R1    | 010
--| R2    | 011
--| R3    | 100
--| L1    | 101
--| L2    | 110
--| L3    | 111
--| --------------------

 
entity thunderbird_fsm is
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 
    signal w_slow_clk : std_logic;
    signal f_state, f_next_state : std_logic_vector(2 downto 0);
-- CONSTANTS ------------------------------------------------------------------
    
begin
    clk_div_inst : entity work.clock_divider
    generic map (
        k_DIV => 1
    )
    port map (
        i_clk   => i_clk,
        i_reset => i_reset,
        o_clk   => w_slow_clk
    );
	-- CONCURRENT STATEMENTS --------------------------------------------------------	
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
    
	-----------------------------------------------------					   
	process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_reset = '1') then
                f_state <= "000"; -- OFF
            else
                f_state <= f_next_state;
            end if;
        end if;
    end process;	
    
    process(f_state, i_left, i_right)
begin

    case f_state is

        when "000" =>  -- OFF
            if (i_left='0' and i_right='0') then
                f_next_state <= "000"; -- OFF
            elsif (i_left='0' and i_right='1') then
                f_next_state <= "010"; -- R1
            elsif (i_left='1' and i_right='0') then
                f_next_state <= "101"; -- L1
            else
                f_next_state <= "001"; -- ON (hazard)
            end if;

        when "001" =>  -- ON
            f_next_state <= "000";

        when "010" =>  -- R1
            f_next_state <= "011";

        when "011" =>  -- R2
            f_next_state <= "100";

        when "100" =>  -- R3
            f_next_state <= "000";

        when "101" =>  -- L1
            f_next_state <= "110";

        when "110" =>  -- L2
            f_next_state <= "111";

        when "111" =>  -- L3
            f_next_state <= "000";

        when others =>
            f_next_state <= "000";

    end case;
        case f_state is
    
            when "000" => -- OFF
                o_lights_L <= "000";
                o_lights_R <= "000";
    
            when "001" => -- ON 
                o_lights_L <= "111";
                o_lights_R <= "111";
    
            when "010" => -- R1
                o_lights_L <= "000";
                o_lights_R <= "001";
    
            when "011" => -- R2
                o_lights_L <= "000";
                o_lights_R <= "011";
    
            when "100" => -- R3
                o_lights_L <= "000";
                o_lights_R <= "111";
    
            when "101" => -- L1
                o_lights_L <= "001";
                o_lights_R <= "000";
    
            when "110" => -- L2
                o_lights_L <= "011";
                o_lights_R <= "000";
    
            when "111" => -- L3
                o_lights_L <= "111";
                o_lights_R <= "000";
    
            when others =>
                o_lights_L <= "000";
                o_lights_R <= "000";
    
        end case;
    
    end process;
		  
end thunderbird_fsm_arch;
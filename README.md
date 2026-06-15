# Memory-based-game
implementation of a Memory based game using verilog
# 1. Introduction & Objective  
This project implements a digital memory game on an FPGA using Verilog. The 
objective is to create an interactive game where the player must memorize a 
randomly generated 8-bit pattern (displayed on LEDs) and then correctly 
recall it using 8-bit switches.  
The game features progressively harder levels, decreasing the time allowed 
for memorization. The player's current level is shown on a 4-digit 7-segment display.  
# 2. Design Overview  
The system is controlled by a top-level module named real_project. This 
module contains a Finite State Machine (FSM) that dictates the game's flow. 
The FSM progresses through four distinct states: IDLE, MEMORIZE, GUESS, 
and RESULT.  
The top-level module coordinates several submodules to handle specific 
tasks:  
• button_debouncer: Cleans the noisy signal from the physical 'start' 
button.  
• clk_divider_3s: A configurable timer used for the MEMORIZE phase.  
• level_display_dec1: Decodes the current level (1-9) into 7-segment display 
signals.  
• result_display: Manages the multiplexed 7-segment display to show 
the points. 
# 3. Module Breakdown  
main_code (Top-Level Module)  
This is the "brain" of the game. It connects all other modules and contains the 
primary game logic.  
• FSM: Manages the game flow.  
• LFSR: An 8-bit Linear Feedback Shift Register is used to generate pseudo
random patterns for the LEDs.  
• Logic: Contains the logic for checking the player's answer (lfsr == switch), 
incrementing the level, and resetting the game.  
• Pulse Generation: Includes vital logic to convert the "level" signal from the 
debouncer into a single-clock-cycle pulse (start_clean_pulse). This 
prevents the FSM from getting stuck.  
• Display MUX: A combinational always @(*) block selects what to show on 
the 7-segment display based on the current FSM state (e.g., show level, 
show "g" for guess, or show the result).  
clk_divider_3s (Timer)  
This module generates a single tick pulse after a specified delay.  
• Input: desired[7:0]. This value represents time in 1/10th-second intervals 
(e.g., desired = 30 creates a 3.0-second delay).  
• Function: When its reset input is low (i.e., when the FSM is in the 
MEMORIZE state), a 32-bit counter increments. When it reaches the target 
count, it fires a one-shot tick pulse.  
• Fixes: This module was corrected to use a 32-bit counter to prevent 
overflow when calculating large delay values (e.g., 30 * 10,000,000).  
button_debouncer  
This module solves the problem of mechanical button bounce.  
• Function: It waits for the start button's input signal to be stable for 
approximately 10ms (at 100MHz) before passing the "clean" signal 
(start_clean) to the main module. This prevents a single button press from 
being registered multiple times.  
level_display_dec1  
A simple combinational module.  
• Function: It takes the 4-bit level number (1-9) and outputs the 
corresponding 7-bit pattern required to display that digit on a common
anode 7-segment display.  
Result_display  
This module displays a 4-letter word across a 4-digit display.  
• Function: It uses a counter to multiplex the 7-segment anodes (an). It 
cycles through the 4 digits very quickly, showing one letter at a time ("G", 
"O", "O", "D" or "B", "A", "D", "-"). This rapid switching creates the optical 
illusion of a stable, 4-letter word.  
# 4. Game Flow (FSM States)  
1. IDLE:  
o Display: Shows the current level on the first 7-segment digit.  
o Action: Waits for start_clean_pulse.  
o Next: Moves to MEMORIZE on start_clean_pulse.  
1. MEMORIZE:  
o Display: Shows the current level on the first digit.  
o LEDs: ON, displaying the 8-bit lfsr pattern.  
o Action: The clk_divider_3s timer is active and counting down.  
o Next: Moves to GUESS when the timer's posedge_tick_detected signal 
is received.  
1. GUESS:  
o LEDs: OFF.  
o Action: Waits for the player to set the switch inputs and press the start 
button again.  
o Next: Moves to RESULT on start_clean_pulse.  
1. RESULT:  
o Display: Shows "GOOD" (if lfsr == switch) or "BAD" (if lfsr != switch).  
o Action: The game logic updates the level. If the answer was wrong, the 
level resets to 1.  
o Next: Moves to IDLE on start_clean_pulse.  
# 5. Inputs and Outputs (from real_project)  
Inputs  
• clk (W5): The 100MHz master clock for the system.  
• rst (R2): The master reset button (resets the game to IDLE at level 1).  
• start (U18): The center button, used to start the game and submit answers.  
• switch[7:0] (V17-W13): The 8 slide switches used by the player to input 
their answer.  
Outputs  
• led[7:0] (U16-V14): The 8 LEDs used to display the memory pattern.  
• seg[6:0] (W7-U7): The 7 segment data lines for the display.  
• an[3:0] (U2-W4): The 4 anode enable lines for the 7-segment display.

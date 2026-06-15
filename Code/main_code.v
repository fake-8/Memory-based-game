module real_project( 
    input start, 
    input clk, 
    input rst, 
    output reg [7:0] led, 
    input [7:0] switch, 
    output reg [6:0] seg, 
    output reg [3:0] an 
); 
// --- State Machine--- 
parameter IDLE        = 2'b00; 
parameter MEMORIZE    = 2'b01; 
parameter GUESS       = 2'b10; 
reg [1:0] state = IDLE; 
reg [7:0] desired_value; // For timer 
reg [7:0] random = 8'b11010101; // Initial LFSR s 
reg [7:0] lfsr;  
reg [3:0] level = 1; 
wire tick;  
wire start_clean;  
wire [6:0] seg_level_w; 
wire reset_timer_w;  
reg start_clean_sync_0, start_clean_sync_1; 
wire start_clean_pulse; 
 
always @(posedge clk or posedge rst) begin 
    if (rst) begin 
        start_clean_sync_0 <= 0; 
        start_clean_sync_1 <= 0; 
    end else begin 
        start_clean_sync_0 <= start_clean; 
        start_clean_sync_1 <= start_clean_sync_0; 
    end 
end 
assign start_clean_pulse = (start_clean_sync_1 == 0) && (start_clean_sync_0 == 1); 
 
// --- Synchronize the timer 'tick' --- 
reg tick_sync_0, tick_sync_1; 
wire posedge_tick_detected; 
always @(posedge clk or posedge rst) begin 
    if (rst) begin 
        tick_sync_0 <= 0; 
        tick_sync_1 <= 0; 
    end else begin 
        tick_sync_0 <= tick; 
        tick_sync_1 <= tick_sync_0; 
    end 
end 
assign posedge_tick_detected = (tick_sync_1 == 0) && (tick_sync_0 == 1); 
 
 
// --- Module Instantiations --- 
clk_divider_3s divider ( 
    .clk(clk), 
    .reset(reset_timer_w),  
    .desired(desired_value), 
    .tick(tick) 
); 
 
button_debouncer db_start ( 
    .clk(clk), 
    .rst(rst), 
    .noisy_btn(start), 
    .clean_btn(start_clean) 
); 
 
level_display_dec1 display_level ( 
    .level(level), 
    .seg(seg_level_w) 
); 
// --- Game Logic --- 
always @(posedge clk or posedge rst) begin 
    if (rst) begin 
        // Reset everything 
        state <= IDLE; 
        level <= 1; 
        desired_value <= 0; 
        lfsr <= random; 
    end else begin 
        case (state) 
            IDLE: begin 
                if (start_clean_pulse) begin 
                    // Set timer based on current level 
                    if (level <= 2)         desired_value <= 25; // 3.0 sec 
                    else if (level <= 4)    desired_value <= 20; // 2.5 sec 
                    else if (level <= 6)    desired_value <= 15; // 2.0 sec 
                    else                    desired_value <= 10; // 1.5 sec 
                    lfsr <= { lfsr[6:0], (lfsr[0] ^ lfsr[2] ^ lfsr[3] ^ lfsr[4]) }; 
                    state <= MEMORIZE; 
                end 
            end            
            MEMORIZE: begin 
                if (posedge_tick_detected) begin // Timer expired! 
                    desired_value <= 0; // Stop timer 
                    state <= GUESS; 
                end 
            end             
            GUESS: begin 
                if (start_clean_pulse) begin  
                    // Check the answer  
                    if (lfsr == switch) begin 
                        if (level < 9) level <= level + 1; 
                    end else begin 
                        level <= 1; // Reset level 
                        random <= lfsr; // Save failed pattern for next led 
                    end 
                    state <= IDLE;  
                end 
            end             
        endcase 
    end 
end 
always @(*) begin 
    led = 8'b0; 
    seg = 7'b1111111;  
    an = 4'b1111; 
    case (state) 
        IDLE: begin 
            seg = seg_level_w; // Show current level 
            an = 4'b1110;   
        end        
        MEMORIZE: begin 
            led = lfsr;         
            seg = seg_level_w; // Show current level 
            an = 4'b1110;      
        end          
        GUESS: begin 
            led = 8'b0;         
            seg = 7'b0001110;   
            an = 4'b1110;       
        end         
        default: begin 
            led = 8'b0; 
            seg = seg_level_w; // Show current level 
            an = 4'b1110;       
        end 
    endcase 
end 
assign reset_timer_w = (state != MEMORIZE);  
endmodule
module button_debouncer ( 
    input  clk,        
    input  rst,        
    input  noisy_btn,  
    output reg clean_btn  
); 
    reg [19:0] counter;  // 20-bit counter for 10ms delay at 100MHz 
    reg btn_sync_0, btn_sync_1;   
 
    // Synchronize the noisy input to the system clock 
    always @(posedge clk) begin 
        btn_sync_0 <= noisy_btn; 
        btn_sync_1 <= btn_sync_0; 
    end 
 
    // Debounce logic 
    always @(posedge clk or posedge rst) begin 
        if (rst) begin 
            counter <= 0; 
            clean_btn <= 0; 
        end else if (btn_sync_1 == clean_btn) 
            counter <= 0;  // Reset counter if input is stable 
        else begin 
            counter <= counter + 1; // Input is unstable, start/continue counting 
            // If input is stable for ~10ms (1M cycles at 100MHz) 
            if (counter == 20'd999_999) begin   
                clean_btn <= btn_sync_1;  // Update the stable output 
                counter <= 0; 
            end 
        end 
    end 
endmodule
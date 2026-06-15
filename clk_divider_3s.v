module clk_divider_3s ( 
    input  clk, 
    input  reset, // Active-high reset 
    input  [7:0] desired, 
    output reg tick 
); 
    reg b; // One-shot flag 
    //'a' must be 32 bits to avoid overflow
    reg [31:0] a;  
     
    // Constant for 0.1 seconds at 100MHz 
    localparam COUNT_100MS = 32'd10000000; 
 
    always @(posedge clk or posedge reset) begin 
        if (reset) begin 
            a <= 0; 
            tick <= 0; 
            b <= 1; // Arm the one-shot 
        end 
        // Timer only runs if 'desired' is non-zero 
        else if (desired != 0) begin 
            if ((a >= (desired * COUNT_100MS - 1)) && (b == 1)) begin 
                a <= 0; 
                tick <= 1; // Fire the tick (0 -> 1) 
                b <= 0;    // Disarm the one-shot 
            end  
            else if (b == 1) begin // If armed and not yet reached count 
                a <= a + 1; // Continue counting 
                tick <= 0; 
            end 
            else begin // tick has fired
                tick <= 0; 
            end 
        end 
        else begin // If desired == 0, keep timer reset and armed 
             a <= 0; 
             tick <= 0; 
             b <= 1; 
        end 
    end 
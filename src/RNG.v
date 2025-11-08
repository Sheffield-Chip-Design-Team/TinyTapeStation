// Module : Random Number Generator 
// Author: Bowen Shi

module rng ( // random nuumber generator based on linear feedback + seed
  input wire clk,
  input wire reset,
  input wire trigger,
  input wire [7:0] seed, // Seed input for initializing randomness
  output wire ready,
  output reg [7:0] rdm_num
);

    localparam [7:0] default_value = 8'b1001_1011;
    reg trigger_reg;
    reg [7:0] rand_buf1;
    reg [7:0] rand_buf2;
    reg ready_reg;
    wire tri_pulse = trigger_reg & !trigger;
    reg tri_pulse_reg;
    reg [7:0] seed_reg;

    // --- combinational mix (no drivers to seed_reg) ---
    wire [7:0] x1   = seed_reg ^ (seed_reg << 3);     // xorshift left
    wire [7:0] x2   = x1 + seed;                      // add seed for diffusion
    wire [7:0] x3   = x2 ^ (x2 >> 2);                 // xorshift right
    wire [7:0] x4   = {x3[0], x3[7:1]};               // rotate right by 1
    wire [7:0] next = x4 * 8'hB5;                     // multiply by odd constant

    // --- single driver for seed_reg ---
    always @(posedge clk) begin
        if (reset)
            seed_reg <= (seed == 8'h00) ? 8'h01 : seed;  // avoid all-zero lock
        else
            seed_reg <= next;                            // single non-blocking update
    end

    // sequential lfsr-based random number generator
    always @(posedge clk) begin
      if (reset) begin
        rand_buf1  <= 0;
        rand_buf2  <= 8'b1111_1101;
        trigger_reg <= 0;
        ready_reg  <= 0;
        seed_reg <=0;
      end
      else begin  
        trigger_reg <= trigger;
        tri_pulse_reg <= tri_pulse;

        if (tri_pulse) begin 
          ready_reg <= 0;
          rand_buf1[3:0] <= (next[3:0] > 4'b1100)? (next[3:0]-4'b1100) : next[3:0];  // Shift all bits from the seed
          rand_buf1[7:4] <= next[7:4]; // Feedback XOR for randomness
        end
          
        if (tri_pulse_reg) begin
            ready_reg  <= 1;
        end
      end 
    end

    always @(posedge clk) begin
        rdm_num <= (|rand_buf1)?rand_buf1:8'b11000011;
    end
    
    assign ready = ready_reg;
endmodule


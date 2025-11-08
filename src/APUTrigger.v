module APU_trigger (
    input wire  clk,
    input wire  reset,
    input wire  frame_end,
    input wire  test_mode,
    input wire  SheepDragonCollision,
    input wire  SwordDragonCollision,
    input wire  PlayerDragonCollision,
    output reg  eat_sound,
    output reg  die_sound,
    output reg  hit_sound
);

  reg [2:0] trigger_buf;

  // buffer the trigger signals 
  always @ (posedge clk) begin
    if (reset) begin
      trigger_buf <= 3'b0;
    end else begin
      if (frame_end) begin
        trigger_buf[0] <= SheepDragonCollision;
        trigger_buf[1] <= SwordDragonCollision;
        trigger_buf[2] <= PlayerDragonCollision;
      end
    end
  end
  
  // detect the rising edge of the trigger signals
  always @ (posedge clk) begin
    if (!test_mode) begin
      if (trigger_buf[0] & ~trigger_buf[0])  
        eat_sound <= 1'b1;
      else 
        eat_sound <= 1'b0;

      if (~trigger_buf[1] & trigger_buf[1])  
        die_sound <= 1'b1;
      else 
        die_sound <= 1'b0;

      if (~trigger_buf[2] & trigger_buf[2])  
        hit_sound <= 1'b1;
      else 
        hit_sound <= 1'b0;
    end else begin
      eat_sound <= SheepDragonCollision;
      die_sound <= PlayerDragonCollision;
      hit_sound <= SwordDragonCollision;
    end
  end
                                                                                                         endmodule

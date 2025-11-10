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
  reg [1:0] frame_delay;

  // buffer the trigger signals 
  always @ (posedge clk) begin
    if (reset) begin
      trigger_buf <= 3'b0;
    end else begin
      // if (frame_end) begin
        trigger_buf[0] <= SheepDragonCollision;
        trigger_buf[1] <= SwordDragonCollision;
        trigger_buf[2] <= PlayerDragonCollision;
        if (frame_delay[1])
          frame_delay <= 2'b00;
        else begin
          frame_delay[0] <= frame_end;
          frame_delay[1] <= frame_delay[0];  //keep sound active two frame, avoid collison happens near the frame end
        end
    end
  end
  
  // detect the rising edge of the trigger signals
  always @ (posedge clk) begin
    if (!test_mode) begin
      if (SheepDragonCollision & ~trigger_buf[0]) begin
        eat_sound <= 1'b1;
      end else if(frame_delay[1]) begin
        eat_sound <= 1'b0; end

      if (SwordDragonCollision & ~trigger_buf[1])  begin
        die_sound <= 1'b1;
      end else if(frame_delay[1])begin
        die_sound <= 1'b0;end

      if (PlayerDragonCollision & ~trigger_buf[2])  begin
        hit_sound <= 1'b1;
      end else if(frame_delay[1] & ~PlayerDragonCollision)begin //player dragon collision logic issue, continue activated during collision
        hit_sound <= 1'b0;end
    end else begin
      eat_sound <= SheepDragonCollision;
      die_sound <= PlayerDragonCollision;
      hit_sound <= SwordDragonCollision;
    end
  end
endmodule

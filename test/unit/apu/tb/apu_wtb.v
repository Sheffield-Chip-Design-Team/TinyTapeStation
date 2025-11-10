`default_nettype none `timescale 1ns / 1ns

module apu_tb ();

  // AudioProcessingUnit
  reg clk;
  reg reset;
  reg saw_trigger;
  reg square_trigger;
  reg noise_trigger;
  reg [9:0] x;
  reg [9:0] y;
  wire sound;

  AudioProcessingUnit audioprocessingunit (
      .clk(clk),
      .reset(reset),
      .saw_trigger(saw_trigger),
      .square_trigger(square_trigger),
      .noise_trigger(noise_trigger),
      .x(x),
      .y(y),
      .sound(sound)
  );

  initial begin
    $dumpfile("apu.vcd");
    $dumpvars(0, apu_tb);
    #1;
  end
endmodule

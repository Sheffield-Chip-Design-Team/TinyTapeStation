// Author: Tovio Henningson
// Taken from https://github.com/toivoh/tt05-synth

// A simple parameterized down-counter module that counts down by a configurable step size
module Osc_Counter #( parameter PERIOD_BITS = 8, LOG2_STEP = 0 ) (
		input wire [PERIOD_BITS-1:0] period0,
		input wire [PERIOD_BITS-1:0] period1,
		input wire enable,
		output wire trigger,

		// External state: Provide current state in counter, update it to next_counter if counter_we is true.
		input wire [PERIOD_BITS-1:0] counter,
		output wire counter_we,
		output wire [PERIOD_BITS-1:0] next_counter
	);

	assign trigger = enable & !(|counter[PERIOD_BITS-1:LOG2_STEP]); // Trigger if decreasing by 1 << LOG2_STEP would wrap around.

	wire [PERIOD_BITS-1:0] delta_counter = (trigger ? period1 : period0) - (1 << LOG2_STEP);

	assign counter_we = enable;
	assign next_counter = counter + delta_counter;
endmodule

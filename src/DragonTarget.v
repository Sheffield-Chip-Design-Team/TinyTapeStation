// Module to control dragon target behavior in a game
// Author: James Ashie Kotey, Bowen Shi

module DragonTarget(
      input wire clk,
      input wire reset,
      input wire trigger,
      input wire dragon_hurt,
      input wire target_reached_player,
      input wire target_reached_sheep,
      input wire [6:0] dragon_state,
      input wire [7:0] dragon_pos,
      input wire [7:0] player_pos, 
      input wire [7:0] sheep_pos,
      input wire rnd_timer,
      output wire [7:0] target_pos
);
    
    reg [7:0] target_pos_reg;
    reg [2:0] DragonBehaviourState=0;
    reg [2:0] NextDragonBehaviourState=2;


    always @(posedge clk) begin
    
          if (~reset) begin

            if (trigger) begin
                DragonBehaviourState <= NextDragonBehaviourState;
            end
    
          end else begin
            DragonBehaviourState <= 2;

          end
    end

    wire [7:0] inverse_sheep = {~sheep_pos[7:4], 4'b1100-sheep_pos[3:0]};

    always @(posedge clk) begin

         if (~reset) begin
             
              case (DragonBehaviourState)
        
                2: begin //chase the player
                  target_pos_reg <= player_pos;
                  if (dragon_hurt | target_reached_player)  NextDragonBehaviourState <= {2'b00, rnd_timer}; 
                end
        
                0: begin // chase the sheep
                  target_pos_reg <= sheep_pos;
                  if (dragon_hurt | target_reached_sheep) NextDragonBehaviourState <= 1;
                end
        
                1: begin // retreat to a corner (use two of the bits of the rng?
                   target_pos_reg <= inverse_sheep;
                   if (dragon_pos == inverse_sheep) NextDragonBehaviourState <= 2; // randomize target
               end
        
                default : begin 
                  target_pos_reg <= target_pos_reg;
                end
            endcase
              
              end else begin   
                NextDragonBehaviourState <= 2;
                target_pos_reg <= 0;
              end
     end
   assign target_pos = target_pos_reg;
endmodule
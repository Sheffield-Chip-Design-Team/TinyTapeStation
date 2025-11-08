
// Module : Dragon Body
// Author: Bowen Shi

/* 
    Description:
    The Dragon body segment 
            
*/

module DragonBody(

    input clk,
    input reset,
    input vsync,
    input heal,                         // grow
    input hit,                          // shrink
    input [31:0] current_time,
    input [5:0] movementCounter,
    input [9:0] Dragon_Head,            // [9:8] orientation, [7:0]  position

    output reg [9:0] Dragon_1,          // Every 10 bit represent a body segment, Maximum of 8 segments, works as a queue.
    output reg [9:0] Dragon_2,
    output reg [9:0] Dragon_3,
    output reg [9:0] Dragon_4,
    output reg [9:0] Dragon_5,
    output reg [9:0] Dragon_6,
    output reg [9:0] Dragon_7,

    output reg [6:0] Display_en
);

    reg pre_vsync;

    reg heal_reg, hit_reg;
    wire heal_pause,hit_pause;
    always @(posedge clk) heal_reg <= heal;
    always @(posedge clk) hit_reg <= hit;

    assign heal_pause = heal & !heal_reg;
    assign hit_pause = hit & !hit_reg;

    reg [31:0] time_1;


    always @(posedge clk)begin
        if (~reset) begin
        
            pre_vsync <= vsync;

            if (pre_vsync != vsync && pre_vsync == 0) begin
                
                if (movementCounter == 6'd10) begin
                    Dragon_1 <= Dragon_Head;
                    Dragon_2 <= Dragon_1;
                    Dragon_3 <= Dragon_2;
                    Dragon_4 <= Dragon_3;
                    Dragon_5 <= Dragon_4;
                    Dragon_6 <= Dragon_5;
                    Dragon_7 <= Dragon_6;
                end

            end 
        end else begin
            Dragon_1 <= {2'b00,8'hFB};
            Dragon_2 <= {2'b00,8'hFB};
            Dragon_3 <= {2'b00,8'hFB};
            Dragon_4 <= {2'b00,8'hFB};
            Dragon_5 <= {2'b00,8'hFB};
            Dragon_6 <= {2'b00,8'hFB};
            Dragon_7 <= {2'b00,8'hFB};
        end
    end

    wire [31:0] interval = current_time - time_1;
    wire colddown = interval > 32'h01000000;

    always @( posedge clk )begin
        if(~reset) begin
            case(1'b1) 
                heal_pause&(Dragon_1[7:0]!=8'hFB): begin
                    Display_en <= (Display_en << 1) | 7'b0000001;
                end
                hit_pause&(Dragon_1[7:0]!=8'hFB)&colddown: begin
                    Display_en <= Display_en >> 1;
                    time_1 <= current_time;
                end
                default: Display_en <= Display_en;
            endcase
        end else begin
            Display_en <= 7'b0000111;
        end
    end
endmodule
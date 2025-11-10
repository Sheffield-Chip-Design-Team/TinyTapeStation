
/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Authors: James Ashie Kotey, Bowen Shi, Kwashie Andoh, Anubhav Avinash
 * Abdulatif Babli, Rupert Bowen, K Arjunan, Cameron Brizland
 * Last Updated:  16/06/2025 @ 16:21:00
 */

 // Tiny Tapestation Top Module

//  === SIMULATION BUILD DEPENDENCIES ===
//   `include "InputCollector.v"
//   `include "CollisionDetector.v"
//   `include "Heart.v"
//   `include "Player.v"
//   `include "DragonHead.v"
//   `include "DragonBody.v"
//   `include "DragonTarget.v"
//   `include "Sheep.v"
//   `include "Sync.v"
//   `include "PPU.v"
//   `include "SpriteROM.v"
//   `include "APU.v"
//   `include "APU_trigger.v"
//   `include "RNG.v"
//  === END ===

module tt_um_enjimneering_tts_top ( 
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset   
);

    // Interface signals between input modules
    wire nes_data = ui_in[0];
    // both are assigned on line 432
    wire nes_clk;
    wire nes_latch;
    
    wire snes_pmod_data = ui_in[6];
    wire snes_pmod_clk = ui_in[5];
    wire snes_pmod_latch = ui_in[4];

    // Output signals from nesReciver
    wire A_out;
    wire B_out;
    wire select_out;
    wire start_out;
    wire up_out;
    wire down_out;
    wire left_out;
    wire right_out;
    // extra SNES signals
    wire X_out;
    wire Y_out;
    wire L_out;
    wire R_out;
    wire is_snes;

    NESTest_Top nes_snes_module (
        // system
        .system_clk_25MHz(clk),
        .rst_n(rst_n|auto_rst_n),         // active low reset

        // NES controller interface [GPIO]. We generate latch and clock internally and send to controller. Data returns.
        .NES_Data(nes_data), // NES controller data -> ui_in[0]
        .NES_Clk(nes_clk), // uo_out[1] -> NES controller clk
        .NES_Latch(nes_latch), // uo_out[2] -> NES controller latch

        // SNES PMOD interface [3 pins]
        .SNES_PMOD_Data(snes_pmod_data),    // PMOD IO7 ->  ui_in[1] 
        .SNES_PMOD_Clk(snes_pmod_clk),     // PMOD IO6 ->  ui_in[2]
        .SNES_PMOD_Latch(snes_pmod_latch),   // PMOD IO5 ->  ui_in[3]

        // button states: to data_out[7:0] on address 0x1
        .A_out(A_out),
        .B_out(B_out),
        .select_out(select_out),
        .start_out(start_out),
        .up_out(up_out),
        .down_out(down_out),
        .left_out(left_out),
        .right_out(right_out),
        
        // Additional SNES buttons: to data_out[3:0] on address 0x2
        .X_out(X_out),
        .Y_out(Y_out),
        .L_out(L_out),
        .R_out(R_out),
        
        // Status indicator: to data_out[0] on address 0x0
        .controller_status(is_snes)  // 1 = SNES active, 0 = NES active
    );

    // input signals
    wire [9:0] input_data; // register to hold the 5 possible player actions
   
    wire [4:0] released_buttons = input_data[4:0];
    wire [4:0] pressed_buttons  = input_data[9:5];

    //timing signals
    wire pixel_value;
    wire frame_end;

    reg player_trigger;
    reg collector_trigger;
    wire frame_end_b = collector_trigger;

    // Global Timer
    reg [31:0] timer;
    initial timer =0;
    always @(posedge clk) timer <= timer+1;
    
     always @(posedge clk ) begin
       player_trigger <= frame_end;
       collector_trigger <= player_trigger;
     end

    InputCollector ic(
        .clk( clk),
        .reset(collector_trigger),
        .up(up_out),  
        .down(down_out),
        .left(left_out),
        .right(right_out),
        .attack(A_out),
        .control_state(input_data)
    );

    wire PlayerDragonCollision;
    wire SwordDragonCollision;
    wire SheepDragonCollision;
    
    // attack enable logic
    reg attack_enable;
    reg [31:0] current_time;
    wire attack_released = released_buttons[4];

    always @(posedge clk) begin
        if (attack_released) current_time <= timer;
        if (timer - current_time > 32'h000000FF) begin // change this constant to change the attack enabled/disabled
            attack_enable <= 1;
        end else begin
            attack_enable <= 0;
        end
    end
    
    // player movement and attack logic
    // orientation and direction: 
    // 00 - up, 01 - right, 10 - down, 11 - left  

    wire [1:0] playerLives;
    wire [7:0] player_pos;                 // player position: xxxx_yyyy
    wire [1:0] player_orientation;         // player orientation 
    wire [1:0] player_direction;           // player direction
    wire [3:0] player_sprite;

    wire [7:0] sword_pos;                   // sword position: xxxx_yyyy
    wire [3:0] sword_sprite;
    wire [1:0] sword_orientation;           // sword orientation 
    
    wire [6:0] VisibleSegments;
    wire [7:0] target_pos;
  
    
    wire [7:0] sheep_pos;
    
    reg auto_rst_n;
    always @(posedge clk) begin
        auto_rst_n <= playerLives != 2'b00;
    end
    
    CollisionDetector collisionDetector (
        .clk( clk),
        .reset(vsync),
        .playerPos(player_pos),
        .swordPos(sword_pos),
        .sheepPos(sheep_pos),
        .attack_enable(attack_enable),
        .activeDragonSegments(VisibleSegments),
        .dragonSegmentPositions(
            {Dragon_1[7:0],
            Dragon_2[7:0],
            Dragon_3[7:0],
            Dragon_4[7:0],
            Dragon_5[7:0],
            Dragon_6[7:0],
            Dragon_7[7:0]} ),
        .playerDragonCollision(PlayerDragonCollision),
        .swordDragonCollision(SwordDragonCollision),
        .sheepDragonCollision(SheepDragonCollision)
    );

    wire playerHurt;

    Hearts #(
        .PlayerTolerance(1)
    ) hearts (
        .clk( clk),
        .vsync(vsync),
        .reset(~rst_n|~auto_rst_n),
        .PlayerDragonCollision(PlayerDragonCollision),
        .PlayerHurt(playerHurt),
        .playerLives(playerLives)
    );

    PlayerLogic playlogic(
        .clk( clk),
        .reset(~rst_n | playerHurt | ~auto_rst_n),
        .input_data(input_data),
        .trigger(player_trigger),
        // .attack_enable(attack_enable),
        .player_sprite(player_sprite),
        .player_pos(player_pos),
        .player_orientation(player_orientation),
        .player_direction(player_direction),
        
        .sword_visible(sword_sprite),
        .sword_position(sword_pos),
        .sword_orientation(sword_orientation)
    );

    // dragon logic 
    wire [1:0] dragon_direction;
    wire [7:0] dragon_position;
    wire [5:0] movement_delay_counter;
    
    DragonTarget dragonBrain(
        .clk( clk),
        .reset(~rst_n|~auto_rst_n),
        .trigger(frame_end_b),
        .target_reached_player(PlayerDragonCollision),
        .target_reached_sheep(SheepDragonCollision),
        .dragon_pos(dragon_position),
        .dragon_state(VisibleSegments),
        .dragon_hurt(SwordDragonCollision),
        .player_pos(player_pos), 
        .rnd_timer(timer[0]),
        .sheep_pos(sheep_pos),
        .target_pos(target_pos)
    );
    
    DragonHead dragonHead( 
        .clk( clk),
        .reset(~rst_n|~auto_rst_n),
        .targetPos(target_pos),
        .vsync(vsync),
        .dragon_direction(dragon_direction),
        .dragon_pos(dragon_position),
        .movement_counter(movement_delay_counter)// Counter for delaying dragon's movement otherwise sticks to player
    );

    reg ShDC_Delay;
    reg SwDc_Delay;
    always@(posedge clk) if(rst_n|auto_rst_n) ShDC_Delay <= SheepDragonCollision; else ShDC_Delay <= 0;
    always@(posedge  clk) if(rst_n|auto_rst_n) SwDc_Delay <= SwordDragonCollision; else SwDc_Delay <= 0;
    
    wire [9:0]   Dragon_1 ;
    wire [9:0]   Dragon_2 ;
    wire [9:0]   Dragon_3 ;
    wire [9:0]   Dragon_4 ;
    wire [9:0]   Dragon_5 ;
    wire [9:0]   Dragon_6 ;
    wire [9:0]   Dragon_7 ;

    DragonBody dragonBody(

        .clk( clk),
        .reset(~rst_n|~auto_rst_n),
        .heal(SheepDragonCollision),
        .hit(SwordDragonCollision),
        .Dragon_Head({dragon_direction, dragon_position}),
        .movementCounter(movement_delay_counter),
        .vsync(vsync),
        .current_time(timer),
        .Dragon_1(Dragon_1),
        .Dragon_2(Dragon_2),
        .Dragon_3(Dragon_3),
        .Dragon_4(Dragon_4),
        .Dragon_5(Dragon_5),
        .Dragon_6(Dragon_6),
        .Dragon_7(Dragon_7),

        .Display_en(VisibleSegments)
    );

    // sheep position logic
    reg [3:0] sheep_sprite =4'b0111;
    reg SDC_Buffer;

    always@(posedge clk) SDC_Buffer <= SheepDragonCollision;
    wire SDC_pulse = SDC_Buffer & !SheepDragonCollision;
    
    // random nuumber generator based on linear feedback + seed
    rng randnum ( 
      .clk(clk),
      .reset(~rst_n|~auto_rst_n),
      .trigger(~rst_n | SheepDragonCollision |~auto_rst_n),
      .seed({timer[2:0],player_pos[6:2]}^Dragon_1[7:0]), // Seed input for initializing randomness
      .rdm_num(sheep_pos)
     );

    // Picture Processing Unit
    PictureProcessingUnit ppu (

        .clk_in         (clk),
        .reset          (~rst_n | ~auto_rst_n), 
        .entity_1       ({4'b0000, 2'b00, 8'b1111_0000, {2'b00, playerLives} }),           // heart
        .entity_2       ({player_sprite, player_orientation , player_pos,  4'b0001}),      // player
        .entity_3       ({sword_sprite, sword_orientation, sword_pos, 4'b0001}),           // sword
        .entity_4       ({sheep_sprite, 2'b01 , sheep_pos,  4'b0001}),                // sheep 
        .entity_5       (18'b1111_11_1111_1111_0001),                                      // empty - sheep 2
        .entity_6       (18'b1111_11_1111_1111_0001),                                   // empty
        .entity_7       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_8       (18'b1111_11_1111_1111_0001),                                      // empty
        .entity_9       ({4'b0110,Dragon_1,3'b000,VisibleSegments[0]}),                    // dragon parts
        .entity_10      ({4'b0100,Dragon_2,3'b000,VisibleSegments[1]}),  
        .entity_11      ({4'b0100,Dragon_3,3'b000,VisibleSegments[2]}),  
        .entity_12      ({4'b0100,Dragon_4,3'b000,VisibleSegments[3]}),
        .entity_13      ({4'b0100,Dragon_5,3'b000,VisibleSegments[4]}),
        .entity_14      ({4'b0100,Dragon_6,3'b000,VisibleSegments[5]}), 
        .entity_15      ({4'b0100,Dragon_7,3'b000,VisibleSegments[6]}),        
        .counter_V      (pix_y),
        .counter_H      (pix_x),
        
        .colour         (pixel_value)
    );

    // display sync signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // sync generator unit 
    sync_generator sync_gen (
        .clk( clk),
        .reset(~rst_n|~auto_rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .screen_hpos(pix_x),
        .screen_vpos(pix_y),
        .frame_end(frame_end)
    );

    // outpout colour signals
    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;

    // display logic
    always @(posedge  clk) begin
        
        if (~rst_n|~auto_rst_n) begin
        R <= 0;
        G <= 0;
        B <= 0;
        
        end else begin
            if (video_active) begin // display output color from Frame controller unit
                if (PlayerDragonCollision == 0 & SwordDragonCollision == 0) begin // no collision - black
                    R <= pixel_value ? 2'b11 : 2'b00;
                    G <= pixel_value ? 2'b11 : 2'b00;
                    B <= pixel_value ? 2'b11 : 2'b00;
                end

                if (PlayerDragonCollision == 1 & SwordDragonCollision == 0) begin // dragon hurs playher rtcollision - red
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 0;
                    B <= pixel_value ? 2'b11 : 0;
                end

                if (PlayerDragonCollision == 0 & SwordDragonCollision == 1) begin // sword hurts dragon hurts dragon collision - blue
                    R <= pixel_value ? 2'b11 : 2'b0;
                    G <= pixel_value ? 2'b11 : 2'b0;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

               if (PlayerDragonCollision == 1 & SwordDragonCollision == 1) begin // both collision simultaneouslt  sword hurts dragon hurts dragon collision - blue
                    R <= pixel_value ? 2'b11 : 2'b11;
                    G <= pixel_value ? 2'b11 : 2'b00;
                    B <= pixel_value ? 2'b11 : 2'b11;
                end

            end else begin
                R <= 0;
                G <= 0;
                B <= 0;
            end
        end
    end

    // Audio signals
    wire sound;
    wire trig_eat;
    wire trig_die;
    wire trig_hit;

    APU_trigger apu_trig (
        .clk(clk),
        .reset(~rst_n|~auto_rst_n),
        .frame_end(frame_end),     // TODO: use frame end signal here
        .SheepDragonCollision(SheepDragonCollision),    
        .SwordDragonCollision(SwordDragonCollision),
        .PlayerDragonCollision(PlayerDragonCollision),
        .test_mode(1'b0),
        .eat_sound(trig_eat),
        .die_sound(trig_die),
        .hit_sound(trig_hit)
    );
    
    AudioProcessingUnit apu (
        .clk(clk),
        .reset(~rst_n|~auto_rst_n),
        .saw_trigger(trig_eat),
        .noise_trigger(trig_die),
        .square_trigger(trig_hit),
        .x(pix_x),
        .y(pix_y),
        .sound(sound)
    );

    // TODO: check these

    // System IO Connections
    assign nes_data = ui_in[0];
    assign uio_oe   = 8'b1000_0110;
    assign uio_out  = {sound, 4'b0000, nes_latch, nes_clk, 1'b0};
    assign uo_out   = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // housekeeping to prevent errors/ warnings in synthesis.
    wire _unused_ok = &{ena, uio_in[7:1]}; 

endmodule

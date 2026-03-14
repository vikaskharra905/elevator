`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2026 02:26:43 PM
// Design Name: 
// Module Name: elevator_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module elevator_controller (
    input wire clk,               // Clock signal
    input wire rst,               // Synchronous reset (returns elevator to ground floor)
    input wire emergency_stop,    // Emergency stop button (high to trigger)
    input wire [3:0] req,         // 4-bit floor requests (req[0]=Ground, req[3]=3rd floor)
    
    output reg [1:0] current_floor, // Indicates floor 00, 01, 10, or 11
    output reg door_open,         // High when the door is open
    output reg moving_up,         // High when moving up
    output reg moving_down,       // High when moving down
    output reg alarm              // High during emergency
);

    // FSM State Encodings
    localparam IDLE      = 3'd0;
    localparam UP        = 3'd1;
    localparam DOWN      = 3'd2;
    localparam OPEN_DOOR = 3'd3;
    localparam EMERGENCY = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        // 1. Handle Reset
        if (rst) begin
            state         <= IDLE;
            current_floor <= 2'd0; // Reset to Ground Floor
            door_open     <= 1'b0;
            moving_up     <= 1'b0;
            moving_down   <= 1'b0;
            alarm         <= 1'b0;
        end 
        
        // 2. Handle Emergency Stop Button
        else if (emergency_stop) begin
            state         <= EMERGENCY;
            door_open     <= 1'b0; // Safety: close doors while halted between floors
            moving_up     <= 1'b0; // Cut off motors
            moving_down   <= 1'b0;
            alarm         <= 1'b1; // Trigger emergency alarm
        end 
        
        // 3. Normal Elevator Operations
        else begin
            alarm <= 1'b0; // Turn off alarm if emergency is cleared
            
            case (state)
                IDLE: begin
                    door_open   <= 1'b0;
                    moving_up   <= 1'b0;
                    moving_down <= 1'b0;
                    
                    // Priority 1: Request at the current floor
                    if (req[current_floor]) begin
                        state <= OPEN_DOOR;
                    end 
                    // Priority 2: Requests above the current floor
                    else if ( (current_floor == 2'd0 && (req[1] || req[2] || req[3])) ||
                              (current_floor == 2'd1 && (req[2] || req[3])) ||
                              (current_floor == 2'd2 && req[3]) ) begin
                        state <= UP;
                    end 
                    // Priority 3: Requests below the current floor
                    else if ( (current_floor == 2'd3 && (req[2] || req[1] || req[0])) ||
                              (current_floor == 2'd2 && (req[1] || req[0])) ||
                              (current_floor == 2'd1 && req[0]) ) begin
                        state <= DOWN;
                    end
                end

                UP: begin
                    moving_up   <= 1'b1;
                    moving_down <= 1'b0;
                    door_open   <= 1'b0;
                    
                    // Simulate moving up one floor per clock cycle
                    current_floor <= current_floor + 1'b1;
                    state <= IDLE; // Return to IDLE to evaluate if we need to stop or keep going
                end

                DOWN: begin
                    moving_up   <= 1'b0;
                    moving_down <= 1'b1;
                    door_open   <= 1'b0;
                    
                    // Simulate moving down one floor per clock cycle
                    current_floor <= current_floor - 1'b1;
                    state <= IDLE; // Return to IDLE to evaluate
                end

                OPEN_DOOR: begin
                    door_open   <= 1'b1;
                    moving_up   <= 1'b0;
                    moving_down <= 1'b0;
                    
                    // NOTE: The elevator will stay in this state until the external 
                    // system or testbench clears the `req` bit for the current floor.
                    if (!req[current_floor]) begin
                        state <= IDLE;
                    end
                end

                EMERGENCY: begin
                    // If the emergency_stop button is released, return to IDLE
                    if (!emergency_stop) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

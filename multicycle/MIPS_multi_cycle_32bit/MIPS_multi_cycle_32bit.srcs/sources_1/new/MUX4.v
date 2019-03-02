`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/07 16:58:06
// Design Name: 
// Module Name: MUX4
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


module MUX4 #(parameter WIDTH=8)
    (
    input [WIDTH-1:0] d00,d01,d10,d11,
    input [1:0] s,
    output reg [WIDTH-1:0] y
    );
    
    always@(*)
    begin
        case(s)
        2'b00:y<=d00;
        2'b01:y<=d01;
        2'b10:y<=d10;
        2'b11:y<=d11;
        endcase
    end
    
endmodule

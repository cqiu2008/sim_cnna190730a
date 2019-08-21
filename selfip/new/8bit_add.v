`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/08/06 08:29:21
// Design Name: 
// Module Name: 8bit_add
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// the result will be output after 3clks
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module a8bit_add(
    input         I_clk,
    input  [23:0] I_adder0,
    input  [23:0] I_adder1,
    output [23:0] O_sum
    );
    
    reg  [7:0]   S_adder00=0;
    reg  [7:0]   S_adder01=0;
    reg  [7:0]   S_adder02=0;
    reg  [7:0]   S_adder10=0;
    reg  [7:0]   S_adder11=0;
    reg  [7:0]   S_adder12=0;
    reg  [8:0]   S_sum00=0;
    reg  [8:0]   S_sum01=0;
    reg  [8:0]   S_sum02=0;
    
    reg  [7:0]   S_adder01_d1=0;
    reg  [7:0]   S_adder02_d1=0;
    reg  [7:0]   S_adder02_d2=0;
    reg  [7:0]   S_adder11_d1=0;
    reg  [7:0]   S_adder12_d1=0;
    reg  [7:0]   S_adder12_d2=0;
    reg  [7:0]   S_sum00_d1=0;
    reg  [7:0]   S_sum00_d2=0;
    reg  [7:0]   S_sum01_d1=0;
    
    always@ (posedge I_clk)
    begin
        S_adder00 <= I_adder0[7:0];
        S_adder01 <= I_adder0[15:8];
        S_adder02 <= I_adder0[23:16];
    
        S_adder10 <= I_adder1[7:0];
        S_adder11 <= I_adder1[15:8];
        S_adder12 <= I_adder1[23:16];
    end
    
    always@ (posedge I_clk)
    begin
        S_adder01_d1 <= S_adder01;
        S_adder02_d1 <= S_adder02;
        S_adder02_d2 <= S_adder02_d1;
        
        S_adder11_d1 <= S_adder11;
        S_adder12_d1 <= S_adder12;
        S_adder12_d2 <= S_adder12_d1;
    end
    
    always@ (posedge I_clk)
    begin
        S_sum00 <= S_adder00 + S_adder10;
        S_sum01 <= S_adder01_d1 + S_adder11_d1 + S_sum00[8];
        S_sum02 <= S_adder02_d2 + S_adder12_d2 + S_sum01[8];
    end
    
    always@ (posedge I_clk)
    begin
        S_sum00_d1 <= S_sum00;
        S_sum00_d2 <= S_sum00_d1;
        S_sum01_d1 <= S_sum01;
    end
    
    assign O_sum = {S_sum02[7:0],S_sum01_d1[7:0],S_sum00_d2[7:0]};
    
endmodule

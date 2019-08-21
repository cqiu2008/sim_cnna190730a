`timescale 1ns / 1ps

module my_divider1(
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] o_quotient,
    output reg [7:0] o_remainder
    );
    
    reg [7:0] tempa;
    reg [7:0] tempb;
    reg [15:0] temp_a;
    reg [15:0] temp_b;
    
    integer i;
    always@ (a or b)
    begin
        tempa <= a;
        tempb <= b;
    end
    
    always@ (tempa or tempb)
    begin
        temp_a = {8'h00,tempa};
        temp_b = {tempb,8'h00};
        for (i=0; i<8; i=i+1)
        begin
            temp_a = {temp_a[14:0],1'b0};
            if (temp_a[15:8] >= tempb)
                temp_a = temp_a - temp_b + 1'b1;
            else
                temp_a = temp_a;
        end
        o_quotient <= temp_a[7:0];
        o_remainder <= temp_a[15:8];
    end
    
    
endmodule

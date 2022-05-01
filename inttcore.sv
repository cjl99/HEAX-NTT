/*
 * @Author: jialiang.chen 
 * @Date: 2022-05-01 19:53:09 
 * @Last Modified by: jialiang.chen
 * @Last Modified time: 2022-05-01 21:23:12
 */
`include "defines.v"

module inttcore (
    input clk,
    input reset,
    input [`CIPHER_SIZE-1:0] cin_a,
    input [`CIPHER_SIZE-1:0] cin_b,
    input [`CIPHER_SIZE-1:0] w,
    input [`CIPHER_SIZE-1:0] wp,
    input [`CIPHER_SIZE-1:0] q,

    wire [`CIPHER_SIZE-1:0] debug_outa,
    wire [`CIPHER_SIZE-1:0] debug_temp1,
    wire [`CIPHER_SIZE-2:0] debug_temp3,
    wire [`CIPHER_SIZE:0] debug_temp5,

    output reg [`CIPHER_SIZE-1:0] cout_a,
    output reg [`CIPHER_SIZE-1:0] cout_b
);

reg [`CIPHER_SIZE-1:0] outa_late1;

wire [`CIPHER_SIZE:0] newa_1, newa_2;
wire [`CIPHER_SIZE:0] newb_1, newb_2;
wire [`CIPHER_SIZE-1:0] outa, newb, outb;

reg [`CIPHER_SIZE-1:0] temp1;
reg [(`CIPHER_SIZE<<1)-2:0] temp2;
wire [`CIPHER_SIZE-2:0] temp3;
wire [`CIPHER_SIZE-1:0] temp4;
wire [`CIPHER_SIZE:0] temp5;


// -------------------------- debug
assign debug_outa = outa;
assign debug_temp1 = temp1;
assign debug_temp3 = temp3;
assign debug_temp5 = temp5;

// -------------------------------
assign newa_1 = (cin_a + cin_b);
assign newa_2 = (cin_a + cin_b - q);
assign outa = (newa_1 >= q) ? newa_2 : newa_1;

assign newb_1 = cin_a - cin_b;
assign newb_2 = (cin_a - cin_b + q);

assign newb = cin_a >= cin_b ? newb_1 : newb_2;
// assign newb = newb_1;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        temp1 <= 0;
        temp2 <= 0;
        outa_late1 <= 0;
    end
    else begin
        temp1 <= (newb * w);
        temp2 <= (newb * wp);
        outa_late1 <= outa;    
    end
end

assign temp3 = temp2 >> `CIPHER_SIZE;
assign temp4 = temp3 * q;
assign temp5 = temp1 - temp4;
assign outb = temp1 >= q ? temp5 : temp1;

always @(*) begin
    if (reset) begin
        cout_a <= 0;
        cout_b <= 0;
    end
    else begin
        cout_a <= outa_late1;
        cout_b <= outb;
    end
end


endmodule

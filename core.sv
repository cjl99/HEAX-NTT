/*
 * @Author: jialiang.chen 
 * @Date: 2022-04-19 20:19:57 
 * @Last Modified by: jialiang.chen
 * @Last Modified time: 2022-04-19 20:53:30
 */

`include "defines.v"

module core (
    input clk,
    input reset,
    input [`CIPHER_SIZE-1:0] cin_a,
    input [`CIPHER_SIZE-1:0] cin_b,
    input [`CIPHER_SIZE-1:0] w,
    input [`CIPHER_SIZE-1:0] wp,
    input [`CIPHER_SIZE-1:0] q,

    output  [`CIPHER_SIZE-1:0] cout_a,
    output [`CIPHER_SIZE-1:0] cout_b
);

reg [`CIPHER_SIZE-1:0] z;
reg [(`CIPHER_SIZE<<1)-2:0] tt;
reg  [`CIPHER_SIZE-1:0] cin_a_late;

wire  [`CIPHER_SIZE-1:0] z_err;
wire [`CIPHER_SIZE-2:0] t;

wire [`CIPHER_SIZE-1:0] newb, newb1;


wire [`CIPHER_SIZE:0] outa,outa1;
wire [`CIPHER_SIZE:0] outb,outb1; // one bit more


always @(posedge clk or posedge reset) begin
    if(reset) begin
        z <= 0;
        tt <= 0;
        cin_a_late <=0;
    end
    else begin
        z <= (cin_b * w);
        tt <= (cin_b * wp);
        cin_a_late <= cin_a;
    end
end


assign t = (tt >> `CIPHER_SIZE);
assign z_err = (t * q);

assign newb = z - z_err;
assign newb1 = newb>=q ? newb-q : newb;

assign outa = cin_a_late + newb1; // auto zero padding, the result is one bit more
assign outa1 = (outa >= q) ? outa - q : outa;

assign outb = cin_a_late + q - newb1;
assign outb1 = (outb >= q) ? outb - q : outb;
assign cout_a = outa1[`CIPHER_SIZE-1:0];
assign cout_b = outb1[`CIPHER_SIZE-1:0];


// always @(posedge clk or posedge reset) begin
//    if(reset) begin
//        cout_a <= 0;
//        cout_b <= 0;
//    end
//    else begin
//         cout_a = outa1[`CIPHER_SIZE-1:0];
//         cout_b = outb1[`CIPHER_SIZE-1:0];
//    end
// end

endmodule

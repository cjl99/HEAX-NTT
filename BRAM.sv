/*
 * @Author: jialiang.chen 
 * @Date: 2022-04-19 16:23:16 
 * @Last Modified by: jialiang.chen
 * @Last Modified time: 2022-04-19 16:47:15
 */
`timescale 1ns / 1ps

// each element has width's bits
// the bram has 2<<len elements

module BRAM #(
    parameter width = 32, len=9
)
(
    input                 clk,
    input                 wen,      // write enable
    input      [len-1:0] waddr,    // write address
    input      [width-1:0] din,      // data input
    input      [len-1:0] raddr,    // read address
    output reg [width-1:0] dout      // data output
    );
    
// block ram
(* ram_style="block" *) reg [width-1:0] blockram [(1<<len)-1:0];

// write operation
always @(posedge clk) begin
    if(wen)
        blockram[waddr] <= din;
end

// read operation
always @(posedge clk) begin
    dout <= blockram[raddr];
end

endmodule

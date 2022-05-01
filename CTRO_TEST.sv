/*
 * @Author: jialiang.chen 
 * @Date: 2022-04-19 19:33:50 
 * @Last Modified by: jialiang.chen
 * @Last Modified time: 2022-04-22 20:44:18
 */
`include "defines.v"

module CONTROL_TEST();

parameter HP = 5;
parameter FP = (2*HP);

reg clk,reset;
reg start;
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] raddr;
wire  [`LOG_RING_SIZE-`LOG_NTT_CORE-1:0] raddr_tw;
wire eo_signal;
wire type_signal;
wire finished;

    // debug data -- which are not necessary for output
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0]   c_loop;
wire [4:0] c_stage;
wire [2*`NTT_CORE*(`LOG_NTT_CORE+1)-1:0] brscramble;
wire [`NTT_CORE*(`LOG_NTT_CORE+1)-1:0 ] me_sela_new;
wire [`NTT_CORE*(`LOG_NTT_CORE+1)-1:0 ] me_selb_new;
wire [`LOG_NTT_CORE-1:0] tw_sel0,tw_sel1,tw_sel2,tw_sel3,tw_sel4,tw_sel5,tw_sel6,tw_sel7;



// ---------------------------------------------------------------- CLK
always #HP clk = ~clk;


// ---------------------------------------------------------------- TEST case
integer k;
initial begin: CLK_RESET_INIT
	clk       = 0;
	reset     = 0;

	#100;
	reset    = 1;
	#100;
	reset    = 0;
	#100;
end

initial begin: INI
    start = 0;
    #300;

    // load w
    start = 1;
    #FP;
    start = 0;

	while(finished == 0)
		#FP;
	#FP;

    $stop();
end

Controller ag( 
    .clk(clk),
    .reset(reset),
    .start(start),
    .raddr(raddr),
    .raddr_tw(raddr_tw),
    .eo_signal(eo_signal),
    .type_signal(type_signal),
    .finished(finished),
    .c_loop(c_loop),
    .c_stage(c_stage),
    // .brscramble(brscramble),
    .me_sela_new(me_sela_new),
    .me_selb_new(me_selb_new),
    .tw_sel0(tw_sel0),
    .tw_sel1(tw_sel1),    
    .tw_sel2(tw_sel2),
    .tw_sel3(tw_sel3),    
    .tw_sel4(tw_sel4),
    .tw_sel5(tw_sel5),
    .tw_sel6(tw_sel6),
    .tw_sel7(tw_sel7));

endmodule

/*
 * @Author: jialiang.chen 
 * @Date: 2022-04-19 19:33:50 
 * @Last Modified by: jialiang.chen
 * @Last Modified time: 2022-04-19 19:51:09
 */
`include "defines.v"

module NTT_TEST();

parameter HP = 5;
parameter FP = (2*HP);

reg                       clk,reset;
reg                       load_w;
reg                       load_data;
reg                       start;
reg                       start_intt;
reg	[`CIPHER_SIZE-1:0] 	din;
wire done;
wire [`CIPHER_SIZE-1:0]   dout;


wire  [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] debug_raddr;
wire  [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] debug_waddr;
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-1:0] debug_raddr_tw;
wire  [`LOG_NTT_CORE:0] debug_me_sela [`NTT_CORE-1:0];
wire  [`LOG_NTT_CORE:0] debug_me_selb [`NTT_CORE-1:0];
wire  [`LOG_NTT_CORE-1:0] debug_tw_sel [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]  debug_core_in_a   [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]  debug_core_in_b   [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]  debug_core_w     [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]  debug_core_wp    [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]  debug_core_out_a  [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]  debug_core_out_b  [`NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0] debug_MEe [`DOUBLE_NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0] debug_MEo [`DOUBLE_NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0] debug_MEs [`DOUBLE_NTT_CORE-1:0];
wire [`CIPHER_SIZE-1:0] debug_MEe_back [`DOUBLE_NTT_CORE-1:0];
wire [`CIPHER_SIZE-1:0] debug_MEo_back [`DOUBLE_NTT_CORE-1:0];
wire [`CIPHER_SIZE-1:0] debug_MEs_back [`DOUBLE_NTT_CORE-1:0];
wire  [`CIPHER_SIZE-1:0]       debug_pi [`DOUBLE_NTT_CORE-1:0];
wire debug_eo_signal_back;

// ---------------------------------------------------------------- CLK
always #HP clk = ~clk;


// ---------------------------------------------------------------- TXT data
reg [`CIPHER_SIZE-1:0] params    [0:1];
reg [`CIPHER_SIZE-1:0] w	 	 [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] wp	     [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] cin_a   [0:`RING_SIZE-1]; // actual size = RING_SIZE * LOG_RING_SIZE
reg [`CIPHER_SIZE-1:0] cin_b   [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] cout_a  [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] cout_b  [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] ntt_outa  [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] ntt_outb [0:`RING_SIZE-1];

reg [`CIPHER_SIZE-1:0] ntt_pin   [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] ntt_pout  [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] intt_pin  [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] intt_pout [0:`RING_SIZE-1];

reg [`CIPHER_SIZE-1:0] win;
reg [`CIPHER_SIZE-1:0] wpin;
reg [`CIPHER_SIZE-1:0] cina;
reg [`CIPHER_SIZE-1:0] cinb;
wire [`CIPHER_SIZE-1:0] couta;
wire [`CIPHER_SIZE-1:0] coutb;


initial begin
	// ntt
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/PARAM"    , params);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/TW"        , w);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/TW_PRIME"     , wp);

	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/NTT_INA"  , ntt_pin);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/NTT_OUTA" , ntt_pout);

	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/CINA"  , cin_a);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/CINB" , cin_b);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/COUTA"  , cout_a);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/COUTB" , cout_b);
//	$readmemh("C:/Users/cjl25/param_ntt/param_ntt.srcs/sources_1/imports/test_generator/INTT_DIN.txt" , intt_pin);
//	$readmemh("C:/Users/cjl25/param_ntt/param_ntt.srcs/sources_1/imports/test_generator/INTT_DOUT.txt", intt_pout);
end



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

// ---------------------------------------------------------------- LOAD TWIDDLE FACTORS
initial begin: LOAD_DATA
    load_w    = 0;
    load_data = 0;
    start     = 0;
    start_intt= 0;
    din       = 0;

    #300;

    // load w
    load_w = 1;
    #FP;
    load_w = 0;	

	// RING_SIZE * FP(10)
	for(k=0; k<`RING_SIZE; k=k+1) begin 
		din = w[k];
		#FP;
	end
    
	for(k=0; k<`RING_SIZE; k=k+1) begin
		din = wp[k];
		#FP;
	end

	din = params[1]; // q
	#FP;
	// din = params[6];
	// #FP;

	#(5*FP);

	// ---------- load data (ntt)
	load_data = 1;
    #FP;
    load_data = 0;

	for(k=0; k<(`RING_SIZE); k=k+1) begin
		din = ntt_pin[k];
		#FP;
	end

	#(5*FP);

	// start (ntt)
	start = 1;
	#FP;
	start = 0;
	#FP;

	while(done == 0)
		#FP;
	#FP;

	#(FP*(`RING_SIZE+10));

end

// ---------------------------------------------------------------- TEST control

reg [`CIPHER_SIZE-1:0] ntt_nout  [0:`RING_SIZE-1];
reg [`CIPHER_SIZE-1:0] intt_nout [0:`RING_SIZE-1];

integer m;
integer en,ei;

initial begin: CHECK_RESULT
	en = 0;
	ei = 0;
    #1500;

	// wait result (ntt)
	while(done == 0)
		#FP;
	#FP;

	// Store output (ntt)
	for(m=0; m<(`RING_SIZE); m=m+1) begin
		ntt_nout[m] = dout;
		#FP;
	end

	#FP;
	
	// Compare output with expected result (ntt)
	for(m=0; m<(`RING_SIZE); m=m+1) begin
		if(ntt_nout[m] == ntt_pout[m]) begin // compare here
			en = en+1;
		end
		else begin
		    $display("NTT:  Index-%d -- Calculated:%d, Expected:%d", m, ntt_nout[m], ntt_pout[m]);
		end
	end
	#FP;

	if(en == (`RING_SIZE))
		$display("NTT:  Correct");
	else
		$display("NTT:  Incorrect");


	$stop();
end


NTT ntt    (clk,reset,
             load_w,
             load_data,
             start,
             start_intt,
             din,
             done,
			 dout,

debug_raddr,
debug_waddr,
debug_raddr_tw,
debug_me_sela,
debug_me_selb,
debug_tw_sel,
debug_core_in_a ,
debug_core_in_b ,
debug_core_w,
debug_core_wp,
debug_core_out_a,
debug_core_out_b,
debug_MEe,
debug_MEo,
debug_MEs,
debug_MEe_back,
debug_MEo_back,
debug_MEs_back,
debug_pi,
debug_eo_signal_back		 
			 );

endmodule

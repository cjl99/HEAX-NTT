`include "defines.v"

`define SIZENOW (( `RING_SIZE) >> 1)

module intttest();


parameter HP = 5;
parameter FP = (2*HP);

reg                       clk,reset;
/// --------------------------------------------------------------- DEBUG
wire [`CIPHER_SIZE-1:0] debug_outa;
wire [`CIPHER_SIZE-1:0] debug_temp1;
wire [`CIPHER_SIZE-2:0] debug_temp3;
wire [`CIPHER_SIZE:0] debug_temp5;




// ---------------------------------------------------------------- CLK
always #HP clk = ~clk;


// ---------------------------------------------------------------- TXT data
reg [`CIPHER_SIZE-1:0] params    [0:1];
reg [`CIPHER_SIZE-1:0] w	 	 [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] wp	     [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] cin_a   [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] cin_b   [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] cout_a  [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] cout_b  [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] ntt_outa  [0:`SIZENOW-1];
reg [`CIPHER_SIZE-1:0] ntt_outb [0:`SIZENOW-1];

reg [`CIPHER_SIZE-1:0] win;
reg [`CIPHER_SIZE-1:0] wpin;
reg [`CIPHER_SIZE-1:0] cina;
reg [`CIPHER_SIZE-1:0] cinb;
wire [`CIPHER_SIZE-1:0] couta;
wire [`CIPHER_SIZE-1:0] coutb;

reg [15:0] en;

initial begin
	// ntt
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/PARAM"    , params);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/INTT_W"        , w);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/INTT_WP"     , wp);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/INTT_INA"  , cin_a);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/INTT_INB" , cin_b);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/INTT_OUTA"  , cout_a);
	$readmemh("C:/Users/cjl25/Desktop/ParamsGenerator/data/INTT_OUTB" , cout_b);
end

// ---------------------------------------------------------------- TEST case
integer i;
integer m;
initial begin: CLK_RESET_INIT
	clk       = 0;
	reset     = 0;

	#100;
	reset    = 1;
	#100;
	reset    = 0;
	en = 0;
	#100;

	// Store output (ntt)
	for(i=0; i<(`SIZENOW); i=i+1) begin
		cina = cin_a[i];
		cinb = cin_b[i];
		win = w[i];
		wpin = wp[i];
		if(i!=0) begin
			ntt_outa[i-1] = couta;
			ntt_outb[i-1] = coutb;
		end
		#FP;
	end

	#FP;
	ntt_outa[i-1] = couta;
	ntt_outb[i-1] = coutb;
	
	// Compare output with expected result (ntt)
	for(i=0; i<(`SIZENOW); i=i+1) begin
		if(ntt_outa[i] == cout_a[i]) begin // compare here
			en = en+1;
		end
		else begin
		    $display("NTT:  Index-%d -- Calculated:%d, Expected:%d",m,ntt_outa[i],cout_a[i]);
		end
	end
	#FP;
	if(en == (`SIZENOW))
		$display("NTTa:  Correct");
	else
		$display("NTTa:  Incorrect");

	
	en = 0;
	#FP;

	for(m=0; m<(`SIZENOW); m=m+1) begin
		if(ntt_outb[m] == cout_b[m]) begin // compare here
			en = en+1;
		end
		else begin
		    $display("NTT:  Index-%d -- Calculated:%d, Expected:%d",m,ntt_outb[m],cout_b[m]);
		end
	end
	#FP;

	if(en == (`SIZENOW))
		$display("NTTb:  Correct");
	else
		$display("NTTb:  Incorrect");


	$stop();
end


inttcore co(
	.clk(clk),
	.reset(reset),
	.cin_a(cina),
    .cin_b(cinb),
    .w(win),
    .wp(wpin),
    .q(params[1]),

.debug_outa(debug_outa),
.debug_temp1(debug_temp1),
.debug_temp3(debug_temp3),
.debug_temp5(debug_temp5),

    .cout_a(couta),
    .cout_b(coutb)
);
    
endmodule

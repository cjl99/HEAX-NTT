/*
* @Author: jialiang.chen 
* @Date: 2022-04-19 18:59:51 
 * @Last Modified by: jialiang.chen
 * @Last Modified time: 2022-04-22 16:10:15
*/

`include "defines.v"

module NTT (
        input                           clk,
        input                           reset,
        input                           load_w,
        input                           load_data,
        input                           start,
        input                           start_intt,
        input [`CIPHER_SIZE-1:0]        din,
        output reg                      done,
        output reg [`CIPHER_SIZE-1:0]   dout,




output [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] debug_raddr,
output [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] debug_waddr,
output [`LOG_RING_SIZE-`LOG_NTT_CORE-1:0] debug_raddr_tw,
output reg [`LOG_NTT_CORE:0] debug_me_sela [`NTT_CORE-1:0],
output reg [`LOG_NTT_CORE:0] debug_me_selb [`NTT_CORE-1:0],
output reg [`LOG_NTT_CORE-1:0] debug_tw_sel [`NTT_CORE-1:0],

output reg [`CIPHER_SIZE-1:0]  debug_core_in_a   [`NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0]  debug_core_in_b   [`NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0]  debug_core_w     [`NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0]  debug_core_wp     [`NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0]  debug_core_out_a  [`NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0]  debug_core_out_b  [`NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0] debug_MEe [`DOUBLE_NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0] debug_MEo [`DOUBLE_NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0] debug_MEs [`DOUBLE_NTT_CORE-1:0],

output reg [`CIPHER_SIZE-1:0] debug_MEe_back [`DOUBLE_NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0] debug_MEo_back [`DOUBLE_NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0] debug_MEs_back [`DOUBLE_NTT_CORE-1:0],
output reg [`CIPHER_SIZE-1:0]       debug_pi [`DOUBLE_NTT_CORE-1:0],
output debug_eo_signal_back


       );

// parameters & control
// reg [2:0] state;
// reg [`LOG_RING_SIZE+2:0] sys_cntr;
reg [2:0] state;
reg [`LOG_RING_SIZE+2:0] sys_cntr;
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] addrout;
wire [`LOG_NTT_CORE:0] coefout;
            
reg [`LOG_NTT_CORE:0] me_sela [`NTT_CORE-1:0];
reg [`LOG_NTT_CORE:0] me_selb [`NTT_CORE-1:0];

wire [`LOG_NTT_CORE-1:0] tw_sel [`NTT_CORE-1:0];
wire [`LOG_NTT_CORE-1:0] tw_sel_late2 [`NTT_CORE-1:0];

reg [`CIPHER_SIZE-1:0] MEe [`DOUBLE_NTT_CORE-1:0];
reg [`CIPHER_SIZE-1:0] MEo [`DOUBLE_NTT_CORE-1:0];
reg [`CIPHER_SIZE-1:0] MEs [`DOUBLE_NTT_CORE-1:0];

reg [`CIPHER_SIZE-1:0] MEe_back [`DOUBLE_NTT_CORE-1:0];
reg [`CIPHER_SIZE-1:0] MEo_back [`DOUBLE_NTT_CORE-1:0];
reg [`CIPHER_SIZE-1:0] MEs_back [`DOUBLE_NTT_CORE-1:0];
reg [`LOG_NTT_CORE:0] me_sela_back [`NTT_CORE-1:0];
reg [`LOG_NTT_CORE:0] me_selb_back [`NTT_CORE-1:0];

// control signals
wire me_write_en_0, me_write_en, me_write_back;
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] raddr, waddr;
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-1:0] raddr_tw;
wire eo_signal, eo_signal_back;
wire type_signal; 
wire finished_0;
// reg [`LOG_NTT_CORE:0] me_sela [`NTT_CORE-1:0];


// brams (datain,dataout,waddr,raddr,wen)
reg [`CIPHER_SIZE-1:0]          pi [`DOUBLE_NTT_CORE-1:0];
wire[`CIPHER_SIZE-1:0]          po [`DOUBLE_NTT_CORE-1:0];
reg [`CIPHER_DRAM_DEPTH-1:0]    pw [`DOUBLE_NTT_CORE-1:0];
reg [`CIPHER_DRAM_DEPTH-1:0]    pr [`DOUBLE_NTT_CORE-1:0];
reg [0:0]                       pe [`DOUBLE_NTT_CORE-1:0];

// modulus q
reg [`CIPHER_SIZE-1:0] q;

// // twiddle factors (w)
reg [`CIPHER_SIZE-1:0]          ti [`NTT_CORE-1:0];
wire[`CIPHER_SIZE-1:0]          to [`NTT_CORE-1:0];
reg [`TWI_DRAM_DEPTH-1:0]       tw [`NTT_CORE-1:0];
reg [`TWI_DRAM_DEPTH-1:0]       tr [`NTT_CORE-1:0];
reg [0:0]                       te [`NTT_CORE-1:0];

// twiddle_prime factors (wp)
reg [`CIPHER_SIZE-1:0]          ti2 [`NTT_CORE-1:0];
wire[`CIPHER_SIZE-1:0]          to2 [`NTT_CORE-1:0];
reg [`TWI_DRAM_DEPTH-1:0]       tw2 [`NTT_CORE-1:0];
reg [`TWI_DRAM_DEPTH-1:0]       tr2 [`NTT_CORE-1:0];
reg [0:0]                       te2 [`NTT_CORE-1:0];

// ntt core in out data
reg [`CIPHER_SIZE-1:0]  core_in_a   [`NTT_CORE-1:0];
reg [`CIPHER_SIZE-1:0]  core_in_b   [`NTT_CORE-1:0];
// wire [`CIPHER_SIZE-1:0]  core_w_late1      [`NTT_CORE-1:0];
// wire [`CIPHER_SIZE-1:0]  core_wp_late1     [`NTT_CORE-1:0];
wire [`CIPHER_SIZE-1:0]  core_out_a  [`NTT_CORE-1:0];
wire [`CIPHER_SIZE-1:0]  core_out_b  [`NTT_CORE-1:0];

reg [`CIPHER_SIZE-1:0]  core_w      [`NTT_CORE-1:0];
reg [`CIPHER_SIZE-1:0]  core_wp     [`NTT_CORE-1:0];


// wire [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] addrout;
// wire [`LOG_NTT_CORE:0] coefout;
// wire [4:0]                       stage_count;
wire                             ntt_finished;
// reg                              ntt_intt; // ntt:0 -- intt:1

assign ntt_finished = finished_0;



// DEBUG DATA
always @(*) begin: DEBUG_ASSIGN
    integer i;
    for (i=0; i<`NTT_CORE; i=i+1) begin
        debug_core_in_a[i] <= core_in_a[i];
        debug_core_in_b[i] <= core_in_b[i];
        debug_core_w[i] <= core_w[i];
        debug_core_wp[i] <= core_wp[i];
        debug_core_out_a[i] <= core_out_a[i];
        debug_core_out_b[i] <= core_out_b[i];
        debug_MEe[i] <= MEe[i]; debug_MEe[i+`NTT_CORE] <= MEe[i+`NTT_CORE];
        debug_MEo[i] <= MEo[i]; debug_MEo[i+`NTT_CORE] <= MEo[i+`NTT_CORE];
        debug_MEs[i] <= MEs[i]; debug_MEs[i+`NTT_CORE] <= MEs[i+`NTT_CORE];
        debug_MEe_back[i] <= MEe_back[i]; 
        debug_MEe_back[i+`NTT_CORE] <= MEe_back[i+`NTT_CORE];
        debug_MEo_back[i] <= MEo_back[i]; 
        debug_MEo_back[i+`NTT_CORE] <= MEo_back[i+`NTT_CORE];
        debug_MEs_back[i] <= MEs_back[i]; 
        debug_MEs_back[i+`NTT_CORE] <= MEs_back[i+`NTT_CORE];        
        debug_pi <= pi;

        debug_me_sela[i] <= me_sela[i];
        debug_me_selb[i] <= me_selb[i];
        debug_tw_sel[i] <= tw_sel[i];
    end
end

assign debug_raddr = raddr;
assign debug_waddr = waddr;
assign debug_eo_signal_back = eo_signal_back;
assign debug_raddr_tw = raddr_tw;


// ------------------------------------------------------------------- Controller
Controller cu(
    .clk(clk),
    .reset(reset),
    .start(start | start_intt),
    .me_write_en(me_write_en_0),
    .raddr(raddr),
    .raddr_tw(raddr_tw),
    .eo_signal(eo_signal),
    .type_signal(type_signal),
    .finished(finished_0),
    .me_sela(me_sela),
    .me_selb(me_selb),
    .tw_sel(tw_sel)
);


ShiftReg #(.SHIFT(6), .DATA(`LOG_RING_SIZE-`LOG_NTT_CORE-1)) sr_r2w(clk, reset, raddr, waddr);
ShiftReg #(.SHIFT(6), .DATA(1)) sr_me_en_back(clk, reset, me_write_en_0, me_write_back);



// ---------------------------------------------------------------- BRAMs
// 2*PE BRAMs -- one for input, one for output polynomial 
// --------------------------------- output not finished yet
// PE BRAMs for storing twiddle factors (w)
// PE BRAMs for storing wp
 
generate
	genvar k;

   for(k=0; k<`DOUBLE_NTT_CORE; k=k+1) begin: BRAM_CIPHER_BLOCK
       BRAM #(.width(`CIPHER_SIZE), .len(`CIPHER_DRAM_DEPTH)) bd00(.clk(clk), .wen(pe[k]), .waddr(pw[k]), .din(pi[k]), .raddr(pr[k]), .dout(po[k]));
       // BRAM #(.width(`CIPHER_SIZE), .len(`DRAM_DEPTH)) bd01(.clk(clk), .wen(pe[2*k+0]), .waddr(pw[2*k+0]), .din(pi[2*k+0]), .raddr(pr[2*k+0]), .dout(po[2*k+0]));
   end

   for(k=0; k<`NTT_CORE; k=k+1) begin: BRAM_TWIDDLE_BLOCK
       BRAM #(.width(`CIPHER_SIZE), .len(`TWI_DRAM_DEPTH)) btw (.clk(clk), .wen(te[k]),  .waddr(tw[k]),  .din(ti[k]),  .raddr(tr[k]),  .dout(to[k]));
       BRAM #(.width(`CIPHER_SIZE), .len(`TWI_DRAM_DEPTH)) btw2(.clk(clk), .wen(te2[k]), .waddr(tw2[k]), .din(ti2[k]), .raddr(tr2[k]), .dout(to2[k]));
   end

endgenerate



// ---------------------------------------------------------------- Memory Elements

ShiftReg #(.SHIFT(1), .DATA(1)) sr_me_en(clk, reset, me_write_en_0, me_write_en);

always @(posedge clk or posedge reset) begin: MES_BLOCK
   integer n;
   for(n=0; n<`DOUBLE_NTT_CORE; n=n+1) begin
       if(reset) begin
           MEe[n] <= 0;
           MEo[n] <= 0;
           MEs[n] <= 0;
       end
       else begin
           if (me_write_en==1 ) begin
               MEe[n] <= po[n]; 
               MEo[n] <= eo_signal==0 ? po[n] : MEo[n];
               MEs[n] <= (eo_signal==0 || type_signal==1) ? MEe[n] : MEs[n]; // late 1 cc
           end
           else begin
               MEe[n] <= 0;
               MEo[n] <= (eo_signal==0) ? 0 : MEo[n];   
               MEs[n] <= (eo_signal==0 || type_signal==1) ? MEe[n] : MEs[n];
           end
       end
   end
end

always @(*) begin: CORE_INPUT_BLOCK
    integer i;
    for(i=0; i<`NTT_CORE; i=i+1) begin
        if(type_signal==0) begin
            core_in_a[i] <= eo_signal==1 ? MEs[i] : MEs[i + `NTT_CORE];
            core_in_b[i] <= eo_signal==1 ? MEo[i] : MEo[i + `NTT_CORE];
        end
        else begin
            // core_in_a[i] = eo_signal==1? MEs[me_sela[i]] : MEs[me_sela[i]];
            // core_in_b[i] = eo_signal==1? MEs[me_selb[i]] : MEs[me_selb[i]];

            core_in_a[i] <= MEs[me_sela[i]];
            core_in_b[i] <= MEs[me_selb[i]];
       end
    end
end

always @(posedge clk or posedge reset) begin: CORE_INPUTW_BLOCK
    integer i;
    
    for(i=0; i<`NTT_CORE; i=i+1) begin
        if (reset) begin
            core_w[i] <= 0;
            core_wp[i] <= 0;
        end
        else begin
            core_w[i] <= to[tw_sel_late2[i]];
            core_wp[i] <= to2[tw_sel_late2[i]];
        end

    end
end



// ---------------------------------------------------------------- NTT core
generate
	genvar m;

   for(m=0; m<`NTT_CORE; m=m+1) begin: NTT_CORE_BLOCK
       core nttcore(.clk(clk), .reset(reset), .cin_a(core_in_a[m]), .cin_b(core_in_b[m]), .w(core_w[m]), .wp(core_wp[m]), .q(q), .cout_a(core_out_a[m]), .cout_b(core_out_b[m]));
   end

    for(m=0; m<`NTT_CORE; m=m+1) begin: SHIFT_W_BLOCK
        // ShiftReg #(.SHIFT(1),.DATA(`CIPHER_SIZE)) sr01(clk,reset, core_w[m], core_w_late1[m]);
        // ShiftReg #(.SHIFT(1),.DATA(`CIPHER_SIZE)) sr02(clk,reset, core_wp[m], core_wp_late1[m]);
        ShiftReg #(.SHIFT(2),.DATA(`LOG_NTT_CORE)) sr_tw_sel(clk, reset, tw_sel[m], tw_sel_late2[m]);
    end

endgenerate





// ---------------------------------------------------------------- state control & sys_cntr
// 0: IDLE
// 1. load twiddle factors ( w & wp & q )
// 2. load ciphtertext
// 3. do ntt
// 4. output data


// 1: load twiddle factors + q + n_inv
// 2: load data
// 3: performs ntt
// 4: output data
// 5: last stage of intt
always @(posedge clk or posedge reset) begin
   if(reset) begin
       state <= 3'd0;
       sys_cntr <= 0;
   end
   else begin
       case(state)
       3'd0: begin
           if(load_w)
               state <= 3'd1;
           else if(load_data)
               state <= 3'd2;
           else if(start | start_intt)
               state <= 3'd3;
           else
               state <= 3'd0;
           sys_cntr <= 0;
       end
       3'd1: begin
           // size(w) = n, size(wp) = n, size(q) = 1
           if(sys_cntr == (`DOUBLE_RING_SIZE + 1)) begin // change state at last
               state <= 3'd0;
               sys_cntr <= 0;
           end
           else begin
               state <= 3'd1;
               sys_cntr <= sys_cntr + 1;
           end
       end
       3'd2: begin
           if(sys_cntr == (`RING_SIZE)) begin
               state <= 3'd0;
               sys_cntr <= 0;
           end
           else begin
               state <= 3'd2;
               sys_cntr <= sys_cntr + 1;
           end
       end
       3'd3: begin
           if(ntt_finished) 
               state <= 3'd4;
           // if(ntt_finished && (ntt_intt == 0))
           //     state <= 3'd4;
           // else if(ntt_finished && (ntt_intt == 1))
           //     state <= 3'd5;
           else
               state <= 3'd3;
           sys_cntr <= 0;
       end
       3'd4: begin
           if(sys_cntr == (`RING_SIZE+1)) begin    // output data
               state <= 3'd0;
               sys_cntr <= 0;
           end
           else begin
               state <= 3'd4;
               sys_cntr <= sys_cntr + 1;
           end
       end
       // 3'd5: begin
       //     if(sys_cntr == (((`RING_SIZE >> (`PE_DEPTH+1))<<1) + `INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY)) begin
       //         state <= 3'd4;
       //         sys_cntr <= 0;
       //     end
       //     else begin
       //         state <= 3'd5;
       //         sys_cntr <= sys_cntr + 1;
       //     end
       // end
       default: begin
           state <= 3'd0;
           sys_cntr <= 0;
       end
       endcase
   end
end


// ---------------------------------------------------------------- twiddle factor w and wp and q
// `DOUBLE_RING_SIZE cc to load data & one cc to load q
always @(posedge clk or posedge reset) begin: TWIDDLE_W_BLOCK
   integer n;
   for(n=0; n < (`NTT_CORE); n=n+1) begin: LOOP_1
       if(reset) begin
           te[n] <= 0;     
           tw[n] <= 0;     
           ti[n] <= 0;     
           tr[n] <= 0;
       end
       else begin  // load w&wp state
           if(state==3'd1) begin
               if(sys_cntr < `RING_SIZE) begin
                   te[n] <= (n == (sys_cntr & ((1 << `LOG_NTT_CORE)-1))) ? 1'b1 : 0;
                   tw[n] <= (sys_cntr >> `LOG_NTT_CORE);    // write addr
                   tr[n] <= 0;
                   ti[n] <= din;
               end
           end
           else if(state==3'd3) begin
               te[n] <= 0;
               tw[n] <= 0;
               ti[n] <= 0;
               tr[n] <= raddr_tw;
           end
           else begin
               te[n] <= 0;    
               tw[n] <= 0;    
               ti[n] <= 0;    
               tr[n] <= 0;
           end
       end
   end
end

always @(posedge clk or posedge reset) begin: TWIDDLE_WP_BLOCK
   integer n;
   for(n=0; n < (`NTT_CORE); n=n+1) begin: LOOP_1
       if(reset) begin
           te2[n] <= 0;    
           tw2[n] <= 0;    
           ti2[n] <= 0;    
           tr2[n] <= 0;
       end
       else begin  // load w&wp state
           if(state==3'd1) begin
               if(sys_cntr>=`RING_SIZE && sys_cntr < `DOUBLE_RING_SIZE) begin
                   te2[n] <= (n == (sys_cntr & ((1 << `LOG_NTT_CORE)-1))) ? 1'b1 : 0;
                   tw2[n] <= (sys_cntr >> `LOG_NTT_CORE);    // write addr
                   tr2[n] <= 0;
                   ti2[n] <= din;
               end
           end
           else if(state==3'd3) begin
               te2[n] <= 0;
               tw2[n] <= 0;
               ti2[n] <= 0;
               tr2[n] <= raddr_tw;
           end
           else begin
               te2[n] <= 0;    
               tw2[n] <= 0;    
               ti2[n] <= 0;    
               tr2[n] <= 0;
           end
       end
   end
end

always @(posedge clk or posedge reset) begin // q
   if(reset) begin
       q <= 0;
   end
   else begin
       q <= (state == 3'd1) && (sys_cntr == `DOUBLE_RING_SIZE) ? din : q;
   end
end

// ---------------------------------------------------------------- load data & other data operations

assign addrout = ((sys_cntr-1) >> (`LOG_NTT_CORE+1));

always @(posedge clk or posedge reset) begin: DT_BLOCK
   integer n;
   for(n=0; n < (`DOUBLE_NTT_CORE); n=n+1) begin: LOOP_1
       if(reset) begin
           pe[n] <= 0; 
           pw[n] <= 0; 
        //    pi[n] <= 0; 
        //    pr[n] <= 0;
       end
       else begin
           if((state == 3'd2)) begin // input data
               if(sys_cntr < `RING_SIZE) begin
                   pe[n] <= (n == (sys_cntr & ((1 << (`LOG_NTT_CORE+1))-1))) ? 1'b1 : 0;
                   pw[n] <= (sys_cntr >> (`LOG_NTT_CORE+1));
                   pi[n] <= din;
                //    pr[n] <= 0;
               end
           end
           else if(state == 3'd3) begin // NTT operations 
                pe[n] <= me_write_back;
                pw[n] <= waddr;
                if (type_signal == 0) begin
                    pi[n] <= eo_signal_back==0 ? MEe_back[n] : MEs_back[n];
                end
                else begin
                    pi[n] <= MEs_back[n];
                end
            //    pr[n] <= raddr;
           end
           else if(state == 3'd4) begin
               pe[n] <= 0;
               pw[n] <= 0;
               pi[n] <= 0;
            //    pr[n] <= addrout;
           end
           else begin
               pe[n] <= 0; 
               pw[n] <= 0; 
               pi[n] <= 0; 
            //    pr[n] <= 0;
           end
       end
   end
end

always @(*) begin: PR_ADDR_ASSIGN
    integer i;
    for(i=0; i<`DOUBLE_NTT_CORE; i=i+1) begin
        if(reset) pr[i] = 0;
        else begin
            if(state==3'd3) pr[i] = raddr;
            else if(state==3'd4) pr[i] = addrout;
            else pr[i] = 0;
        end
    end
end

generate
    for (k=0; k<`NTT_CORE; k=k+1) begin
        ShiftReg #(.SHIFT(2), .DATA(`LOG_NTT_CORE + 1)) sr_me_sela_late2(clk, reset, me_sela[k], me_sela_back[k]);
        ShiftReg #(.SHIFT(2), .DATA(`LOG_NTT_CORE + 1)) sr_me_selb_late2(clk, reset, me_selb[k], me_selb_back[k]);
    end

endgenerate

ShiftReg #(.SHIFT(2), .DATA(1)) sr_eo_signal(clk, reset, eo_signal, eo_signal_back);

always @(posedge clk or posedge reset) begin: ME_BACK_BLOCK
   integer n;
   for(n=0; n<`NTT_CORE; n=n+1) begin
       if(reset) begin
           MEe_back[n] <= 0; MEe_back[n+`NTT_CORE] <=0;
           MEo_back[n] <= 0; MEo_back[n+`NTT_CORE] <=0;
           MEs_back[n] <= 0; MEs_back[n+`NTT_CORE] <=0;
       end
       else begin
            if (type_signal==0) begin
                if (eo_signal_back==0) begin
                    MEe_back[n] <= core_out_a[n]; 
                    MEo_back[n] <= core_out_b[n];
                    MEs_back[n] <= MEo_back[n];
                    MEs_back[n+`NTT_CORE] <= MEo_back[n+`NTT_CORE];
                end
                else begin
                    MEe_back[n+`NTT_CORE] <= core_out_a[n]; 
                    MEo_back[n+`NTT_CORE] <= core_out_b[n];
                    // other don't change
                end
            end
            else begin
                MEe_back[n] <= 0;
                MEe_back[n+`NTT_CORE] <= 0;
                MEo_back[me_sela_back[n]] <= core_out_a[n]; // tricky part
                MEo_back[me_selb_back[n]] <= core_out_b[n];
                MEs_back[n] <= MEo_back[n];
                MEs_back[n+`NTT_CORE] <= MEo_back[n+`NTT_CORE];
            end

            // else begin
            //     // MEe_back[n] <= 0;
            //     // MEo_back[n] <= (eo_signal==0) ? 0 : MEo_back[n];   
            //     // MEs_back[n] <= (eo_signal==0 || type_signal==1) ? MEe[n] : MEs[n];
            // end
       end
   end
end



// done signal & output data
assign coefout = (sys_cntr-2);

always @(posedge clk or posedge reset) begin
   if(reset) begin
       done <= 0;
       dout <= 0;
   end
   else begin
       if(state == 3'd4) begin
           done <= (sys_cntr == 1) ? 1 : 0;
           dout <= po[coefout];
       end
       else begin
           done <= 0;
           dout <= 0;
       end
   end
end


endmodule

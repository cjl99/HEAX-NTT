/*
Copyright 2020, Ahmet Can Mert <ahmetcanmert@sabanciuniv.edu>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

`include "defines.v"

module Controller (
    input clk, reset,
    input start,

    output reg me_write_en,
    output reg [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] raddr,
    output reg [`LOG_RING_SIZE-`LOG_NTT_CORE-1:0] raddr_tw,
    output reg eo_signal,
    output type_signal,
    output reg finished,
    output reg [`LOG_NTT_CORE:0] me_sela [`NTT_CORE-1:0],
    output reg [`LOG_NTT_CORE:0] me_selb [`NTT_CORE-1:0],
    output reg [`LOG_NTT_CORE-1:0] tw_sel [`NTT_CORE-1:0]
    // debug data -- which are not necessary for output
    );


reg [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0]   c_loop;
reg [4:0] c_stage;

// ---------------------------------------------------------------------------
// Control signals
// stage & loop's in each stage
reg [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0]   c_loop_limit; // RING_SIZE/(2*nttcore)
reg [4:0] c_stage_limit; // max{LOG_RING_SIZE} = 63

// reg [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0]   c_loop;    
// reg [4:0] c_stage;

reg [8:0] c_wait_limit;
reg [8:0] c_wait;

// loop even=0 odd=1

always @(posedge clk or posedge reset) begin // eo_signal late 1 cc
    if(c_loop==0) begin
        eo_signal <= 0;
    end
    else begin
        eo_signal <= ~eo_signal;
    end
    // eo_signal <= c_loop[0];
end

assign type_signal = (c_stage < (`LOG_RING_SIZE-`LOG_NTT_CORE-1)) ? 0 : 1;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        c_stage_limit <= 0;
        c_loop_limit  <= 0;
        c_wait_limit <= 0;
    end
    else begin
        if(start) begin
            c_stage_limit <= (`LOG_RING_SIZE-1);
            c_loop_limit  <= ((`RING_SIZE >> (`LOG_NTT_CORE+1))-1);
            c_wait_limit <=  8'd15;
        end
        else begin
            c_stage_limit <= c_stage_limit;
            c_loop_limit  <= c_loop_limit;
            c_wait_limit <= c_wait_limit;
        end
    end
end


// --------------------------------------------------------------------------- STATE
reg [1:0] state;
// 0 --> IDLE
// 1 --> NTT 
// 2 --> NTT (WAIT between stages --  more x cc for writing back)

always @(posedge clk or posedge reset) begin
    if(reset)
        state <= 0;
    else begin
        case(state)
        2'd0: begin
            state <= (start) ? 2'd1 : 0;
        end
        2'd1: begin
            state <= (c_loop == c_loop_limit) ? 2'd2 : 2'd1;
        end
        2'd2: begin
            if((c_stage == c_stage_limit) && (c_wait == c_wait_limit)) // operation is finished
                state <= 0;
            else if(c_wait == c_wait_limit)                            // to next NTT stage
                state <= 1;
            else                                                       // wait
                state <= 2;
        end
        default: state <= 0;
        endcase
    end
end

// --------------------------------------------------------------------------- WAIT OPERATION
always @(posedge clk or posedge reset) begin
    if(reset) begin
        c_wait       <= 0;
    end
    else begin
        if(state == 2'd2)
            c_wait <= (c_wait < c_wait_limit) ? (c_wait + 1) : 0;
        else
            c_wait <= 0;
    end
end


// --------------------------------------------------------------------------- STAGE OPERATION
always @(posedge clk or posedge reset) begin
    if(reset) begin
        c_stage       <= 0;
        c_loop        <= 0;
    end
    else begin
        if(start) begin
            c_stage <= 0;
            c_loop  <= 0;
        end
        else begin
            // ---------------------------- c_stage
            if((state == 2'd2) && (c_wait == c_wait_limit) && (c_stage == c_stage_limit))   // change at end of loop
                c_stage <= 0;   
            else if((state == 2'd2) && (c_wait == c_wait_limit))    
                c_stage <= c_stage + 1; // go to next stage
            else
                c_stage <= c_stage;
            // ---------------------------- c_loop
            if((state == 2'd2) && (c_wait == c_wait_limit))
                c_loop <= 0;    // wait for write
            else if((state == 2'd1) && (c_loop < c_loop_limit))
                c_loop <= c_loop + 1;   // next step
            else
                c_loop <= c_loop;
        end
    end
end


// --------------------------------------------------------------------------- raddr no late
wire [`LOG_RING_SIZE-`LOG_NTT_CORE-2:0] raddr_temp;
assign raddr_temp = ((`LOG_RING_SIZE-`LOG_NTT_CORE-1) - (c_stage+1));

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        raddr <= 0;
        me_write_en <= 0;
    end
    else begin
        if(start) begin
            raddr <= 0;
            me_write_en <= 0;
        end
        else begin
            if((state == 2'd2) && (c_wait == c_wait_limit)) begin   
                raddr <= 0;
            end
            else if((state == 2'd1) && (c_loop <= c_loop_limit)) begin
                if(c_stage < (`LOG_RING_SIZE-`LOG_NTT_CORE-1)) begin
                    if(~c_loop[0])  // last bit is 0
                        raddr <= (c_loop >> 1) + ((c_loop >> (raddr_temp+1)) << raddr_temp);
                    else    // last bit is 1
                        raddr <= (1 << raddr_temp) + (c_loop >> 1) + ((c_loop >> (raddr_temp+1)) << raddr_temp);
                end
                else
                    raddr <= c_loop;    // direct order
            end
            else begin
                raddr <= raddr;
            end

            if ((state == 2'd1) && (c_loop <= c_loop_limit)) 
                me_write_en <= 1;
            else 
                me_write_en <= 0;
        end
    end
end

// --------------------------------------------------------------------------- raddr_tw late 1 cc


always @(posedge clk or posedge reset) begin
    if(reset) begin
        raddr_tw <= 0;
    end
    else begin
        if((state == 2'd2) && (c_wait == c_wait_limit)) begin   
            raddr_tw <= 0; 
        end
        else if((state == 2'd1) && (c_loop <= c_loop_limit)) begin
            if(c_stage < `LOG_NTT_CORE) begin
                raddr_tw <= 0;
            end
            else if(c_stage == `LOG_NTT_CORE) begin
                raddr_tw <= 1;
            end
            else if (c_stage <= (`LOG_RING_SIZE - `LOG_NTT_CORE - 1)) begin
                raddr_tw <= ((1<<c_stage) + (c_loop >> (`LOG_RING_SIZE-`LOG_NTT_CORE-1-c_stage))) >> `LOG_NTT_CORE;
            end
            else begin
                raddr_tw <= ((1<<c_stage) + (c_loop << (c_stage + `LOG_NTT_CORE +1 - `LOG_RING_SIZE))) >> `LOG_NTT_CORE;
            end
        end
        else begin
            raddr_tw <= raddr_tw;
        end
    end
end


// ---------------------------------------------------------------------------  me select signal late 1 cc
wire [`LOG_NTT_CORE:0] me_temp;
wire [`LOG_NTT_CORE-1:0] me_temp2;
assign me_temp = (c_stage - (`LOG_RING_SIZE-`LOG_NTT_CORE-1));
assign me_temp2 = `NTT_CORE >> me_temp;

wire [`LOG_NTT_CORE:0] b_temp [`NTT_CORE-1:0];

always @(posedge clk or posedge reset) begin: SEL_BLOCK     
    integer n;
    for(n=0; n<`NTT_CORE; n=n+1) begin
        if(reset) begin
            me_sela[n] <= 0;
            me_selb[n] <= 0;
        end
        else begin
            if(c_stage < (`LOG_RING_SIZE-`LOG_NTT_CORE-1)) begin  // not use this signal
                me_sela[n] <= 0;
                me_selb[n] <= 0;
            end
            else if (c_stage ==(`LOG_RING_SIZE-`LOG_NTT_CORE-1) ) begin
                me_sela[n] <= n;
                me_selb[n] <= n+`NTT_CORE;
            end
            else begin // last lognttcore+1 stage
                if (c_loop==0) begin
                    if ((n & me_temp2) == 0 ) begin
                        me_selb[n] <= me_sela[n+me_temp2];
                        me_sela[n+me_temp2] <= me_selb[n];
                    end
                end
                else begin
                    me_sela[n] <= me_sela[n];
                    me_selb[n] <= me_selb[n];
                end
                // unchanged else
            end
        end

    end
end


// ---------------------------------------------------------------------------  raddr_tw select signal late 1 cc
wire [`LOG_RING_SIZE-1:0] tw_begin;
wire [`LOG_NTT_CORE-1:0] tw_tttt;
assign tw_tttt = c_loop << (c_stage + `LOG_NTT_CORE +1 - `LOG_RING_SIZE );
assign tw_begin = 1<<c_stage;

always @(posedge clk or posedge reset) begin: TWSELEACT_BLOCK
    integer i;
    for(i=0; i<`NTT_CORE; i=i+1) begin
        if(reset) begin
            tw_sel[i] <= 0;
        end
        else begin
            if(c_stage <= `LOG_RING_SIZE-`LOG_NTT_CORE-1) begin
                tw_sel[i] <= (tw_begin[`LOG_NTT_CORE-1:0]) + (c_loop >> (`LOG_RING_SIZE-`LOG_NTT_CORE-1-c_stage));  // same selection = last `LOG_NTTCORE bit of tw_begin
            end
            // else if (c_stage <=( (`LOG_NTT_CORE<<1) ) ) begin
            else begin
                tw_sel[i] <= tw_tttt[`LOG_NTT_CORE-1:0] +  (i >> (`LOG_RING_SIZE - c_stage -1) );
            end
            // else begin
            //     tw_sel[i] <= i;
            // end
        end
    end
end

// --------------------------------------------------------------------------- write signal 



// --------------------------------------------------------------------------- ntt_finished

always @(posedge clk or posedge reset) begin
    if(reset) begin
        finished <= 0;
    end
    else begin
        if((state == 2'd2) && (c_wait == c_wait_limit) && (c_stage == c_stage_limit))
            finished <= 1;
        else
            finished <= 0;
    end
end






//ShiftReg #(.SHIFT(4),.DATA(1)) sr11(clk,reset,finished,finished_w);

endmodule
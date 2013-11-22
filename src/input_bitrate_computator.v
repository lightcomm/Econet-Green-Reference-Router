///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: module_template 2008-03-13 gac1 $
//
// Module: input_bitrate_computator.v
// Project: NF2.1
// Description: defines a module for the user data path that computate input bitrate.
//    Bitrate_computator module uses 6 registers. The first is a software register 
//	and it specifies sampling period. 
//	Instead other five registers contains bitrate computation for each of the four queue 
//	and the total bitrate calculated as the sum of the previous four.
//
///////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2013 Lightcomm s.r.l.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module input_bitrate_computator 
	#(
	parameter DATA_WIDTH = 64,
      	parameter CTRL_WIDTH = DATA_WIDTH/8,
        parameter UDP_REG_SRC_WIDTH = 2,
	parameter INPUT_ARBITER_STAGE_NUM = 2,
	parameter NUM_OUTPUT_QUEUES = 8,
	parameter STAGE_NUM = 5,
	parameter NUM_IQ_BITS = 3
	)
	(
		// --- data path interface
	 	output reg [DATA_WIDTH-1:0]        out_data,
     	 	output reg [CTRL_WIDTH-1:0]        out_ctrl,
     	 	output reg                         out_wr,
     		input                              out_rdy,

     		input  [DATA_WIDTH-1:0]            in_data,
     		input  [CTRL_WIDTH-1:0]            in_ctrl,
     		input                              in_wr,
     		output                             in_rdy,

      		// --- Register interface
      		input                              reg_req_in,
      		input                              reg_ack_in,
      		input                              reg_rd_wr_L_in,
      		input  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_in,
      		input  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_in,
      		input  [UDP_REG_SRC_WIDTH-1:0]     reg_src_in,

      		output                             reg_req_out,
      		output                             reg_ack_out,
      		output                             reg_rd_wr_L_out,
      		output  [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_out,
      		output  [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_out,
      		output  [UDP_REG_SRC_WIDTH-1:0]    reg_src_out,

		// Input Signals - Bytes pushed to User Data Path from MAC queues
		input [31:0]		q0_num_bytes_pushed,
		input [31:0]		q1_num_bytes_pushed,
		input [31:0]		q2_num_bytes_pushed,
		input [31:0]		q3_num_bytes_pushed,

		// misc
      		input                                reset,
      		input                                clk
	);
	`LOG2_FUNC


	wire  					reg_req_internal;
        wire  					reg_ack_internal;
        wire 					reg_rd_wr_L_itnernal;
        wire [`UDP_REG_ADDR_WIDTH-1:0]		reg_addr_internal;
        wire [`CPCI_NF2_DATA_WIDTH-1:0 ]	reg_data_internal;
        wire [UDP_REG_SRC_WIDTH-1:0]		reg_src_internal;


	// Wires used for maintain values of registers
	wire [31:0]   q0_bitrate;
	wire [31:0]   q1_bitrate;
	wire [31:0]   q2_bitrate;
	wire [31:0]   q3_bitrate;
	wire [31:0]   total_bitrate;
	wire [31:0]   cycle;


	reg   ewma_in_ready, ewma_in_ready_next;    // = 1 if data to be provided to ewma is ready


        //Input data from previous module
	fallthrough_small_fifo #(.WIDTH(DATA_WIDTH+CTRL_WIDTH), .MAX_DEPTH_BITS(2))
		input_fifo
	        	(.din ({in_ctrl,in_data}),     // Data in
	        	 .wr_en (in_wr),               // Write enable
	        	 .rd_en (in_fifo_rd_en),       // Read the next word 
	        	 .dout ({in_fifo_ctrl_dout, in_fifo_data_dout}),
	        	 .full (),
	        	 .nearly_full (in_fifo_nearly_full),
	        	 .empty (in_fifo_empty),
	        	 .reset (reset),
	        	 .clk (clk)
	        	 );




	// Module used in order to access to Bitrate Computator registers described in /include/input_bitrate_computator.xml
	generic_regs
	#(
		.UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
		.TAG                 (`INPUT_BITRATE_COMPUTATOR_BLOCK_ADDR),
		.REG_ADDR_WIDTH      (`INPUT_BITRATE_COMPUTATOR_REG_ADDR_WIDTH),
		.NUM_COUNTERS        (0),                 // Number of counters
		.NUM_SOFTWARE_REGS   (1),                 // Number of sw regs
		.NUM_HARDWARE_REGS   (5)                  // Number of hw regs
	) module_regs (
	       	.reg_req_in       (reg_req_in),
	       	.reg_ack_in       (reg_ack_in),
	       	.reg_rd_wr_L_in   (reg_rd_wr_L_in),
	       	.reg_addr_in      (reg_addr_in),
	       	.reg_data_in      (reg_data_in),
	       	.reg_src_in       (reg_src_in),

                .reg_req_out      (reg_req_internal),
                .reg_ack_out      (reg_ack_internal),
                .reg_rd_wr_L_out  (reg_rd_wr_L_internal),
	        .reg_addr_out     (reg_addr_internal),
	        .reg_data_out     (reg_data_internal),
	        .reg_src_out      (reg_src_internal),
	        // --- counters interface
	        .counter_updates  (),
                .counter_decrement(),
	
		.hardware_regs    ({total_bitrate, q3_bitrate, q2_bitrate, q1_bitrate, q0_bitrate}),
                .software_regs    ({cycle}), 
		
		.clk              (clk),
	        .reset            (reset)
	);



	// Definition of an instance of Bitrate Ewma
 	bitrate_ewma
	    bitrate_ewma (
		.total_bitrate_in  (total_bitrate),
 		 .data_ready (ewma_in_ready),
 
                 .reg_req_in (reg_req_internal),
                 .reg_ack_in (reg_ack_internal),
                 .reg_rd_wr_L_in (reg_rd_wr_L_internal), 
                 .reg_addr_in (reg_addr_internal),
                 .reg_data_in (reg_data_internal),
                 .reg_src_in (reg_src_internal),

                 .reg_req_out (reg_req_out),
                 .reg_ack_out (reg_ack_out),
                 .reg_rd_wr_L_out (reg_rd_wr_L_out),
                 .reg_addr_out (reg_addr_out),
                 .reg_data_out (reg_data_out),
                 .reg_src_out (reg_src_out),
                
                 .reset (reset),
                 .clk (clk)
	);


//--------------------- Internal Parameter-------------------------
        localparam NUM_STATES = 3;

	localparam STATE1    = 1;
	localparam STATE2    = 2;
	localparam STATE3    = 4;

	reg [31:0]  q0_last,q0_last_next;
	reg [31:0]  q1_last,q1_last_next;
	reg [31:0]  q2_last,q2_last_next;
	reg [31:0]  q3_last,q3_last_next;

	reg [31:0]  q0_value,q0_value_next;
	reg [31:0]  q1_value,q1_value_next;
	reg [31:0]  q2_value,q2_value_next;
	reg [31:0]  q3_value,q3_value_next;
	
	reg [19:0]  cnt,cnt_next;
	reg [31:0]  total_bitrate_reg, total_bitrate_reg_next;

	reg [NUM_STATES-1:0]   state,state_next;

	reg [19:0] check_cycle;
	reg [31:0] diff_cycle;

	assign q0_bitrate = q0_value;
	assign q1_bitrate = q1_value;
	assign q2_bitrate = q2_value;
	assign q3_bitrate = q3_value;
	assign total_bitrate = total_bitrate_reg;
	
//	assign in_rdy = !in_fifo_nearly_full;


	always @(*) begin       
		state_next = state;
		cnt_next = cnt;
		q0_last_next = q0_last;
		q1_last_next = q1_last;
		q2_last_next = q2_last;
		q3_last_next = q3_last;
		total_bitrate_reg_next = total_bitrate_reg;
		case(state)
			STATE1: begin
				cnt_next = cnt_next + 'h1;
				case(cycle)
					1: begin check_cycle = 'd9; diff_cycle = 'd100000000; end
					2: begin check_cycle = 'd99; diff_cycle = 'd10000000; end
					3: begin check_cycle = 'd999; diff_cycle = 'd1000000; end
					4: begin check_cycle = 'd9999; diff_cycle = 'd100000; end
					5: begin check_cycle = 'd99999; diff_cycle = 'd10000;  end
					default: begin check_cycle = 'd999999; diff_cycle = 'd1000; end
				endcase
				if(cnt>=check_cycle) begin
	        			q0_value_next = (q0_num_bytes_pushed - q0_last) * diff_cycle;
	        			q1_value_next = (q1_num_bytes_pushed - q1_last) * diff_cycle;
	        			q2_value_next = (q2_num_bytes_pushed - q2_last) * diff_cycle;
        				q3_value_next = (q3_num_bytes_pushed - q3_last) * diff_cycle;
					state_next = STATE2;
		 	   	end
			end
			STATE2: begin 
				cnt_next = 0;
				total_bitrate_reg_next = (q0_value  + q1_value + q2_value + q3_value);
				// Ready signal triggers ewma module in order to computate total bitrate with EWMA
				ewma_in_ready_next = 1;
				state_next = STATE3;
			end
			STATE3: begin
                                q0_last_next = q0_num_bytes_pushed;
      				q1_last_next = q1_num_bytes_pushed;
       				q2_last_next = q2_num_bytes_pushed;
        			q3_last_next = q3_num_bytes_pushed;
				state_next = STATE1;
			end
		endcase
	end

	always @(posedge clk) begin
		if(reset) begin
			cnt <= 0;
			state <= STATE1;
			q0_last <= 0;
			q1_last <= 0;
			q2_last <= 0;
			q3_last <= 0;
			q0_value <= 0;
			q1_value <= 0;
			q2_value <= 0;
			q3_value <= 0;
			total_bitrate_reg <= 0;
			ewma_in_ready <= 0;
		end
		else begin
			state <= state_next;
			cnt <= cnt_next;
			q0_last <= q0_last_next;
			q1_last <= q1_last_next;
			q2_last <= q2_last_next;
			q3_last <= q3_last_next;
			q0_value <= q0_value_next;
			q1_value <= q1_value_next;
			q2_value <= q2_value_next;
			q3_value <= q3_value_next;
			total_bitrate_reg <= total_bitrate_reg_next;
			ewma_in_ready <= ewma_in_ready_next;
		end
	end
endmodule


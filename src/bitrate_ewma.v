///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: module_template 2008-03-13 gac1 $
//
// Module: ewma.v
// Project: bitrate_ewma
// Description: defines a module that computate ewma bitrate
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



module bitrate_ewma
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
/*     		output reg [DATA_WIDTH-1:0]        out_data,
     		output reg [CTRL_WIDTH-1:0]        out_ctrl,
     		output reg                         out_wr,
     		input                              out_rdy,

     		input  [DATA_WIDTH-1:0]            in_data,
     		input  [CTRL_WIDTH-1:0]            in_ctrl,
     		input                              in_wr,
     		output                             in_rdy,
*/

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

		input 				   data_ready,
		input [31:0]			   total_bitrate_in,

		// misc
      		input                                reset,
      		input                                clk
	);
	`LOG2_FUNC

	wire [31:0]   ewma;
	wire [31:0]   alpha;


	/*
        //Input data from previous module
	fallthrough_small_fifo #(.WIDTH(DATA_WIDTH+CTRL_WIDTH), .MAX_DEPTH_BITS(2))
        	input_fifo (       
                        .din ({in_ctrl,in_data}),     // Data in
                	.wr_en (in_wr),               // Write enable
	        	.rd_en (in_fifo_rd_en),       // Read the next word 
	        	.dout ({in_fifo_ctrl_dout, in_fifo_data_dout}),
	        	.full (),
	        	.nearly_full (in_fifo_nearly_full),
	        	.empty (in_fifo_empty),
	        	.reset (reset),
	        	.clk (clk)
	        );
*/

	generic_regs
	#(
		.UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
		.TAG                 (`BITRATE_EWMA_BLOCK_ADDR), 
		.REG_ADDR_WIDTH      (`BITRATE_EWMA_REG_ADDR_WIDTH), 
		.NUM_COUNTERS        (0),                 // Number of counters
		.NUM_SOFTWARE_REGS   (1),                 // Number of sw regs
		.NUM_HARDWARE_REGS   (1)                  // Number of hw regs
	) module_regs (
	       	.reg_req_in       (reg_req_in),
	       	.reg_ack_in       (reg_ack_in),
	       	.reg_rd_wr_L_in   (reg_rd_wr_L_in),
	       	.reg_addr_in      (reg_addr_in),
	       	.reg_data_in      (reg_data_in),
	       	.reg_src_in       (reg_src_in),

                .reg_req_out      (reg_req_out),
                .reg_ack_out      (reg_ack_out),
                .reg_rd_wr_L_out  (reg_rd_wr_L_out),
	        .reg_addr_out     (reg_addr_out),
	        .reg_data_out     (reg_data_out),
	        .reg_src_out      (reg_src_out),
	        // --- counters interface
	        .counter_updates  (),
                .counter_decrement(),
	
		.hardware_regs    ({ewma}),
                .software_regs    ({alpha}),

		.clk              (clk),
	        .reset            (reset)
	);

	reg [31:0]  ewma_reg;
	reg [31:0]  ewma_prev;

	assign ewma = ewma_reg;
	
//	assign in_rdy = !in_fifo_nearly_full;

	always @(posedge clk) begin
		if(data_ready) begin
	                case(alpha)
        	                1: begin ewma_reg = (total_bitrate_in>>3)  + ((ewma_prev>>3)*7); end      // alpha= 0.125 
				2: begin ewma_reg = (total_bitrate_in>>2) + ((ewma_prev>>2)*3);  end      // alpha = 0.25 and (1-alpha)=0.75
                        	3: begin ewma_reg = ((total_bitrate_in>>3)*3) + ((ewma_prev>>3)*5); end     // alpha = 0.375 and (1-alpha)=0.625
				4: begin ewma_reg = (total_bitrate_in>>1) + ((ewma_prev)>>1); end         // alpha = 0.5 and (1-alpha)=0.5
				5: begin ewma_reg = ((total_bitrate_in>>3)*5) + ((ewma_prev>>3)*3); end    // alpha = 0.625 and (1-alpha)=0.375
	        	        6: begin ewma_reg = ((total_bitrate_in>>2)*3) + ((ewma_prev)>>2); end      // alpha = 0.75 and (1-alpha)=0.25
		        	7: begin ewma_reg = ((total_bitrate_in>>3)*7) + ((ewma_prev)>>3); end      // alpha = 0.875 and (1-alpha)=0.125
				default: begin ewma_reg = (total_bitrate_in); end                        // alpha = 1 and (1-alpha)=0
			endcase
                	ewma_prev = ewma_reg;
		end
        end

endmodule



`timescale 1ns / 1ps
`include "system.vh"

module ram #(
	     parameter ADDR_W = 12, // must be lower than ADDR_W-N_SLAVES_W
             parameter FILE = "none"
	     )
   (
    input                 clk,
    input                 rst,

    // intruction bus
    input                 i_valid,
    input [ADDR_W-1:0]    i_addr,
    input [`DATA_W-1:0]   i_wdata, //used for booting
    input [`DATA_W/8-1:0] i_wstrb,  //used for booting
    output [`DATA_W-1:0]  i_rdata,
    output reg            i_ready,

    // data bus
    input                 d_valid,
    input [ADDR_W-1:0]    d_addr,
    input [`DATA_W-1:0]   d_wdata,
    input [`DATA_W/8-1:0] d_wstrb,
    output [`DATA_W-1:0]  d_rdata,
    output reg            d_ready
    );

   parameter file_suffix = {"3","2","1","0"};
   //parameter file_suffix = "3210"

   genvar                 i;

   for (i = 0; i < 4; i = i+1) begin : gen_main_mem_byte
      iob_t2p_mem 
            #(
	      .MEM_INIT_FILE({FILE, "_", file_suffix[8*(i+1)-1 -: 8], ".dat"}),
	      .DATA_W(8),
              .ADDR_W(ADDR_W))
      main_mem_byte 
            (
	     .clk             (clk),
             //data 
	     .en_a            (d_valid),
	     .we_a            (d_wstrb[i]),
	     .addr_a          (d_addr),
	     .data_a          (d_wdata[8*(i+1)-1 -: 8]),
	     .q_a             (d_rdata[8*(i+1)-1 -: 8]),
             //instruction
	     .en_b            (i_valid),
	     .we_b            (i_wstrb[i]),
	     .addr_b          (i_addr),
	     .data_b          (i_wdata[8*(i+1)-1 -: 8]),
	     .q_b             (i_rdata[8*(i+1)-1 -: 8])
	     );	
     end

   // reply with ready 
   always @(posedge clk, posedge rst)
     if(rst) begin
	    d_ready <= 1'b0;
	    i_ready <= 1'b0;
     end else begin 
	    d_ready <= d_valid;
	    i_ready <= i_valid;
     end
endmodule

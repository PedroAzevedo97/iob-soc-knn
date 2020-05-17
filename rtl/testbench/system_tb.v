`timescale 1ns / 1ps

`include "system.vh"
`include "iob-uart.vh"
`include "console.vh"

`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2

module system_tb;

   //clock
   reg clk = 1;
   always #5 clk = ~clk;

   //reset 
   reg reset = 1;

   //received by getchar
   reg [7:0] cpu_char = 0;
   
   integer   i;
   
   //
   // TEST PROCEDURE
   //
   initial begin

`ifdef VCD
      $dumpfile("system.vcd");
      $dumpvars();
`endif

      //init cpu bus signals
      uart_valid = 0;
      uart_wstrb = 0;
      
      // deassert rst
      repeat (100) @(posedge clk);
      reset <= 0;

      //sync up with reset 
      repeat (100) @(posedge clk) #1;

      //
      // CONFIGURE UART
      //
      cpu_inituart();
      
      do begin
         cpu_getchar(cpu_char);
         
         if (cpu_char == `STX) begin // Send file
            cpu_sendFile();
         end else if (cpu_char == `SRX) begin // Receive file
            $write("File will be written to out.bin\n");
            cpu_receiveFile();
         end else if (cpu_char == `EOT) begin // Finish
            $write("Bye, bye!\n");
         end else begin
            $write("%c", cpu_char);
         end
      end while (cpu_char != `EOT);

   end // test procedure
   
   //
   // INSTANTIATE COMPONENTS
   //

   //DDR AXI interface signals 
`ifdef USE_DDR               
   //Write address
   wire [0:0] ddr_awid;
   wire [31:0] ddr_awaddr;
   wire [7:0]  ddr_awlen;
   wire [2:0]  ddr_awsize;
   wire [1:0]  ddr_awburst;
   wire        ddr_awlock;
   wire [3:0]  ddr_awcache;
   wire [2:0]  ddr_awprot;
   wire [3:0]  ddr_awqos;
   wire        ddr_awvalid;
   wire        ddr_awready;
   //Write data
   wire [31:0] ddr_wdata;
   wire [3:0]  ddr_wstrb;
   wire        ddr_wlast;
   wire        ddr_wvalid;
   wire        ddr_wready;
   //Write response
   wire [7:0]  ddr_bid;
   wire [1:0]  ddr_bresp;
   wire        ddr_bvalid;
   wire        ddr_bready;
   //Read address
   wire [0:0]  ddr_arid;
   wire [31:0] ddr_araddr;
   wire [7:0]  ddr_arlen;
   wire [2:0]  ddr_arsize;
   wire [1:0]  ddr_arburst;
   wire        ddr_arlock;
   wire [3:0]  ddr_arcache;
   wire [2:0]  ddr_arprot;
   wire [3:0]  ddr_arqos;
   wire        ddr_arvalid;
   wire        ddr_arready;
   //Read data
   wire [7:0]  ddr_rid;
   wire [31:0] ddr_rdata;
   wire [1:0]  ddr_rresp;
   wire        ddr_rlast;
   wire        ddr_rvalid;
   wire        ddr_rready;
`endif

   //test uart signals
   wire        tester_txd, tester_rxd;       
   wire        tester_rts, tester_cts;       

   //cpu trap signal
   wire        trap;
   
   //
   // UNIT UNDER TEST
   //
   system uut (
	       .clk           (clk),
	       .reset         (reset),
	       .trap          (trap),

`ifdef USE_DDR
               //DDR
               //address write
	       .m_axi_awid    (ddr_awid),
	       .m_axi_awaddr  (ddr_awaddr),
	       .m_axi_awlen   (ddr_awlen),
	       .m_axi_awsize  (ddr_awsize),
	       .m_axi_awburst (ddr_awburst),
	       .m_axi_awlock  (ddr_awlock),
	       .m_axi_awcache (ddr_awcache),
	       .m_axi_awprot  (ddr_awprot),
	       .m_axi_awqos   (ddr_awqos),
	       .m_axi_awvalid (ddr_awvalid),
	       .m_axi_awready (ddr_awready),
               
	       //write  
	       .m_axi_wdata   (ddr_wdata),
	       .m_axi_wstrb   (ddr_wstrb),
	       .m_axi_wlast   (ddr_wlast),
	       .m_axi_wvalid  (ddr_wvalid),
	       .m_axi_wready  (ddr_wready),
               
	       //write response
	       .m_axi_bid     (ddr_bid[0]),
	       .m_axi_bresp   (ddr_bresp),
	       .m_axi_bvalid  (ddr_bvalid),
	       .m_axi_bready  (ddr_bready),
               
	       //address read
	       .m_axi_arid    (ddr_arid),
	       .m_axi_araddr  (ddr_araddr),
	       .m_axi_arlen   (ddr_arlen),
	       .m_axi_arsize  (ddr_arsize),
	       .m_axi_arburst (ddr_arburst),
	       .m_axi_arlock  (ddr_arlock),
	       .m_axi_arcache (ddr_arcache),
	       .m_axi_arprot  (ddr_arprot),
	       .m_axi_arqos   (ddr_arqos),
	       .m_axi_arvalid (ddr_arvalid),
	       .m_axi_arready (ddr_arready),
               
	       //read   
	       .m_axi_rid     (ddr_rid[0]),
	       .m_axi_rdata   (ddr_rdata),
	       .m_axi_rresp   (ddr_rresp),
	       .m_axi_rlast   (ddr_rlast),
	       .m_axi_rvalid  (ddr_rvalid),
	       .m_axi_rready  (ddr_rready),	
`endif
               
               //UART
	       .uart_txd      (tester_rxd),
	       .uart_rxd      (tester_txd),
	       .uart_rts      (tester_cts),
	       .uart_cts      (tester_rts)
	       );


   //TESTER UART
   reg         uart_valid;
   reg [`UART_ADDR_W-1:0] uart_addr;
   reg [`DATA_W-1:0]      uart_wdata;
   reg                    uart_wstrb;
   reg [`DATA_W-1:0]      uart_rdata;
   wire                   uart_ready;

   iob_uart test_uart (
		       .clk       (clk),
		       .rst       (reset),
      
		       .valid     (uart_valid),
		       .address   (uart_addr),
		       .wdata     (uart_wdata),
		       .wstrb     (uart_wstrb),
		       .rdata     (uart_rdata),
		       .ready     (uart_ready),
      
		       .txd       (tester_txd),
		       .rxd       (tester_rxd),
		       .rts       (tester_rts),
		       .cts       (tester_cts)
		       );

`ifdef USE_DDR
   axi_ram 
     #(
 `ifdef USE_BOOT
       .FILE("none"),
 `else
       .FILE("firmware"),
 `endif
       .FILE_SIZE(2**(`MEM_ADDR_W-2)),
       .DATA_WIDTH (`DATA_W),
       .ADDR_WIDTH (`ADDR_W)
       )
   ddr_model_mem(
                 //address write
                 .clk            (clk),
                 .rst            (reset),
		 .s_axi_awid     ({8{ddr_awid}}),
		 .s_axi_awaddr   (ddr_awaddr[`ADDR_W-1:0]),
                 .s_axi_awlen    (ddr_awlen),
                 .s_axi_awsize   (ddr_awsize),
                 .s_axi_awburst  (ddr_awburst),
                 .s_axi_awlock   (ddr_awlock),
		 .s_axi_awprot   (ddr_awprot),
		 .s_axi_awcache  (ddr_awcache),
     		 .s_axi_awvalid  (ddr_awvalid),
		 .s_axi_awready  (ddr_awready),
      
		 //write  
		 .s_axi_wvalid   (ddr_wvalid),
		 .s_axi_wready   (ddr_wready),
		 .s_axi_wdata    (ddr_wdata),
		 .s_axi_wstrb    (ddr_wstrb),
                 .s_axi_wlast    (ddr_wlast),
      
		 //write response
		 .s_axi_bready   (ddr_bready),
                 .s_axi_bid      (ddr_bid),
                 .s_axi_bresp    (ddr_bresp),
		 .s_axi_bvalid   (ddr_bvalid),
      
		 //address read
		 .s_axi_arid     ({8{ddr_arid}}),
		 .s_axi_araddr   (ddr_araddr[`ADDR_W-1:0]),
		 .s_axi_arlen    (ddr_arlen), 
		 .s_axi_arsize   (ddr_arsize),    
                 .s_axi_arburst  (ddr_arburst),
                 .s_axi_arlock   (ddr_arlock),
                 .s_axi_arcache  (ddr_arcache),
                 .s_axi_arprot   (ddr_arprot),
		 .s_axi_arvalid  (ddr_arvalid),
		 .s_axi_arready  (ddr_arready),
      
		 //read   
		 .s_axi_rready   (ddr_rready),
		 .s_axi_rid      (ddr_rid),
		 .s_axi_rdata    (ddr_rdata),
		 .s_axi_rresp    (ddr_rresp),
                 .s_axi_rlast    (ddr_rlast),
		 .s_axi_rvalid   (ddr_rvalid)
                 );   
`endif

`include "iob_uart_cpu_tasks.v"
   
   // finish simulation
   always @(posedge trap)   	 
     #500 $finish;
   
endmodule

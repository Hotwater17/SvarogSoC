
module instr_mem_ahb #(
	parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 11
	)(
	//Global signals 
    input                       hclk_i,
    input                       hreset_i,

    //#####AHB#####
    //Select
    input                       hsel_i,

    //Address and control
    input   [DATA_WIDTH-1:0]    haddr_i,
    input                       hwrite_i,
    
    //Data
    input   [DATA_WIDTH-1:0]    hwdata_i,
    output  reg [DATA_WIDTH-1:0] hrdata_o,

    //Transfer response
    output  reg                 hready_o,
    output  reg                 hresp_o
	
    );

	logic [1:0] FSM;
    logic       cs;
    logic       wen;
    logic       oen;
    logic       is_write;
/*

    sram_instr  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) IMEM (
    .clk_i(hclk_i),
    .reset_i(hreset_i),
    .write_i(hwrite_i),
    .size_i(haddr_i[1:0]),
    .addr_i(haddr_i[12:2]),
    .cs_i(hsel_i),
    .wdata_i(hwdata_i),
    .rdata_o(hrdata_o)
);
*/
sram2k ISRAM(
   .Q(hrdata_o),
   .CLK(hclk_i),
   .CEN(cs),
   .WEN(wen),
   .A(haddr_i[12:2]),
   .D(hwdata_i),
   .OEN(oen)
);		  
		  
	//assign hready_o = FSM;
	assign hresp_o = 1'b0;
    //Change to use when cache is miss/hit

	always_ff @(negedge hclk_i) begin : romFSM
	
		if(FSM != 2'b11 && hsel_i) FSM <= FSM+2'b01;
		else FSM <= 2'b00;
		
        if(hsel_i && hwrite_i) is_write <= 1'b1;
        else if(FSM == 2'b11) is_write <= 1'b0;

	end
	
	always_comb begin : romComb
	
		if(FSM == 2'b11) hready_o = 1'b1;
		else hready_o = 1'b0;

        cs = ~((FSM == 2'b10));
        wen = ~(~cs && hwrite_i);  
		oen = ~(hready_o);
	end

	
	
endmodule




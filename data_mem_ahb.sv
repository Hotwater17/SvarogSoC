

module data_mem_ahb #(
	parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
	)(
	//Global signals 
    input                       hclk_i,
    input                       hreset_i,

    //#####AHB#####
    //Select
    input                       hsel_i,

    //Address and control
    input   [31:0]    haddr_i,
    input                       hwrite_i,
    
    //Data
    input   [DATA_WIDTH-1:0]    hwdata_i,
    output  reg [DATA_WIDTH-1:0]  hrdata_o,

    //Transfer response
    output  reg                 hready_o,
    output  reg                 hresp_o

);
	
logic [1:0] FSM;

logic       cs;
logic       wen;
logic       oen;
logic       is_write;

assign hresp_o = 1'b0;
/*

	*/
    /*
 sram_data #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(ADDR_WIDTH)
) DMEM (
    .clk_i(hclk_i),
    .reset_i(hreset_i),
    .size_i(haddr_i[1:0]),
    .addr_i(haddr_i[11:2]),
    .cs_i(hsel_i),
    .write_i(hwrite_i),
    .wdata_i(hwdata_i),
    .rdata_o(hrdata_o)
);
*/	

sram1k DSRAM(
   .Q(hrdata_o),
   .CLK(hclk_i),
   .CEN(cs),
   .WEN(wen),
   .A(haddr_i[11:2]),
   .D(hwdata_i),
   .OEN(oen)
);
//Remove this functionality
/*
	always_comb begin : mux
		if((haddr_i > 32'h00014000) && (haddr_i < 32'h00020000)) begin
			flash_sel = hsel_i;
			ram_sel = 1'b0;
			hrdata_o = flash_rdata;
			hready_o = flash_ready;
		end
		else begin
			flash_sel = 1'b0;
			ram_sel = hsel_i;
			hrdata_o = ram_rdata;
			hready_o = ram_ready;
		end
	end		
	*/
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
	
/*
	ext_flash_ctrl MEM(
        .clk_i(hclk_i),
        .reset_i(hreset_i),
        .req_i(flash_sel),
        .addr_i(haddr_i),
        .ready_o(flash_ready),
        .data_o(flash_rdata),
        .miso_i(miso_i),
		.mosi_o(mosi_o),
		.sck_o(sck_o),
		.ssn_o(ssn_o)
	);
*/
endmodule
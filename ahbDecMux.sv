
module ahbDecMux #(

  parameter DATA_WIDTH = 32,
  parameter FLASH_BASE_ADDR = 32'h00000000,
  parameter IMEM_BASE_ADDR = 32'h01000000,
  parameter DMEM_BASE_ADDR = 32'h02000000, 
  parameter PERIPH_BASE_ADDR = 32'h03000000,
  parameter UNUSED_BASE_ADDR = 32'h04000000
)(
	 //input	[1:0]					  htrans_i,
    input   [DATA_WIDTH-1:0]    haddr_i,
    output  [DATA_WIDTH-1:0]    hrdata_o,
    output                      hresp_o,
    output                      hready_o,

    

    input [DATA_WIDTH-1:0]      flash_hrdata_i,
    input                       flash_hresp_i,
    input                       flash_hready_i,
    output                      flash_hsel_o,

    input   [DATA_WIDTH-1:0]    imem_hrdata_i,
    input                       imem_hresp_i,
    input                       imem_hready_i, 
    output                      imem_hsel_o,   

    input   [DATA_WIDTH-1:0]    dmem_hrdata_i,
    input                       dmem_hresp_i,
    input                       dmem_hready_i,
    output                      dmem_hsel_o,

    input   [DATA_WIDTH-1:0]    periph_hrdata_i,
    input                       periph_hresp_i,
    input                       periph_hready_i,
    output                      periph_hsel_o

);


    assign  flash_hsel_o = ((haddr_i >= FLASH_BASE_ADDR) && (haddr_i < IMEM_BASE_ADDR)) ;
    assign  imem_hsel_o = ((haddr_i >= IMEM_BASE_ADDR && haddr_i < DMEM_BASE_ADDR));
    assign  dmem_hsel_o = ((haddr_i >= DMEM_BASE_ADDR && haddr_i < PERIPH_BASE_ADDR));
    assign  periph_hsel_o = ((haddr_i >= PERIPH_BASE_ADDR && haddr_i < UNUSED_BASE_ADDR));

    assign  hrdata_o =  (haddr_i >= FLASH_BASE_ADDR && haddr_i < IMEM_BASE_ADDR) ? flash_hrdata_i :
                        (haddr_i >= IMEM_BASE_ADDR && haddr_i < DMEM_BASE_ADDR) ? imem_hrdata_i :
                        (haddr_i >= DMEM_BASE_ADDR && haddr_i < PERIPH_BASE_ADDR) ? dmem_hrdata_i :
                        (haddr_i >= PERIPH_BASE_ADDR && haddr_i < UNUSED_BASE_ADDR) ? periph_hrdata_i : 32'h00000000;

    assign  hresp_o = (haddr_i >= FLASH_BASE_ADDR && haddr_i < IMEM_BASE_ADDR) ? flash_hresp_i :
                      (haddr_i >= IMEM_BASE_ADDR && haddr_i < DMEM_BASE_ADDR) ? imem_hresp_i :
                      (haddr_i >= DMEM_BASE_ADDR && haddr_i < PERIPH_BASE_ADDR) ? dmem_hresp_i :
                      (haddr_i >= PERIPH_BASE_ADDR && haddr_i < UNUSED_BASE_ADDR) ? periph_hresp_i : 1'b1;                      

    assign  hready_o =  (haddr_i >= FLASH_BASE_ADDR && haddr_i < IMEM_BASE_ADDR) ? flash_hready_i :
                        (haddr_i >= IMEM_BASE_ADDR && haddr_i < DMEM_BASE_ADDR) ? imem_hready_i :
                        (haddr_i >= DMEM_BASE_ADDR && haddr_i < PERIPH_BASE_ADDR) ? dmem_hready_i :
                        (haddr_i >= PERIPH_BASE_ADDR && haddr_i < UNUSED_BASE_ADDR) ? periph_hready_i : 1'b1;




endmodule
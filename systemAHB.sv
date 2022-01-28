module sys_top #(
  parameter DATA_WIDTH = 32,
  parameter SLAVE_NUMBER = 3,
  parameter IMEM_ADDR_WIDTH = 11, //2kW, 8kB
  parameter DMEM_ADDR_WIDTH = 10,  //1kW, 4kB
  parameter FLASH_BASE_ADDR = 32'h00000000,
  parameter IMEM_BASE_ADDR = 32'h01000000,
  parameter DMEM_BASE_ADDR = 32'h02000000, 
  parameter PERIPH_BASE_ADDR = 32'h03000000, 
  parameter UNUSED_BASE_ADDR = 32'h04000000
)(
  input                clk_i,
  input                reset_i,

  input   [DATA_WIDTH-1:0]  gpio0_i,
  output  [DATA_WIDTH-1:0]  gpio0_o,
  output  [DATA_WIDTH-1:0]  gpio0_oe,

  
  input                     flash_miso_i,
  output                    flash_mosi_o,
  output                    flash_sck_o,
  output                    flash_ssn_o,

  input                     spi_miso_i,
  output                    spi_mosi_o,
  output                    spi_sck_o,
  output                    spi_ssn_o,

  output 						        uart_tx_o,
  input 					        	uart_rx_i

);

    logic  [DATA_WIDTH-1:0]    hrdata;
    logic  [DATA_WIDTH-1:0]    hwdata;

    logic                       hready;
    logic                       hresp;

    logic  	[DATA_WIDTH-1:0]  haddr;
    logic                      hwrite;

    logic                      instr_req;

    logic                      flash_hsel;
    logic                      flash_hready;
    logic                      flash_hresp;
    logic  [DATA_WIDTH-1:0]    flash_hrdata;

    logic                      dmem_hsel;
    logic                      dmem_hready;
    logic                      dmem_hresp;
    logic  [DATA_WIDTH-1:0]    dmem_hrdata;
   
    logic                      imem_hsel;
    logic                      imem_hready;
    logic                      imem_hresp;
    logic  [DATA_WIDTH-1:0]    imem_hrdata;

    logic                      periph_hsel;
    logic                      periph_hready;
    logic                      periph_hresp;
    logic  [DATA_WIDTH-1:0]    periph_hrdata;



    logic  [SLAVE_NUMBER-1:0]  psel;       
    logic  [DATA_WIDTH-1:0]    paddr;
    logic                      penable;
    logic                      pwrite;
    logic  [DATA_WIDTH-1:0]    pwdata;
    logic  [(DATA_WIDTH*SLAVE_NUMBER)-1:0]    prdata;
    logic  [SLAVE_NUMBER-1:0]  pready;
    logic  [SLAVE_NUMBER-1:0]  pslverr;

    logic  [DATA_WIDTH-1:0]    gpio0_prdata;
    logic                      gpio0_pslverr;
    logic                      gpio0_pready;
    logic                      gpio0_psel;

    logic  [DATA_WIDTH-1:0]    uart0_prdata;
    logic                      uart0_pslverr;
    logic                      uart0_pready;
    logic                      uart0_psel;    

    logic  [DATA_WIDTH-1:0]    spi0_prdata;
    logic                      spi0_pslverr;
    logic                      spi0_pready;
    logic                      spi0_psel;
	 



assign prdata = {spi0_prdata, uart0_prdata, gpio0_prdata};
assign pready = {spi0_pready, uart0_pready, gpio0_pready};
assign pslverr  = {spi0_pslverr, uart0_pslverr, gpio0_pslverr};
assign spi0_psel = psel[2];
assign uart0_psel = psel[1];
assign gpio0_psel = psel[0];

ahbDecMux #(
  .DATA_WIDTH(32),
  .FLASH_BASE_ADDR(FLASH_BASE_ADDR),
  .IMEM_BASE_ADDR(IMEM_BASE_ADDR),
  .DMEM_BASE_ADDR(DMEM_BASE_ADDR), 
  .PERIPH_BASE_ADDR(PERIPH_BASE_ADDR),
  .UNUSED_BASE_ADDR(UNUSED_BASE_ADDR)
) DECMUX (
  .haddr_i(haddr),
  .imem_hrdata_i(imem_hrdata),
  .imem_hresp_i(imem_hresp),
  .imem_hready_i(imem_hready),
  .imem_hsel_o(imem_hsel),
  .dmem_hrdata_i(dmem_hrdata),
  .dmem_hresp_i(dmem_hresp),
  .dmem_hready_i(dmem_hready),
  .dmem_hsel_o(dmem_hsel),
  .periph_hrdata_i(periph_hrdata),
  .periph_hresp_i(periph_hresp),
  .periph_hready_i(periph_hready),
  .periph_hsel_o(periph_hsel),
  .flash_hsel_o(flash_hsel),
  .flash_hready_i(flash_hready),
  .flash_hresp_i(flash_hresp),
  .flash_hrdata_i(flash_hrdata),
  .hrdata_o(hrdata),
  .hresp_o(hresp),
  .hready_o(hready)
);



core_ahb CORE(
	.clk_i(clk_i),
	.reset_i(reset_i),
  .instr_req_o(instr_req),
	.hrdata_i(hrdata),
	.hwdata_o(hwdata),
	.hready_i(hready),
	.hresp_i(hresp),
	.haddr_o(haddr),
	.hwrite_o(hwrite)
	
);

flash_ahb EXT_FLASH(
  .hclk_i(clk_i),
  .hreset_i(reset_i),
  .hsel_i(flash_hsel),
  .haddr_i(haddr),
  .hwrite_i(hwrite),
  .hwdata_i(hwdata),
  .hrdata_o(flash_hrdata),
  .hready_o(flash_hready),
  .hresp_o(flash_hresp),
  .miso_i(flash_miso_i),
  .mosi_o(flash_mosi_o),
  .sck_o(flash_sck_o),
  .ssn_o(flash_ssn_o)
);

instr_mem_ahb #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(IMEM_ADDR_WIDTH)
  ) IMEM (
  .hclk_i(clk_i),
  .hreset_i(reset_i),
  .hsel_i(imem_hsel),
  .haddr_i(haddr),
  .hwrite_i(hwrite),
  .hwdata_i(hwdata),
  .hrdata_o(imem_hrdata),
  .hready_o(imem_hready),
  .hresp_o(imem_hresp)

);

data_mem_ahb #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(DMEM_ADDR_WIDTH)
  ) DMEM (
  .hclk_i(clk_i),
  .hreset_i(reset_i),
  .hsel_i(dmem_hsel),
  .haddr_i(haddr),
  .hwrite_i(hwrite),
  .hwdata_i(hwdata),
  .hrdata_o(dmem_hrdata),
  .hready_o(dmem_hready),
  .hresp_o(dmem_hresp)
);

AHB_APB_Bridge PeripheralBridge(
  .hclk_i(clk_i),
  .hreset_i(reset_i),
  .hsel_i(periph_hsel),
  .haddr_i(haddr),
  .hwrite_i(hwrite),
  .hwdata_i(hwdata),
  .hrdata_o(periph_hrdata),
  .hready_o(periph_hready),
  .hresp_o(periph_hresp),
  .psel_o(psel),
  .paddr_o(paddr),
  .penable_o(penable),
  .pwrite_o(pwrite),
  .pwdata_o(pwdata),
  .prdata_i(prdata),
  .pready_i(pready),
  .pslverr_i(pslverr)
);

//Slave 0
apb_gpio GPIO0(
  .clk_i(clk_i),
  .reset_i(reset_i),
  .pclk(clk_i),
  .presetn(reset_i),
  .paddr(paddr[4:0]),
  .psel(gpio0_psel),
  .penable(penable),
  .pwrite(pwrite),
  .pwdata(pwdata),
  .prdata(gpio0_prdata),
  .pready(gpio0_pready),
  .pslverr(gpio0_pslverr),
  .gpio_i(gpio0_i),
  .gpio_o(gpio0_o),
  .gpio_oe(gpio0_oe)
);

//Slave 1
apb_uart UART0(
  .clk_i(clk_i),
  .reset_i(reset_i),
  .pclk(clk_i),
  .presetn(reset_i),
  .paddr(paddr[3:0]),
  .psel(uart0_psel),
  .penable(penable),
  .pwrite(pwrite),
  .pwdata(pwdata),
  .prdata(uart0_prdata),
  .pready(uart0_pready),
  .pslverr(uart0_pslverr),
  .uart_rx(uart_rx_i),
  .uart_tx(uart_tx_o)
);

//Slave 2
apb_spi SPI0(

  .clk_i(clk_i),
	.reset_i(reset_i),
  .pclk(clk_i),
  .presetn(reset_i),
  .paddr(paddr[2:0]),
  .psel(spi0_psel),
  .penable(penable),
  .pwrite(pwrite),
  .pwdata(pwdata),
  .pready(spi0_pready),
  .prdata(spi0_prdata),
  .pslverr(spi0_pslverr),
  .miso_i(spi_miso_i),
  .mosi_o(spi_mosi_o),
  .sck_o(spi_sck_o),
  .ssn_o(spi_ssn_o)

);



endmodule
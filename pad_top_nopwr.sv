module pad_top(

    //inout           DVSS,
    //inout   [7:0]   VDD_core_pad,
    //inout   [7:0]   VDD_io_pad,

    input           clk_pad,
    input           resetn_pad,

    inout   [31:0]  gpio0_pad,

    input           flash_miso_pad,
    output          flash_sck_pad,
    output          flash_mosi_pad,
    output          flash_ssn_pad,

    input           spi_miso_pad,
    output          spi_sck_pad,
    output          spi_mosi_pad,
    output          spi_ssn_pad,

    input           uart_rx_pad,
    output          uart_tx_pad            
);

logic           clk_i_core;
logic           resetn_i_core;

logic [31:0]    gpio_i_core;
logic [31:0]    gpio_o_core;
logic [31:0]    gpio_oe_core;

logic           flash_miso_i_core;
logic           flash_sck_o_core;
logic           flash_mosi_o_core;
logic           flash_ssn_o_core;

logic           spi_miso_i_core;
logic           spi_sck_o_core;
logic           spi_mosi_o_core;
logic           spi_ssn_o_core;

logic           uart_rx_i_core;
logic           uart_tx_o_core;


sys_top SYSTEM(
    .clk_i(clk_i_core),
    .reset_i(resetn_i_core),
    .gpio0_i(gpio_i_core),
    .gpio0_o(gpio_o_core),
    .gpio0_oe(gpio_oe_core),
    .flash_miso_i(flash_miso_i_core),
    .flash_mosi_o(flash_mosi_o_core),
    .flash_sck_o(flash_sck_o_core),
    .flash_ssn_o(flash_ssn_o_core),
    .spi_miso_i(spi_miso_i_core),
    .spi_mosi_o(spi_mosi_o_core),
    .spi_sck_o(spi_sck_o_core),
    .spi_ssn_o(spi_ssn_o_core),
  	.uart_tx_o(uart_tx_o_core),
  	.uart_rx_i(uart_rx_i_core)
);



//TOTAL OF 84 PADS, 21 per side
/*
//Core
PVDD1CDG //3.3V --> 1.8V
PVSS3CDG

//IO(common ground with core)
PVDD2CDG //3.3V
PVSS3CDG
*/

//LEFT

//PVSS3CDG pad1 (.VSS(VSS));
//PVDD1CDG pad2  (.VDD(VDD));
//PVDD2CDG pad3  (.VDDPST(VDDPST));

//GPIO
PDUW0408SCDG pad4 (.DS(1'b0), .I(gpio_o_core[0]), .IE(~gpio_oe_core[0]), .C(gpio_i_core[0]), .OEN(~gpio_oe_core[0]), .PAD(gpio0_pad[0]), .PE(gpio_o_core[0] && ~gpio_oe_core[0]));
PDUW0408SCDG pad5 (.DS(1'b0), .I(gpio_o_core[1]), .IE(~gpio_oe_core[1]), .C(gpio_i_core[1]), .OEN(~gpio_oe_core[1]), .PAD(gpio0_pad[1]), .PE(gpio_o_core[1] && ~gpio_oe_core[1]));
PDUW0408SCDG pad6 (.DS(1'b0), .I(gpio_o_core[2]), .IE(~gpio_oe_core[2]), .C(gpio_i_core[2]), .OEN(~gpio_oe_core[2]), .PAD(gpio0_pad[2]), .PE(gpio_o_core[2] && ~gpio_oe_core[2]));
PDUW0408SCDG pad7 (.DS(1'b0), .I(gpio_o_core[3]), .IE(~gpio_oe_core[3]), .C(gpio_i_core[3]), .OEN(~gpio_oe_core[3]), .PAD(gpio0_pad[3]), .PE(gpio_o_core[3] && ~gpio_oe_core[3]));
PDUW0408SCDG pad8 (.DS(1'b0), .I(gpio_o_core[4]), .IE(~gpio_oe_core[4]), .C(gpio_i_core[4]), .OEN(~gpio_oe_core[4]), .PAD(gpio0_pad[4]), .PE(gpio_o_core[4] && ~gpio_oe_core[4]));
PDUW0408SCDG pad9 (.DS(1'b0), .I(gpio_o_core[5]), .IE(~gpio_oe_core[5]), .C(gpio_i_core[5]), .OEN(~gpio_oe_core[5]), .PAD(gpio0_pad[5]), .PE(gpio_o_core[5] && ~gpio_oe_core[5]));

//MID

//PVDD2CDG pad10  (.VDDPST(VDDPST));
//PVSS3CDG pad11 (.VSS(VSS));
//PVDD1CDG pad12  (.VDD(VDD));

PDUW0408SCDG pad13 (.DS(1'b0), .I(gpio_o_core[6]), .IE(~gpio_oe_core[6]), .C(gpio_i_core[6]), .OEN(~gpio_oe_core[6]), .PAD(gpio0_pad[6]), .PE(gpio_o_core[6] && ~gpio_oe_core[6]));
PDUW0408SCDG pad14 (.DS(1'b0), .I(gpio_o_core[7]), .IE(~gpio_oe_core[7]), .C(gpio_i_core[7]), .OEN(~gpio_oe_core[7]), .PAD(gpio0_pad[7]), .PE(gpio_o_core[7] && ~gpio_oe_core[7]));

//SPI
PDUW0408SCDG pad15 (.DS(1'b0), .I(spi_sck_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(spi_sck_pad), .PE(1'b0));
PDUW0408SCDG pad16 (.DS(1'b0), .I(spi_mosi_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(spi_mosi_pad), .PE(1'b0));
PDUW0408SCDG pad17 (.DS(1'b0), .I(spi_ssn_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(spi_ssn_pad), .PE(1'b0));
PDUW0408SCDG pad18 (.DS(1'b0), .I(1'b0), .IE(1'b1), .C(spi_miso_i_core), .OEN(1'b1), .PAD(spi_miso_pad), .PE(1'b1));

//PVDD2CDG pad19  (.VDDPST(VDDPST));
//PVDD1CDG pad20  (.VDD(VDD));
//PVSS3CDG pad21 (.VSS(VSS));



//TOP

//PVSS3CDG pad22 (.VSS(VSS));
//PVDD1CDG pad23  (.VDD(VDD));
//PVDD2CDG pad24  (.VDDPST(VDDPST));

//GPIO
PDUW0408SCDG pad25 (.DS(1'b0), .I(gpio_o_core[8]), .IE(~gpio_oe_core[8]), .C(gpio_i_core[8]), .OEN(~gpio_oe_core[8]), .PAD(gpio0_pad[8]), .PE(gpio_o_core[8] && ~gpio_oe_core[8]));
PDUW0408SCDG pad26 (.DS(1'b0), .I(gpio_o_core[9]), .IE(~gpio_oe_core[9]), .C(gpio_i_core[9]), .OEN(~gpio_oe_core[9]), .PAD(gpio0_pad[9]), .PE(gpio_o_core[9] && ~gpio_oe_core[9]));
PDUW0408SCDG pad27 (.DS(1'b0), .I(gpio_o_core[10]), .IE(~gpio_oe_core[10]), .C(gpio_i_core[10]), .OEN(~gpio_oe_core[10]), .PAD(gpio0_pad[10]), .PE(gpio_o_core[10] && ~gpio_oe_core[10]));
PDUW0408SCDG pad28 (.DS(1'b0), .I(gpio_o_core[11]), .IE(~gpio_oe_core[11]), .C(gpio_i_core[11]), .OEN(~gpio_oe_core[11]), .PAD(gpio0_pad[11]), .PE(gpio_o_core[11] && ~gpio_oe_core[11]));
PDUW0408SCDG pad29 (.DS(1'b0), .I(gpio_o_core[12]), .IE(~gpio_oe_core[12]), .C(gpio_i_core[12]), .OEN(~gpio_oe_core[12]), .PAD(gpio0_pad[12]), .PE(gpio_o_core[12] && ~gpio_oe_core[12]));
PDUW0408SCDG pad30 (.DS(1'b0), .I(gpio_o_core[13]), .IE(~gpio_oe_core[13]), .C(gpio_i_core[13]), .OEN(~gpio_oe_core[13]), .PAD(gpio0_pad[13]), .PE(gpio_o_core[13] && ~gpio_oe_core[13]));

//MID

//PVDD2CDG pad31  (.VDDPST(VDDPST));
//PVSS3CDG pad32 (.VSS(VSS));
//PVDD1CDG pad33  (.VDD(VDD));


PDUW0408SCDG pad34 (.DS(1'b0), .I(gpio_o_core[14]), .IE(~gpio_oe_core[14]), .C(gpio_i_core[14]), .OEN(~gpio_oe_core[14]), .PAD(gpio0_pad[14]), .PE(gpio_o_core[14] && ~gpio_oe_core[14]));
PDUW0408SCDG pad35 (.DS(1'b0), .I(gpio_o_core[15]), .IE(~gpio_oe_core[15]), .C(gpio_i_core[15]), .OEN(~gpio_oe_core[15]), .PAD(gpio0_pad[15]), .PE(gpio_o_core[15] && ~gpio_oe_core[15]));

//FLASH
PDUW0408SCDG pad36 (.DS(1'b0), .I(flash_sck_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(flash_sck_pad), .PE(1'b0));
PDUW0408SCDG pad37 (.DS(1'b0), .I(flash_mosi_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(flash_mosi_pad), .PE(1'b0));
PDUW0408SCDG pad38 (.DS(1'b0), .I(flash_ssn_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(flash_ssn_pad), .PE(1'b0));
PDUW0408SCDG pad39 (.DS(1'b0), .I(1'b0), .IE(1'b1), .C(flash_miso_i_core), .OEN(1'b1), .PAD(flash_miso_pad), .PE(1'b1));

//PVDD2CDG pad40  (.VDDPST(VDDPST));
//PVDD1CDG pad41  (.VDD(VDD));
//PVSS3CDG pad42 (.VSS(VSS));


//RIGHT

//PVSS3CDG pad43 (.VSS(VSS));
//PVDD1CDG pad44  (.VDD(VDD));
//PVDD2CDG pad45  (.VDDPST(VDDPST));

//GPIO
PDUW0408SCDG pad46 (.DS(1'b0), .I(gpio_o_core[16]), .IE(~gpio_oe_core[16]), .C(gpio_i_core[16]), .OEN(~gpio_oe_core[16]), .PAD(gpio0_pad[16]), .PE(gpio_o_core[16] && ~gpio_oe_core[16]));
PDUW0408SCDG pad47 (.DS(1'b0), .I(gpio_o_core[17]), .IE(~gpio_oe_core[17]), .C(gpio_i_core[17]), .OEN(~gpio_oe_core[17]), .PAD(gpio0_pad[17]), .PE(gpio_o_core[17] && ~gpio_oe_core[17]));
PDUW0408SCDG pad48 (.DS(1'b0), .I(gpio_o_core[18]), .IE(~gpio_oe_core[18]), .C(gpio_i_core[18]), .OEN(~gpio_oe_core[18]), .PAD(gpio0_pad[18]), .PE(gpio_o_core[18] && ~gpio_oe_core[18]));
PDUW0408SCDG pad49 (.DS(1'b0), .I(gpio_o_core[19]), .IE(~gpio_oe_core[19]), .C(gpio_i_core[19]), .OEN(~gpio_oe_core[19]), .PAD(gpio0_pad[19]), .PE(gpio_o_core[19] && ~gpio_oe_core[19]));
PDUW0408SCDG pad50 (.DS(1'b0), .I(gpio_o_core[20]), .IE(~gpio_oe_core[20]), .C(gpio_i_core[20]), .OEN(~gpio_oe_core[20]), .PAD(gpio0_pad[20]), .PE(gpio_o_core[20] && ~gpio_oe_core[20]));
PDUW0408SCDG pad51 (.DS(1'b0), .I(gpio_o_core[21]), .IE(~gpio_oe_core[21]), .C(gpio_i_core[21]), .OEN(~gpio_oe_core[21]), .PAD(gpio0_pad[21]), .PE(gpio_o_core[21] && ~gpio_oe_core[21]));

//MID

//PVDD2CDG pad52  (.VDDPST(VDDPST));
//PVSS3CDG pad53 (.VSS(VSS));
//PVDD1CDG pad54  (.VDD(VDD));

PDUW0408SCDG pad55 (.DS(1'b0), .I(gpio_o_core[22]), .IE(~gpio_oe_core[22]), .C(gpio_i_core[22]), .OEN(~gpio_oe_core[22]), .PAD(gpio0_pad[22]), .PE(gpio_o_core[22] && ~gpio_oe_core[22]));
PDUW0408SCDG pad56 (.DS(1'b0), .I(gpio_o_core[23]), .IE(~gpio_oe_core[23]), .C(gpio_i_core[23]), .OEN(~gpio_oe_core[23]), .PAD(gpio0_pad[23]), .PE(gpio_o_core[23] && ~gpio_oe_core[23]));
//UART
PDUW0408SCDG pad57 (.DS(1'b0), .I(uart_tx_o_core), .IE(1'b0), .C(), .OEN(1'b0), .PAD(uart_tx_pad), .PE(1'b0));
PDUW0408SCDG pad58 (.DS(1'b0), .I(1'b0), .IE(1'b1), .C(uart_rx_i_core), .OEN(1'b1), .PAD(uart_rx_pad), .PE(1'b1));

//UNUSED 2 PADS
//59
//60


//PVDD2CDG pad61  (.VDDPST(VDDPST));
//PVDD1CDG pad62  (.VDD(VDD));
//PVSS3CDG pad63 (.VSS(VSS));



//BOTTOM

//PVSS3CDG pad64 (.VSS(VSS));
//PVDD1CDG pad65  (.VDD(VDD));
//PVDD2CDG pad66  (.VDDPST(VDDPST));

//Clock
PDUW0408SCDG pad67 (.DS(1'b0), .I(1'b0), .IE(1'b1), .C(clk_i_core), .OEN(1'b1), .PAD(clk_pad), .PE(1'b1));

//GPIO
PDUW0408SCDG pad68 (.DS(1'b0), .I(gpio_o_core[24]), .IE(~gpio_oe_core[24]), .C(gpio_i_core[24]), .OEN(~gpio_oe_core[24]), .PAD(gpio0_pad[24]), .PE(gpio_o_core[24] && ~gpio_oe_core[24]));
PDUW0408SCDG pad69 (.DS(1'b0), .I(gpio_o_core[25]), .IE(~gpio_oe_core[25]), .C(gpio_i_core[25]), .OEN(~gpio_oe_core[25]), .PAD(gpio0_pad[25]), .PE(gpio_o_core[25] && ~gpio_oe_core[25]));
PDUW0408SCDG pad70 (.DS(1'b0), .I(gpio_o_core[26]), .IE(~gpio_oe_core[26]), .C(gpio_i_core[26]), .OEN(~gpio_oe_core[26]), .PAD(gpio0_pad[26]), .PE(gpio_o_core[26] && ~gpio_oe_core[26]));
PDUW0408SCDG pad71 (.DS(1'b0), .I(gpio_o_core[27]), .IE(~gpio_oe_core[27]), .C(gpio_i_core[27]), .OEN(~gpio_oe_core[27]), .PAD(gpio0_pad[27]), .PE(gpio_o_core[27] && ~gpio_oe_core[27]));
PDUW0408SCDG pad72 (.DS(1'b0), .I(gpio_o_core[28]), .IE(~gpio_oe_core[28]), .C(gpio_i_core[28]), .OEN(~gpio_oe_core[28]), .PAD(gpio0_pad[28]), .PE(gpio_o_core[28] && ~gpio_oe_core[28]));


//MID
//PVDD2CDG pad73  (.VDDPST(VDDPST));
//PVSS3CDG pad74 (.VSS(VSS));
//PVDD1CDG pad75  (.VDD(VDD));

PDUW0408SCDG pad76 (.DS(1'b0), .I(gpio_o_core[29]), .IE(~gpio_oe_core[29]), .C(gpio_i_core[29]), .OEN(~gpio_oe_core[29]), .PAD(gpio0_pad[29]), .PE(gpio_o_core[29] && ~gpio_oe_core[29]));
PDUW0408SCDG pad77 (.DS(1'b0), .I(gpio_o_core[30]), .IE(~gpio_oe_core[30]), .C(gpio_i_core[30]), .OEN(~gpio_oe_core[30]), .PAD(gpio0_pad[30]), .PE(gpio_o_core[30] && ~gpio_oe_core[30]));
PDUW0408SCDG pad78 (.DS(1'b0), .I(gpio_o_core[31]), .IE(~gpio_oe_core[31]), .C(gpio_i_core[31]), .OEN(~gpio_oe_core[31]), .PAD(gpio0_pad[31]), .PE(gpio_o_core[31] && ~gpio_oe_core[31]));

//UNUSED 2 PADS
//79
//80


//Reset
PDUW0408SCDG pad81 (.DS(1'b0), .I(1'b0), .IE(1'b1), .C(resetn_i_core), .OEN(1'b1), .PAD(resetn_pad), .PE(1'b1));

//PVDD2CDG pad82  (.VDDPST(VDDPST));
//PVDD1CDG pad83  (.VDD(VDD));
//PVSS3CDG pad84 (.VSS(VSS));



endmodule

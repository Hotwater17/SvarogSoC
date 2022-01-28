module flash_ahb #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 14
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
    output  reg                 hresp_o,

    //Flash SPI
	input                       miso_i,
	output                      mosi_o,
	output                      sck_o,
	output                      ssn_o
);

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam BUSY = 2'b10; 
localparam READY = 2'b11;

logic [1:0] thisState;
logic [1:0] nextState;

logic flash_req;
logic flash_busy;
/*
always_ff @(posedge hclk_i or negedge hreset_i) begin : reqBlock
    if(~hreset_i) begin
        flash_req <= 1'b0;
        flash_busy <= 1'b0;
    end 
    else if(hsel_i) begin
       if(hready_o && ~flash_req) begin 
           flash_busy <= 1'b1;
           if(~flash_busy) flash_req <= ~flash_busy;
       end
       else if(~hready_o && flash_req) begin
            if(flash_busy) flash_busy <= 1'b0;
            if(~flash_busy) flash_req <= 1'b0;
       end
    end
    else begin
        flash_req <= 1'b0;
    end
end
*/

always_ff @(posedge hclk_i or negedge hreset_i) begin : fsm_ff
    if(~hreset_i) begin
        thisState <= IDLE;
    end
    else begin
        thisState <= nextState;
    end
end

always_comb begin : fsm_logic
    case(thisState)
        IDLE : begin
           nextState = (hsel_i && hready_o /*&& ~flash_req*/) ? START : IDLE;
           flash_req = (hsel_i && hready_o /*&& ~flash_req*/); //FIXED THE TIMING LOOP
        end
        START : begin
            flash_req = hready_o;
            nextState = (~hready_o) ? BUSY : START;
        end
        BUSY : begin
            flash_req = 1'b0;
            nextState = (hsel_i && hready_o && ~flash_req) ? READY : BUSY;
        end
        READY : begin
            flash_req = 1'b0;
            nextState = (hready_o /*&& ~hsel_i*/) ? IDLE : READY;
        end
        default : begin
            flash_req = 1'b0;
            nextState = IDLE;
        end
    endcase
end

ext_flash_ctrl FLASH(
    .clk_i(hclk_i), 
    .reset_i(hreset_i),
    .req_i(flash_req),
    .addr_i(haddr_i[25:2]),
    .data_i(hwdata_i),
    .write_i(hwrite_i),
    .ready_o(hready_o),
    .data_o(hrdata_o),
    .miso_i(miso_i),
    .mosi_o(mosi_o),
    .sck_o(sck_o),
    .ssn_o(ssn_o)     
);



endmodule
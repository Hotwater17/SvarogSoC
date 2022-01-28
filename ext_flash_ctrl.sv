
module ext_flash_ctrl #(
    parameter DATA_WIDTH = 32
)(
    //Common signals
    input       clk_i, 
    input       reset_i,

        //Memory controller interface
    input                       req_i,
    input   [23:0]              addr_i,
    input   [DATA_WIDTH-1:0]    data_i, 
    input                       write_i,             
    output  reg                 ready_o,
    output  [DATA_WIDTH-1:0]    data_o,

    //SPI Interface
    input  miso_i,
    output mosi_o,
    output sck_o,
    output ssn_o
);

localparam READ_CMD = 8'h03;
localparam ADDR_BYTES = 3'h3;
localparam DATA_BYTES = 3'h4;

localparam FLASH_IDLE = 2'b00;
localparam FLASH_CMD = 2'b01; 
localparam FLASH_ADDR = 2'b10; 
localparam FLASH_DATA = 2'b11;
logic [1:0] flash_this_state;
logic [1:0] flash_next_state;

/*
    Flash controller signals
*/
logic [23:0] addr_reg;


logic [2:0] addr_byte_counter;
logic [2:0] data_byte_counter;

logic [7:0] read_data_word[0:3];

logic tx_data_valid; 
logic tx_ready;

logic ssn_reg;
logic ready_reg;

logic [7:0] tx_byte;
logic [7:0] rx_byte;

assign data_o = {read_data_word[3], read_data_word[2], read_data_word[1], read_data_word[0]};
assign ssn_o = ssn_reg;

  
  spi_master #(
	.SPI_MODE(0)
  ) SPI (
    .clk_i(clk_i),
    .spi_clk_i(clk_i),
    .reset_i(reset_i),
    .tx_data_valid_i(tx_data_valid),
    .tx_data_i(tx_byte),
    .rx_data_o(rx_byte),
    .tx_ready_o(tx_ready),
    .mode_i(2'b00),
    .miso_i(miso_i),
    .mosi_o(mosi_o),
    .sck_o(sck_o)
  );
/*
always_ff @(posedge clk_i or negedge reset_i) begin : addrStore
    if(~reset_i) addr_reg <= 32'h0; //HERE LIES THE ERROR
    else if((flash_this_state == FLASH_IDLE) && req_i && ssn_reg) addr_reg <= addr_i;
end
*/

always_ff @(posedge clk_i or negedge reset_i) begin : addrStore
    if(~reset_i) addr_reg <= 32'h0; 
    else if((flash_this_state == FLASH_IDLE) && req_i && ssn_reg) addr_reg <= addr_i;
end

always_ff @(posedge clk_i or negedge reset_i) begin : readDataStore
    if(~reset_i) begin
        read_data_word[0] <= 8'h0;
        read_data_word[1] <= 8'h0;
        read_data_word[2] <= 8'h0;
        read_data_word[3] <= 8'h0;
    end 
    else if((flash_this_state == FLASH_DATA) && (tx_ready)) begin
        case(data_byte_counter)
            0 : read_data_word[0] <= rx_byte;
            1 : read_data_word[1] <= rx_byte;
            2 : read_data_word[2] <= rx_byte;
            3 : read_data_word[3] <= rx_byte;
        endcase
    end
end

always_ff @(posedge clk_i or negedge reset_i) begin : slaveSelect
    if(~reset_i) ssn_reg <= 1'b1;
    else begin
        if((flash_this_state == FLASH_IDLE) && (req_i)) ssn_reg <= 1'b0;
        else if((flash_this_state == FLASH_DATA) && (tx_ready) && (data_byte_counter == 0)) ssn_reg <= 1'b1;
    end
end

always_ff @(posedge clk_i or negedge reset_i) begin : addrCounter
    if(~reset_i) addr_byte_counter <= ADDR_BYTES-2;
    else if(ssn_reg) addr_byte_counter <= ADDR_BYTES-2;
    else if((flash_this_state == FLASH_ADDR) && (tx_ready) && (addr_byte_counter > 0)) begin
         addr_byte_counter <= addr_byte_counter - 3'h1;
    end
end


always_ff @(posedge clk_i or negedge reset_i) begin : dataCounter
    if(~reset_i) data_byte_counter <= DATA_BYTES-1;
    else if(ssn_reg) data_byte_counter <= DATA_BYTES;
    else if((flash_this_state == FLASH_DATA) && (tx_ready) && (data_byte_counter > 0)) begin
         data_byte_counter <= data_byte_counter - 1;
    end
end

always_ff @(posedge clk_i or negedge reset_i) begin : flashFSM
    if(~reset_i) flash_this_state <= FLASH_IDLE;
    else flash_this_state <= flash_next_state;
end

/*
always_ff @( posedge clk_i or negedge reset_i ) begin : controlSignalsFSM
    case(flash_this_state)
        FLASH_IDLE : begin
            tx_data_valid <= (req_i && ssn_reg);
            ready_o <= ~req_i;
        end
        FLASH_CMD : begin
            tx_data_valid <= tx_ready;
            ready_o <= 1'b0;
        end
        FLASH_ADDR : begin
            tx_data_valid <= tx_ready;
            ready_o <= 1'b0;
        end
        FLASH_DATA : begin
            tx_data_valid <= tx_ready && (data_byte_counter != 0);
            ready_o <= tx_ready && (data_byte_counter == 0);
        end

        default : begin
            tx_data_valid <= 1'b0;
            ready_o <= 1'b1;
        end
    endcase
end
*/

always_ff @( posedge clk_i or negedge reset_i ) begin : readyFSM
    if(~reset_i) ready_o <= 1'b0;
    else begin
        case(flash_this_state) 
            FLASH_IDLE : ready_o <= (~req_i);
            FLASH_CMD : ready_o <= 1'b0;
            FLASH_ADDR : ready_o <= 1'b0;
            FLASH_DATA : ready_o <= (tx_ready && (data_byte_counter == 0));
        endcase
    end
end

always_comb begin : flashStateLogic
    case(flash_this_state)
        FLASH_IDLE : begin
            flash_next_state = (req_i && ssn_reg) ? FLASH_CMD : FLASH_IDLE; 
            tx_data_valid = (req_i && ssn_reg);
            tx_byte = (req_i && ssn_reg) ? READ_CMD : 8'h0;
            //ready_o = 1'b1;
            ready_reg = 1'b1;
        end
        FLASH_CMD : begin
            flash_next_state = tx_ready ? FLASH_ADDR : FLASH_CMD;
            tx_data_valid = tx_ready;
            tx_byte = (tx_ready) ? addr_reg[23:16] : 8'h0;
            //ready_o = 1'b0;
            ready_reg = 1'b0;
        end
        FLASH_ADDR : begin
            flash_next_state = (tx_ready && (addr_byte_counter == 0)) ? FLASH_DATA : FLASH_ADDR;
            tx_data_valid = tx_ready;
            //ready_o = 1'b0;
            ready_reg = 1'b0;
            case(addr_byte_counter)
                0 : tx_byte = addr_reg[7:0];
                1 : tx_byte = addr_reg[15:8];
                2 : tx_byte = addr_reg[23:16];
                //3 : tx_byte = addr_reg[31:24];
                default : tx_byte = 8'h0;
            endcase
        end
        FLASH_DATA : begin
            flash_next_state = (tx_ready && (data_byte_counter == 0)) ? FLASH_IDLE : FLASH_DATA;
            tx_data_valid = (tx_ready && (data_byte_counter != 0));
            tx_byte = 8'h0;
            //ready_o = (tx_ready && (data_byte_counter == 0));
            ready_reg = (tx_ready && (data_byte_counter == 0));
        end
        default : begin
            flash_next_state = FLASH_IDLE;
            tx_data_valid = 1'b0;
            tx_byte = 8'h0;
            //ready_o = 1'b1;
            ready_reg = 1'b1;
            
        end
    endcase
end


endmodule
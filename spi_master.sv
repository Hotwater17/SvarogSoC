module spi_master #(
    parameter SPI_MODE = 0
)(
  
input clk_i,
input spi_clk_i,
input reset_i,

input tx_data_valid_i,
input [7:0] tx_data_i,
output reg [7:0] rx_data_o,
output reg tx_ready_o,

input [1:0] mode_i,
  
input  miso_i,
output reg mosi_o,
output reg sck_o
  
);
  
/*
    SPI Master signals
*/

localparam CLK_PER_HALFBIT = 8;
  
logic CPOL;
logic CPHA;
logic [4:0] clock_edge_count;
logic spi_clock;
logic [$clog2(CLK_PER_HALFBIT*2)-1:0] spi_clock_count; //8 clocks per halfbit 
logic leading_edge;
logic trailing_edge;
logic [2:0] rx_bit_count;
logic [2:0] tx_bit_count;
logic [7:0] tx_data_buffer;
logic tx_data_valid_reg; 


/*assign CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);
assign CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);  
*/

assign CPOL = (mode_i == 2) | (mode_i == 3);
assign CPHA = (mode_i == 1) | (mode_i == 3);
  /*
    Actual SPI Master
*/


always_ff @(posedge spi_clk_i or  negedge reset_i) begin : dataStore
    if(~reset_i) begin
        tx_data_buffer <= 8'b0;
        tx_data_valid_reg <= 1'b0;
    end 
    else begin
        tx_data_valid_reg <= tx_data_valid_i;
        if(tx_data_valid_i) tx_data_buffer <= tx_data_i;
    end 
end

always_ff @(posedge spi_clk_i or negedge reset_i) begin : spiClock
    if(~reset_i) begin
        tx_ready_o <= 1'b0;
        spi_clock <= CPOL;
        spi_clock_count <= 0;
        clock_edge_count <= 0;
        trailing_edge <= 1'b0;
        leading_edge <= 1'b0;
        sck_o <= CPOL;    
    end
    else begin
        leading_edge <= 1'b0;
        trailing_edge <= 1'b0;

      if(tx_data_valid_i) begin
            tx_ready_o <= 1'b0;
            clock_edge_count <= 16;
            //First cycle
        end
        else if(clock_edge_count > 0) begin
            tx_ready_o <= 1'b0;
            //Edge detector
            if(spi_clock_count == (CLK_PER_HALFBIT*2) - 1) begin
                clock_edge_count <= clock_edge_count - 1;
                trailing_edge <= 1'b1;
                spi_clock_count <= 0;
                spi_clock <= ~spi_clock;
            end
            else if(spi_clock_count == CLK_PER_HALFBIT-1) begin
                clock_edge_count <= clock_edge_count - 1;
                leading_edge <= 1'b1;
                spi_clock_count <= spi_clock_count + 1;
                spi_clock <= ~spi_clock;
            end
            else begin
                spi_clock_count <= spi_clock_count + 1;
            end
        end
        else tx_ready_o <= 1'b1; //All 16 edges done for this byte transfer

        sck_o <= spi_clock;
    end

end


always_ff @(posedge spi_clk_i or negedge reset_i) begin : spiMOSI
    if(~reset_i) begin
        mosi_o <= 1'b0;
        tx_bit_count <= 3'h7; //MSB first
    end
    else begin
      if(tx_data_valid_reg & ~CPHA) begin //this never happens
            mosi_o <= tx_data_buffer[7];
            tx_bit_count <= 6;
        end
        else if((leading_edge & CPHA) | (trailing_edge & ~CPHA)) begin
            tx_bit_count <= tx_bit_count - 3'h1;
            mosi_o <= tx_data_buffer[tx_bit_count];
        end
        else if(tx_ready_o) begin 
          tx_bit_count <= 3'h7;
          mosi_o <= 1'b0;
      end
    end
end

always_ff @(posedge spi_clk_i or negedge reset_i) begin : spiMISO
    if(~reset_i) begin
        rx_data_o <= 8'b0;
        rx_bit_count <= 3'h7;
    end
    else begin
        if((leading_edge & ~CPHA) | (trailing_edge & CPHA)) begin
            rx_data_o[rx_bit_count] <= miso_i;
            rx_bit_count <= rx_bit_count - 3'h1;
        end
        else if(tx_ready_o) rx_bit_count <= 3'h7;
    end
end






  
endmodule
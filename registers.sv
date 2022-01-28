/*

	Registers

*/

module registers
#(
parameter DATA_WIDTH=32,
parameter REGISTERS_NUMBER=32,
parameter ADDR_BUS_WIDTH=5
)
(

input clk_i,
input reset_i,

input write_en_i,
input [ADDR_BUS_WIDTH-1:0] write_addr_i,
input [ADDR_BUS_WIDTH-1:0] read_1_addr_i,
input [ADDR_BUS_WIDTH-1:0] read_2_addr_i,
input [DATA_WIDTH-1:0] write_data_i,

output [DATA_WIDTH-1:0] read_1_data_o,
output [DATA_WIDTH-1:0] read_2_data_o

);

wire write_en_int;
reg [DATA_WIDTH-1:0] GPRx[REGISTERS_NUMBER-1:0];



assign read_1_data_o = (read_1_addr_i == 5'b00000) ? 32'h00000000 : GPRx[read_1_addr_i];
assign read_2_data_o = (read_2_addr_i == 5'b00000) ? 32'h00000000 : GPRx[read_2_addr_i];
assign write_en_int = (write_addr_i == 5'b00000) ? 1'b0 : write_en_i;

always_ff @(posedge clk_i or negedge reset_i)
begin

 if(!reset_i)
 begin
	
    GPRx[1] <= 32'h00000000;
    GPRx[2] <= 32'h00000000;
    GPRx[3] <= 32'h00000000;
    GPRx[4] <= 32'h00000000;
    GPRx[5] <= 32'h00000000;
    GPRx[6] <= 32'h00000000;
    GPRx[7] <= 32'h00000000;
    GPRx[8] <= 32'h00000000;
    GPRx[9] <= 32'h00000000;
    GPRx[10] <= 32'h00000000;
    GPRx[11] <= 32'h00000000;
    GPRx[12] <= 32'h00000000;
    GPRx[13] <= 32'h00000000;
    GPRx[14] <= 32'h00000000;
    GPRx[15] <= 32'h00000000;
    GPRx[16] <= 32'h00000000;
    GPRx[17] <= 32'h00000000;
    GPRx[18] <= 32'h00000000;
    GPRx[19] <= 32'h00000000;
    GPRx[20] <= 32'h00000000;
    GPRx[21] <= 32'h00000000;
    GPRx[22] <= 32'h00000000;
    GPRx[23] <= 32'h00000000;
    GPRx[24] <= 32'h00000000;
    GPRx[25] <= 32'h00000000;
    GPRx[26] <= 32'h00000000;
    GPRx[27] <= 32'h00000000;
    GPRx[28] <= 32'h00000000;
    GPRx[29] <= 32'h00000000;
    GPRx[30] <= 32'h00000000;
    GPRx[31] <= 32'h00000000;

end
 else if(write_en_int)
	begin
			GPRx[write_addr_i] <= write_data_i;
	end
end





endmodule
module Mux_2_to_1 #(
parameter DATA_WIDTH=32
)(

input [DATA_WIDTH-1:0] data0_i,
input [DATA_WIDTH-1:0] data1_i,

input select_i,

output reg [DATA_WIDTH-1:0] data_o

);



always @(*)
begin
	case(select_i)

		2'b00: data_o  = data0_i;
		2'b01: data_o  = data1_i;

	endcase
end



endmodule
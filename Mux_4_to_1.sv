module Mux_4_to_1 #(
parameter DATA_WIDTH=32
)(

input [DATA_WIDTH-1:0] data0_i,
input [DATA_WIDTH-1:0] data1_i,
input [DATA_WIDTH-1:0] data2_i,
input [DATA_WIDTH-1:0] data3_i,

input [1:0] select_i,

output reg [DATA_WIDTH-1:0] data_o

);



always_comb
begin
	case(select_i)

		2'b00: data_o  = data0_i;
		2'b01: data_o  = data1_i;
		2'b10: data_o  = data2_i;
		2'b11: data_o = data3_i;

	endcase
end



endmodule

/*

	ALU

*/

module alu #(

parameter DATA_WIDTH=32,
parameter ADDR_BUS_WIDTH=5,
parameter OP_WIDTH=10

)(

input clk_i,
input reset_i,

input [DATA_WIDTH-1:0] A_i,
input [DATA_WIDTH-1:0] B_i,
input [OP_WIDTH-1:0] Op_Sel_i,

output reg [DATA_WIDTH-1:0] Res_o,
output reg zero_o,
output reg carry_o,
output reg neg_o,
output reg ovf_o

);

always_comb
begin
	case(Op_Sel_i)

		//OP: 7bits of funct7 and 3 bits of funct3

		10'b0000000000: {carry_o, Res_o} = A_i + B_i; //ADD 
		10'b0100000000: {carry_o, Res_o} = A_i - B_i; //SUB
		10'b0000000001: {carry_o, Res_o} = A_i << B_i; //SLL
		10'b0000000010: //SLT
			begin
				if($signed(A_i) < $signed(B_i)) {carry_o, Res_o} = {1'b0, 32'h00000001};
				else {carry_o, Res_o} = {1'b0, 32'h0};
			end 
		10'b0000000011: //SLTU
			begin
				if(A_i < B_i) {carry_o, Res_o} = {1'b0, 32'h00000001};
				else {carry_o, Res_o} = {1'b0, 32'h0};
			end
		10'b0000000100: {carry_o, Res_o} = A_i ^ B_i; //XOR
		10'b0000000101: {carry_o, Res_o} = A_i >> B_i;//SRL
		10'b1000000101: {carry_o, Res_o} = A_i >>> B_i; //SRA
		10'b0000000110: {carry_o, Res_o} = A_i | B_i; //OR
		10'b0000000111: {carry_o, Res_o} = A_i & B_i; //AND
		default: 		{carry_o, Res_o} = {1'b0, 32'h0};

	endcase
	

	
	
end

	assign zero_o = ~(|Res_o);
	assign ovf_o = ({carry_o, Res_o[31]} == 2'b01);
	assign neg_o = Res_o[31];

endmodule
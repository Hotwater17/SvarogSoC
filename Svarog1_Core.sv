
/*

	Svarog-1 Core

*/


module Svarog1_Core #(
parameter DATA_WIDTH=32,
parameter REGISTERS_NUMBER=32
)(

//Basic signals

input clk_i,
input reset_i,

//Instruction interface

input                   instr_ready_i,
input  [DATA_WIDTH-1:0] instr_rdata_i,
output [DATA_WIDTH-1:0] instr_addr_o,
output                  instr_req_o,

//Data interface

input                   data_ready_i,
input  [DATA_WIDTH-1:0] data_rdata_i,
output reg [DATA_WIDTH-1:0] data_wdata_o,
output [DATA_WIDTH-1:0] data_addr_o,
output                  data_req_o,
output                  data_write_o

);



wire pc_branch_en;
wire [DATA_WIDTH-1:0] pc_instr_addr;
wire [DATA_WIDTH-1:0] pc_branch_addr;

wire rf_write_en;
wire [4:0] rf_write_addr;
wire [4:0] rf_read_1_addr;
wire [4:0] rf_read_2_addr;
wire [DATA_WIDTH-1:0] rf_write_data;

wire [DATA_WIDTH-1:0] rf_read_1_data;
wire [DATA_WIDTH-1:0] rf_read_2_data;

wire [DATA_WIDTH-1:0] alu_A;
wire [DATA_WIDTH-1:0] alu_B;
wire [9:0] alu_op_sel;

wire [DATA_WIDTH-1:0] alu_res;
wire alu_zero;
wire alu_neg;
wire alu_ovf;
wire alu_carry;

wire dec_br_sel;
wire [DATA_WIDTH-1:0] dec_imm_branch_addr;
wire [DATA_WIDTH-1:0] branch_link_addr;

wire [2:0] ls_extend;

wire [DATA_WIDTH-1:0] dec_a_imm;
wire [DATA_WIDTH-1:0] dec_b_imm;
wire dec_a_sel;
wire dec_b_sel;
wire dec_rf_wr_sel;

wire [DATA_WIDTH-1:0] dec_fetch_addr;

wire [DATA_WIDTH-1:0] branch_imm_with_offset;

wire data_wr_en;
wire data_rd_en;
reg [DATA_WIDTH-1:0] data_rdata_extended;


pc Program_Counter(

.clk_i(clk_i),
.reset_i(reset_i),
.pc_en_i(instr_ready_i),
.branch_en_i(pc_branch_en),
.branch_addr_i(pc_branch_addr),
.instr_addr_o(pc_instr_addr)

);

registers Register_File(

.clk_i(clk_i),
.reset_i(reset_i),
.write_en_i(rf_write_en),
.write_addr_i(rf_write_addr),
.read_1_addr_i(rf_read_1_addr),
.read_2_addr_i(rf_read_2_addr),
.write_data_i(rf_write_data),
.read_1_data_o(rf_read_1_data),
.read_2_data_o(rf_read_2_data)

);

alu ALU(

.clk_i(clk_i),
.reset_i(reset_i),
.A_i(alu_A),
.B_i(alu_B),
.Op_Sel_i(alu_op_sel),
.Res_o(alu_res),
.zero_o(alu_zero),
.carry_o(alu_carry),
.neg_o(alu_neg),
.ovf_o(alu_ovf)

);


newDecoder Decoder(

.clk_i(clk_i),
.reset_i(reset_i),
.imem_data_i(instr_rdata_i),
.imem_ready_i(instr_ready_i),
.instr_fetched_addr_o(dec_fetch_addr),
.instr_fetch_en_o(instr_req_o),
.flag_carry_i(alu_carry),
.flag_neg_i(alu_neg),
.flag_zero_i(alu_zero),
.flag_ovf_i(alu_ovf),
.br_sel_o(dec_br_sel),
.pc_addr_i(pc_instr_addr),
.pc_br_en_o(pc_branch_en),
.alu_b_imm_o(dec_b_imm),
.alu_a_sel_o(dec_a_sel),
.alu_b_sel_o(dec_b_sel),
.alu_op_sel_o(alu_op_sel),
.ls_data_extend_o(ls_extend),
.rf_wr_sel_o(dec_rf_wr_sel),
.rf_wr_en_o(rf_write_en),
.rf_rd_a_addr_o(rf_read_1_addr),
.rf_rd_b_addr_o(rf_read_2_addr),
.rf_wr_addr_o(rf_write_addr),
.dmem_ready_i(data_ready_i),
.dmem_wr_en_o(data_wr_en),
.dmem_rd_en_o(data_rd_en)	

);


Mux_2_to_1 Mux_A(

.data0_i(rf_read_1_data),
.data1_i(dec_fetch_addr),
.select_i(dec_a_sel),
.data_o(alu_A)

);

Mux_2_to_1 Mux_B(

.data0_i(rf_read_2_data),
.data1_i(dec_b_imm),
.select_i(dec_b_sel),
.data_o(alu_B)

);

Mux_4_to_1 Mux_Writeback(

.data0_i(alu_res),
.data1_i(data_rdata_extended),
.data2_i(branch_link_addr),
.data3_i(0),
.select_i({pc_branch_en, dec_rf_wr_sel}),
.data_o(rf_write_data)

);

Mux_2_to_1 Mux_Branch(

.data0_i(alu_res),
.data1_i(branch_imm_with_offset),
.select_i(dec_br_sel),
.data_o(pc_branch_addr)

);


always_comb begin : lsExtend

        unique case(ls_extend)

                3'b000 : begin //Signed Byte
                  data_wdata_o = { {24{rf_read_2_data[7]}},rf_read_2_data[7:0]};  
                  data_rdata_extended = { {24{data_rdata_i[7]}} ,data_rdata_i[7:0]};
                end
                3'b001 : begin //Signed Halfword
                  data_wdata_o = { {16{rf_read_2_data[15]}}, rf_read_2_data[15:0]};
                  data_rdata_extended = { {16{data_rdata_i[15]}}, data_rdata_i[15:0]};        
                end
                3'b010 : begin //Signed Word
                  data_wdata_o = rf_read_2_data[31:0];
                  data_rdata_extended = data_rdata_i[31:0];
                end
                3'b100 : begin //Unsigned Byte
                  data_wdata_o = { {24{1'b0}} , rf_read_2_data[7:0]};
                  data_rdata_extended = { {24{1'b0}}, data_rdata_i[7:0]};
                end 
                3'b101 : begin //Unsigned Halfword
                  data_wdata_o = { {16{1'b0}}, rf_read_2_data[15:0]};
                  data_rdata_extended = {{16{1'b0}}, data_rdata_i[15:0]};
                end

                default : begin
                  data_wdata_o = rf_read_2_data[31:0];
                  data_rdata_extended = data_rdata_i[31:0];                        
                end

        endcase
end

assign dec_imm_branch_addr = dec_b_imm;
assign branch_imm_with_offset = dec_imm_branch_addr + dec_fetch_addr;
assign branch_link_addr = dec_fetch_addr + 4; //Used to be pc_branch_addr + 4
assign instr_addr_o = pc_instr_addr;

assign data_write_o = (!data_rd_en && data_wr_en); 
assign data_req_o = data_rd_en || data_wr_en; 
assign data_addr_o = alu_res;



endmodule
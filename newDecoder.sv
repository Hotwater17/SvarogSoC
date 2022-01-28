module newDecoder #(

    parameter DATA_WIDTH = 32

)(
    input                       clk_i,
    input                       reset_i,

    input   [DATA_WIDTH-1:0]    imem_data_i,
    input                       imem_ready_i,

    output reg [DATA_WIDTH-1:0] instr_fetched_addr_o,
    output reg                  instr_fetch_en_o,

    input                       flag_carry_i,
    input                       flag_neg_i,
    input                       flag_zero_i,
    input                       flag_ovf_i,

    output reg                  br_sel_o, 
    input      [DATA_WIDTH-1:0] pc_addr_i,
    output reg                  pc_br_en_o,
    
    
    output reg [DATA_WIDTH-1:0] alu_b_imm_o,
    output reg                  alu_a_sel_o,
    output reg                  alu_b_sel_o,
    output reg [9:0]            alu_op_sel_o,

    output reg [2:0]            ls_data_extend_o,

    output reg                  rf_wr_sel_o,
    output reg                  rf_wr_en_o,
    output reg [4:0]            rf_rd_a_addr_o,
    output reg [4:0]            rf_rd_b_addr_o,
    output reg [4:0]            rf_wr_addr_o,

    input                       dmem_ready_i,
    output reg                  dmem_wr_en_o,
    output reg                  dmem_rd_en_o    

);


enum {ARG_REGFILE, ARG_IMM_PC} alu_arg_select;
enum {WB_ALU_PC, WB_DMEM} wb_select;
enum {PC_ALU, PC_IMM} pc_br_select;

//enum [1:0] {LSE_WS, LSE_HS, LSE_BS, LSE_U} lse_sign_extend;


enum {DEC_FETCH, DEC_EXEC, DEC_DMEM} decThisState, decNextState;

 
localparam I_LUI    =   7'b0110111;
localparam I_AUIPC  =   7'b0010111;
localparam I_JAL    =   7'b1101111;
localparam I_JALR   =   7'b1100111;
localparam I_BR     =   7'b1100011;
localparam I_LD     =   7'b0000011;
localparam I_ST     =   7'b0100011;
localparam I_IMM    =   7'b0010011;
localparam I_REG    =   7'b0110011;
localparam I_FENCE  =   7'b0001111;
localparam I_ECABR  =   7'b1110011; 


localparam BR_TYPE_BEQ  =   3'b000;
localparam BR_TYPE_BNE  =   3'b001;
localparam BR_TYPE_BLT  =   3'b100;
localparam BR_TYPE_BLTU =   3'b110;
localparam BR_TYPE_BGE  =   3'b101;
localparam BR_TYPE_BGEU =   3'b111;

localparam LD_TYPE_LB   =   3'b000;
localparam LD_TYPE_LH   =   3'b001;
localparam LD_TYPE_LW   =   3'b010;
localparam LD_TYPE_LD   =   3'b011;
localparam LD_TYPE_LBU  =   3'b100;
localparam LD_TYPE_LHU  =   3'b101;
localparam LD_TYPE_LWU  =   3'b110;

localparam ST_TYPE_SB   =   3'b000;
localparam ST_TYPE_SH   =   3'b001;
localparam ST_TYPE_SW   =   3'b010;
localparam ST_TYPE_SD   =   3'b011;



logic [DATA_WIDTH-1:0]  instr_fetch_reg;
logic [DATA_WIDTH-1:0]  instr_current_addr;
logic                   instr_is_dmem_access;
logic                   instr_is_jump;
logic                   instr_dmem_nrw;
logic                   br_addr_done;


assign instr_fetched_addr_o = instr_current_addr;


always_comb begin : dataPathLogic
    
    unique case(instr_fetch_reg[6:0])

            I_LUI : begin
                alu_b_imm_o = {instr_fetch_reg[31:12], 12'h000};
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_IMM_PC;
                alu_op_sel_o = 10'b0;
                rf_rd_a_addr_o = 5'b0; //x0
                rf_rd_b_addr_o = 5'b0; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
            end

            I_AUIPC : begin
                alu_b_imm_o = {instr_fetch_reg[31:12], 12'h000};
                alu_a_sel_o = ARG_IMM_PC;
                alu_b_sel_o = ARG_IMM_PC;
                alu_op_sel_o = 10'b0;
                rf_rd_a_addr_o = 5'b0; //x0
                rf_rd_b_addr_o = 5'b0; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
            end

            I_JAL : begin
                alu_b_imm_o = { {11{instr_fetch_reg[31]}}, instr_fetch_reg[31], instr_fetch_reg[19:12], instr_fetch_reg[20], instr_fetch_reg[30:21], 1'b0};
                alu_a_sel_o = ARG_IMM_PC; 
                alu_b_sel_o = ARG_IMM_PC;
                alu_op_sel_o = 10'b0000000000; //add - sum of the addresses
                rf_rd_a_addr_o = 5'b0; //x0
                rf_rd_b_addr_o = 5'b0; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_ALU_PC; //Write link address
                br_sel_o = PC_ALU;  //Jump to PC + imm calculated from ALU
                instr_is_jump = 1'b1;
                instr_is_dmem_access = 1'b0;
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
            end

            I_JALR : begin
                alu_b_imm_o = { {20{instr_fetch_reg[31]}}, instr_fetch_reg[31:20]};
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_IMM_PC;
                alu_op_sel_o = 10'b0000000000; //add - sum of the addresses (000)
                rf_rd_a_addr_o = instr_fetch_reg[19:15]; 
                rf_rd_b_addr_o = 5'b0; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_ALU_PC; //Write link address
                br_sel_o = PC_ALU; //Jump to rs1 + imm calculated from ALU
                instr_is_jump = 1'b1;
                instr_is_dmem_access = 1'b0;    
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
            end

            I_BR : begin
                alu_b_imm_o = { {19{instr_fetch_reg[31]}}, instr_fetch_reg[31],instr_fetch_reg[7], instr_fetch_reg[30:25], instr_fetch_reg[11:8], 1'b0};
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_REGFILE;
                
                rf_rd_a_addr_o = instr_fetch_reg[19:15];
                rf_rd_b_addr_o = instr_fetch_reg[24:20];
                rf_wr_addr_o = 5'b0;
                rf_wr_sel_o = WB_ALU_PC; 
                br_sel_o = PC_IMM; //Jump to PC + imm calculated externally(not ALU)
                instr_is_dmem_access = 1'b0; 
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
                unique case(instr_fetch_reg[14:12])
                    BR_TYPE_BEQ : begin
                        alu_op_sel_o = 10'b0100000000; //Subtract to compare
                        instr_is_jump = flag_zero_i;
                    end
                    BR_TYPE_BNE : begin
                        alu_op_sel_o = 10'b0100000000; //Subtract to compare
                        instr_is_jump = !flag_zero_i;
                    end 
                    BR_TYPE_BLT : begin
                        alu_op_sel_o = 10'b0000000010; //SLT
                        instr_is_jump = !flag_zero_i;
                    end 
                    BR_TYPE_BLTU : begin 
                        alu_op_sel_o = 10'b0000000011; //SLTU
                        instr_is_jump = !flag_zero_i;
                    end
                    BR_TYPE_BGE : begin
                        alu_op_sel_o = 10'b0000000010; //SLT
                        instr_is_jump = flag_zero_i;
                    end 
                    BR_TYPE_BGEU : begin 
                        alu_op_sel_o = 10'b0000000011; //SLTU
                        instr_is_jump = flag_zero_i;
                    end
                    default : begin
                        alu_op_sel_o = 10'b0100000000;
                        instr_is_jump = 1'b0;
                    end

                endcase
 
            end

            I_LD : begin
                alu_b_imm_o = { {20{instr_fetch_reg[31]}}, instr_fetch_reg[31:20]};
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_IMM_PC;
                alu_op_sel_o = 10'b0000000000; //Add to obtain address
                rf_rd_a_addr_o = instr_fetch_reg[19:15]; 
                rf_rd_b_addr_o = 5'b0; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_DMEM;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b1;
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = instr_fetch_reg[14:12]; //Distinguish between LB, LH, LW, unsigned too
            end

            I_ST : begin
                alu_b_imm_o = { {20{instr_fetch_reg[31]}}, instr_fetch_reg[31:25], instr_fetch_reg[11:7]};
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_IMM_PC;           
                alu_op_sel_o = 10'b0000000000; //Add to obtain address
                rf_rd_a_addr_o = instr_fetch_reg[19:15]; 
                rf_rd_b_addr_o = instr_fetch_reg[24:20];
                rf_wr_addr_o = 5'b00000;
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b1;
                instr_dmem_nrw = 1'b1;
                ls_data_extend_o = instr_fetch_reg[14:12]; //Distinguish between LB, LH, LW, unsigned too   
            end
            
            I_IMM : begin
                alu_b_imm_o = { {20{instr_fetch_reg[31]}}, instr_fetch_reg[31:20]};
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_IMM_PC;
                alu_op_sel_o = instr_fetch_reg[14:12]; //add - sum of the addresses (000)
                rf_rd_a_addr_o = instr_fetch_reg[19:15]; 
                rf_rd_b_addr_o = 5'b0; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;   
            end

            I_REG : begin
                alu_b_imm_o = 32'b0;
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_REGFILE;
                alu_op_sel_o = {instr_fetch_reg[31:25], instr_fetch_reg[14:12]};
                rf_rd_a_addr_o = instr_fetch_reg[19:15]; 
                rf_rd_b_addr_o = instr_fetch_reg[24:20]; //doesn't matter - immediate
                rf_wr_addr_o = instr_fetch_reg[11:7];
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;                 
            end

            I_FENCE : begin
                alu_b_imm_o = 32'b0;
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_REGFILE;
                alu_op_sel_o = 0;
                rf_rd_a_addr_o = 0; 
                rf_rd_b_addr_o = 0; 
                rf_wr_addr_o = 0;
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;   
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
                //IDK WHAT TO DO HERE
            end

            I_ECABR : begin
                alu_b_imm_o = 32'b0;
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_REGFILE;
                alu_op_sel_o = 0;
                rf_rd_a_addr_o = 0; 
                rf_rd_b_addr_o = 0; //doesn't matter - immediate
                rf_wr_addr_o = 0;
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;              
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
                //IDK WHAT TO DO HERE
            end

            default : begin
                alu_b_imm_o = 32'b0;
                alu_a_sel_o = ARG_REGFILE;
                alu_b_sel_o = ARG_REGFILE;
                alu_op_sel_o = 0;
                rf_rd_a_addr_o = 0; 
                rf_rd_b_addr_o = 0; //doesn't matter - immediate
                rf_wr_addr_o = 0;
                rf_wr_sel_o = WB_ALU_PC;
                br_sel_o = PC_ALU;
                instr_is_jump = 1'b0;
                instr_is_dmem_access = 1'b0;              
                instr_dmem_nrw = 1'b0;
                ls_data_extend_o = 3'b000;
            end

    endcase
 
end


always_comb begin : stateLogic
        
        unique case(decThisState)

            DEC_FETCH   :   begin
                decNextState = imem_ready_i ? DEC_EXEC : DEC_FETCH;
                instr_fetch_en_o = 1'b0;/*!imem_ready_i*/; //IDK if that's correct though. 
                rf_wr_en_o = 1'b0;
                pc_br_en_o = 1'b0;
                dmem_wr_en_o = 1'b0;
                dmem_rd_en_o = 1'b0;
                //if instruction is ready, go to exec
                //else stay in fetch
                //Also, increment PC if instr fetch is ready. Latch new instr and its address into register BELOW.
            end

            DEC_EXEC    :   begin
                //Wait 1 additional cycle in case of branch to calculate the branch address 
                decNextState = instr_is_dmem_access ? DEC_DMEM : (instr_is_jump ? (br_addr_done ? DEC_FETCH : DEC_EXEC) : DEC_FETCH); //Is it okay?
                instr_fetch_en_o = instr_is_jump ? br_addr_done : ~instr_is_dmem_access; //Next instruction request if no memory access 
                rf_wr_en_o = ~instr_is_dmem_access;
                pc_br_en_o = instr_is_jump;
                dmem_wr_en_o = (instr_dmem_nrw & instr_is_dmem_access);
                dmem_rd_en_o = (~instr_dmem_nrw & instr_is_dmem_access);
                //if memory access, go to dmem
                //else go to fetch
                //If no dmem, set instr request?
            end

            DEC_DMEM    :   begin
                decNextState = dmem_ready_i ? DEC_FETCH : DEC_DMEM;
                instr_fetch_en_o = /*1'b1*/ dmem_ready_i; //If there's going to be just a single access, request instr from arbiter
                rf_wr_en_o = ~instr_dmem_nrw & dmem_ready_i; //enable write if load instruction
                pc_br_en_o = 1'b0;
                dmem_wr_en_o = instr_dmem_nrw;
                dmem_rd_en_o = ~instr_dmem_nrw;
                //if memory access done, go to fetch
                //else stay in dmem
                //Set instr req
            end

            default     :   begin
                decNextState = DEC_FETCH;
                instr_fetch_en_o = 1'b1;
                rf_wr_en_o = 1'b0;
                pc_br_en_o = 1'b0;
                dmem_wr_en_o = 1'b0;
                dmem_rd_en_o = 1'b0;
            end

        endcase
       
end

always_ff @(posedge clk_i or negedge reset_i) begin : stateFSM
    
    if(!reset_i)    decThisState <= DEC_EXEC;
    else            decThisState <= decNextState;

end

always_ff @( posedge clk_i or negedge reset_i ) begin : isAddrDone
    if(~reset_i) br_addr_done <= 1'b0;
    else if((decThisState == DEC_EXEC) && instr_is_jump) br_addr_done <= 1'b1;
    else br_addr_done <= 1'b0;
end

//If timing between PC increment and fetch is not right, try changing to posedge imem_ready_i
always_ff @(posedge clk_i or negedge reset_i) begin : instrFetch
    
    if(!reset_i) begin
        instr_fetch_reg <= 32'h0;
        instr_current_addr <= 32'h0;
    end
    else if((decThisState == DEC_FETCH) && imem_ready_i) begin
        instr_fetch_reg <= imem_data_i;
        instr_current_addr <= pc_addr_i;
    end

end

endmodule
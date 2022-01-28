

module core_ahb #(
    parameter DATA_WIDTH = 32
)(
    //Global signals
    input clk_i,
    input reset_i,
	 
    output              instr_req_o,

    //##########AHB#########
    //Data
    input   [DATA_WIDTH-1:0]    hrdata_i,
    output  reg [DATA_WIDTH-1:0]    hwdata_o,

    //Transfer response
    input                       hready_i,
    input                       hresp_i,

    //Address and control
    output  reg [DATA_WIDTH-1:0]    haddr_o,
    output  reg                     hwrite_o
    
);

reg                      instr_ready;
reg  [DATA_WIDTH-1:0]    instr_rdata;
wire    [DATA_WIDTH-1:0]    instr_addr;
wire                        instr_req;

reg                      data_ready;
reg   [DATA_WIDTH-1:0]    data_rdata;
wire    [DATA_WIDTH-1:0]    data_wdata; 
wire    [DATA_WIDTH-1:0]    data_addr;
wire                        data_req;
wire                        data_write;    

logic							  icache_req_pending;

logic icache_ready;
logic [DATA_WIDTH-1:0] icache_rdata;
logic cache_hit;
logic icache_req;


enum logic [2:0] {IDLE, I_ADDR, I_DATA, D_ADDR, D_DATA} arbiterThisState, arbiterNextState;

assign instr_req_o = icache_req;


Svarog1_Core core(
.clk_i(clk_i),
.reset_i(reset_i),
.instr_ready_i(icache_ready),
.instr_rdata_i(icache_rdata),
.instr_addr_o(instr_addr),
.instr_req_o(instr_req),
.data_ready_i(data_ready),
.data_rdata_i(data_rdata),
.data_wdata_o(data_wdata),
.data_addr_o(data_addr),
.data_req_o(data_req),
.data_write_o(data_write)   
);

ICACHE # (
    .DATA_WIDTH(DATA_WIDTH),
    .CACHE_SIZE_BITS(5) //32 words
    ) I1 (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .core_addr_i(instr_addr),
    .core_req_i(instr_req),
    .core_ready_o(icache_ready),
    .core_rdata_o(icache_rdata),
    .cache_req_o(icache_req),
    .hrdata_i(hrdata_i),
    .hready_i(hready_i && (arbiterThisState == I_DATA))
);

//Write an arbiter/controller and put the module here


always_comb begin : arbiterStateLogic

    unique case(arbiterThisState)
        IDLE : begin
            if(data_req /*&& hgrant_i*/) arbiterNextState = D_ADDR;
            else if((icache_req /*|| icache_req_pending*/) /*&& hgrant_i*/) arbiterNextState = I_ADDR;
            else arbiterNextState = IDLE;
        end
        I_ADDR : begin
            arbiterNextState = I_DATA;
        end
        I_DATA : begin //TODO: Add another option if transfer was not successful(retry)
            arbiterNextState = hready_i ? (data_req ? D_ADDR : IDLE) : I_DATA;
        end
        D_ADDR : begin
            arbiterNextState = D_DATA;
        end

        D_DATA : begin //TODO: Add another option if transfer was not successful(retry)
        //ITS JUST MAX 1 DATA CYCLE NOW I THINK
            arbiterNextState = hready_i ? (icache_req ? I_ADDR : IDLE) : D_DATA;
        end
		
		default arbiterNextState = IDLE;
    endcase
end

always_ff @(posedge clk_i or negedge reset_i) begin : arbiterStateFSM

    if(!reset_i) begin
        arbiterThisState <= IDLE;
    end
    else begin
        arbiterThisState <= arbiterNextState;
    end
end

always_comb begin : arbiterBusLogic
    unique case (arbiterThisState)
        IDLE : begin
				
            hwdata_o = 32'h0;
            haddr_o = 32'hFFFFFFFF;
            hwrite_o = 1'b0;
            
            instr_rdata = 32'h0;
            instr_ready = 1'b0;
            data_rdata = 32'h0;
            data_ready = 1'h0;
				
			
				
        end 
        I_ADDR : begin
            hwdata_o = 32'h0;
            haddr_o = instr_addr;
            hwrite_o = 1'b0;

            instr_rdata = 32'h0;
            instr_ready = 1'b0;
            data_rdata = 32'h0;
            data_ready = 1'h0;

            

        end
        I_DATA : begin
            hwdata_o = 32'h0;
            haddr_o = instr_addr;
            hwrite_o = 1'b0;

            instr_rdata = hrdata_i;
            instr_ready = hready_i;
            data_rdata = 32'h0;
            data_ready = 1'h0;         
             
        end
        D_ADDR : begin
            hwdata_o = 32'h0;
            haddr_o = data_addr;
            hwrite_o = data_write;

            instr_rdata = 32'h0;
            instr_ready = 1'b0;
            data_rdata = 32'h0;
            data_ready = 1'h0;

            
        end
        D_DATA : begin
            hwdata_o = data_write ? data_wdata : 32'h0;
            haddr_o = data_addr;
            hwrite_o = data_write;

            instr_rdata = 32'h0;
            instr_ready = 1'b0;
            data_rdata = hrdata_i;
            data_ready = hready_i; //For multiple access set data_ready high only when all transfers are done(burst cnt = 0)

            
        end
		default : begin
            hwdata_o = 32'h0;
            haddr_o = 32'h0;
            hwrite_o = 1'b0;
            

            instr_rdata = 32'h0;
            instr_ready = 1'b0;
            data_rdata = 32'h0;
            data_ready = 1'h0;			

            
		end
         
    endcase
end


endmodule
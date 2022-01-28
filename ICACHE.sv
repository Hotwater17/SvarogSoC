

module ICACHE #(
    parameter DATA_WIDTH = 32,
    parameter CACHE_SIZE_BITS = 4,
    parameter CACHE_LENGTH = 2 ** CACHE_SIZE_BITS,
    parameter TAG_SIZE_BITS = DATA_WIDTH - CACHE_SIZE_BITS - 2, //2 - skip 2 LSB, as 1 word is in 1 entry 
    parameter BYTE_OFFSET = 2
)(

    //##### Common signals #####

    input                       clk_i,
    input                       reset_i,

    //##### Core interface #####

    input   [DATA_WIDTH-1:0]    core_addr_i,
    input                       core_req_i,
    output                      core_ready_o,
    output  [DATA_WIDTH-1:0]    core_rdata_o,

    output reg                  cache_hit_o,

    output reg                  cache_req_o, 
    //##### Bus interface (AHB) #####

    //Data 
    input   [DATA_WIDTH-1:0]        hrdata_i,
    //output  reg [DATA_WIDTH-1:0]    hwdata_o,

    //Transfer response
    input                       hready_i,
    input                       hresp_i
    
    
);




logic                   valid_bit [0:CACHE_LENGTH-1];
logic [TAG_SIZE_BITS-1:0] cache_tag [0:CACHE_LENGTH-1];
logic [TAG_SIZE_BITS-1:0] req_tag;
logic [DATA_WIDTH-1:0]  cache_data [0:CACHE_LENGTH-1];
logic [CACHE_SIZE_BITS-1:0] cache_index;
logic cache_is_hit;
logic cache_is_miss; 
logic tag_match;
logic sram_ready;
logic sram_wr_en;

integer cnt;

enum {CACHE_IDLE, CACHE_COMPARE, CACHE_WB, CACHE_ALLOCATE} cacheThisState, cacheNextState;

assign cache_index = core_addr_i[(CACHE_SIZE_BITS+BYTE_OFFSET-1):(BYTE_OFFSET)]; //In case of 256 cell cache(8 bits)- 9:2
assign cache_hit_o = cache_is_hit;
assign req_tag = core_addr_i[(DATA_WIDTH-1):(CACHE_SIZE_BITS+BYTE_OFFSET)];
assign tag_match = (cache_tag[cache_index] == req_tag);
assign cache_is_hit = (tag_match && valid_bit[cache_index] && (cacheThisState == CACHE_COMPARE)); //If tag is matched and valid bit is 1, hit
assign cache_is_miss = ((!tag_match || !(valid_bit[cache_index])) && (cacheThisState == CACHE_COMPARE));
assign sram_ready = (cacheThisState == CACHE_COMPARE); //Memory is always ready with this implementation(registers)
assign sram_wr_en = (cacheThisState == CACHE_ALLOCATE);

assign core_rdata_o = cache_data[cache_index];
assign core_ready_o = cache_is_hit;

assign cache_req_o = (cacheThisState == CACHE_ALLOCATE);

always_ff @(posedge clk_i or negedge reset_i) begin : dataAllocate
    
    if(~reset_i) begin
        for(cnt=0; cnt<2 ** CACHE_SIZE_BITS; cnt++) begin
        cache_data[cnt] <= 32'h00000000;
        cache_tag[cnt] <= 22'b0;
        valid_bit[cnt] <= 1'b0;
    end
    end
    else if(sram_wr_en && hready_i) begin
        cache_data[cache_index] <= hrdata_i;
        cache_tag[cache_index] <= req_tag;
        valid_bit[cache_index] <= 1'b1;
    end

end

always_comb begin : cacheStateLogic
    
    unique case(cacheThisState)
        
        CACHE_IDLE : cacheNextState = core_req_i ? CACHE_COMPARE : CACHE_IDLE;

        CACHE_COMPARE : begin   
            cacheNextState = sram_ready ? (cache_is_hit ?  CACHE_IDLE : CACHE_ALLOCATE) : CACHE_COMPARE;
        end
        CACHE_ALLOCATE : cacheNextState = hready_i ? CACHE_COMPARE : CACHE_ALLOCATE;

        default : cacheNextState = CACHE_IDLE;

    endcase

end

always_ff @(posedge clk_i or negedge reset_i) begin : cacheStateFSM
    
    if(!reset_i) cacheThisState <= CACHE_IDLE; 
    else cacheThisState <= cacheNextState;

end


endmodule

module AHB_APB_Bridge #(
    parameter DATA_WIDTH = 32,
    parameter SLAVE_NUMBER = 3,
    parameter PERIPH_BASE_ADDR = 32'h03000000,
    parameter S0_OFFSET_ADDR =  32'h03000000,
    parameter S1_OFFSET_ADDR =  32'h03000100,
    parameter S2_OFFSET_ADDR =  32'h03000200,
    parameter S3_OFFSET_ADDR =  32'h03000300,
    parameter S4_OFFSET_ADDR =  32'h03000400,
    parameter S5_OFFSET_ADDR =  32'h03000500,
    parameter S6_OFFSET_ADDR =  32'h03000600,
    parameter S7_OFFSET_ADDR =  32'h03000700,
    parameter SLAVE_BOUNDARY =  32'h03000800
)(
    //Global signals 
    input                       hclk_i,
    input                       hreset_i,

    //#####AHB#####
    //Select
    input                       hsel_i,

    //Address and control
    input   [DATA_WIDTH-1:0]    haddr_i,
    input                       hwrite_i,
    
    //Data
    input   [DATA_WIDTH-1:0]    hwdata_i,
    output  reg [DATA_WIDTH-1:0] hrdata_o,

    //Transfer response
    output  reg                 hready_o,
    output  reg                 hresp_o,

    //#####APB#####
    
    //Select
    output  reg [SLAVE_NUMBER-1:0]  psel_o,

    //Address and control
    output  reg [DATA_WIDTH-1:0]    paddr_o,
    output  reg                     penable_o,
    output  reg                     pwrite_o,
    
    //Data
    output  reg [DATA_WIDTH-1:0]    pwdata_o,
    input       [(SLAVE_NUMBER*DATA_WIDTH)-1:0]    prdata_i,

    //Transfer response
    input   [SLAVE_NUMBER-1:0]      pready_i,
    input   [SLAVE_NUMBER-1:0]      pslverr_i 



    );

    logic awaitingTransfer;
    logic apbAddress;
    

    int  currentSlave;

    logic [DATA_WIDTH-1:0] prdataMuxed;
    logic                  preadyMuxed;
    logic                  pslverrMuxed;

    enum logic {HADDR, HDATA} ahbThisState, ahbNextState;

    enum logic [1:0] {PIDLE, PSETUP, PACCESS} apbThisState, apbNextState;

    assign psel_o[0] = (haddr_i >= S0_OFFSET_ADDR && haddr_i < S1_OFFSET_ADDR) && (apbThisState != PIDLE);
    assign psel_o[1] = (haddr_i >= S1_OFFSET_ADDR && haddr_i < S2_OFFSET_ADDR) && (apbThisState != PIDLE);
    assign psel_o[2] = (haddr_i >= S2_OFFSET_ADDR && haddr_i < S3_OFFSET_ADDR) && (apbThisState != PIDLE);
    /*assign psel_o[3] = (haddr_i >= S3_OFFSET_ADDR && haddr_i < S4_OFFSET_ADDR) && (apbThisState != PIDLE);
    assign psel_o[4] = (haddr_i >= S4_OFFSET_ADDR && haddr_i < S5_OFFSET_ADDR) && (apbThisState != PIDLE);
    assign psel_o[5] = (haddr_i >= S5_OFFSET_ADDR && haddr_i < S6_OFFSET_ADDR) && (apbThisState != PIDLE);
    assign psel_o[6] = (haddr_i >= S6_OFFSET_ADDR && haddr_i < S7_OFFSET_ADDR) && (apbThisState != PIDLE);
    assign psel_o[7] = (haddr_i >= S7_OFFSET_ADDR && haddr_i < SLAVE_BOUNDARY) && (apbThisState != PIDLE);*/



    assign pslverrMuxed = pslverr_i[currentSlave];
    assign preadyMuxed = pready_i[currentSlave];
    //assign prdataMuxed = prdata_i[((currentSlave+1)*DATA_WIDTH)-1 : currentSlave*DATA_WIDTH];
    


    always_comb begin : addrMux
        
         if(haddr_i >= S0_OFFSET_ADDR && haddr_i < S1_OFFSET_ADDR) begin
             currentSlave = 0;
             prdataMuxed = prdata_i[31:0];
         end
         else if(haddr_i >= S1_OFFSET_ADDR && haddr_i < S2_OFFSET_ADDR) begin
             currentSlave = 1;
             prdataMuxed = prdata_i[63:32];
         end
         else if(haddr_i >= S2_OFFSET_ADDR && haddr_i < S3_OFFSET_ADDR) begin
             currentSlave = 2;
             prdataMuxed = prdata_i[95:64];
         end
         /*else if(haddr_i >= S3_OFFSET_ADDR && haddr_i < S4_OFFSET_ADDR) begin
             currentSlave = 3;
             prdataMuxed = prdata_i[127:96];
         end
         else if(haddr_i >= S4_OFFSET_ADDR && haddr_i < S5_OFFSET_ADDR) begin
             currentSlave = 4;
             prdataMuxed = prdata_i[159:128];
         end
         else if(haddr_i >= S5_OFFSET_ADDR && haddr_i < S6_OFFSET_ADDR) begin
             currentSlave = 5;
             prdataMuxed = prdata_i[191:160];
         end
         else if(haddr_i >= S6_OFFSET_ADDR && haddr_i < S7_OFFSET_ADDR) begin
             currentSlave = 6;
             prdataMuxed = prdata_i[223:192];
         end
         else if(haddr_i >= S7_OFFSET_ADDR && haddr_i < SLAVE_BOUNDARY) begin
             currentSlave = 7;
             prdataMuxed = prdata_i[255:224];
         end*/
         else begin
             currentSlave = 0;
             prdataMuxed = prdata_i[31:0]; 
         end

    end

    always_comb begin : ahbNextStateLogic
        
        unique case(ahbThisState)

            HADDR : begin
                if(hsel_i) ahbNextState = HDATA; 
                else ahbNextState = HADDR;
            end 
            HDATA : begin
                //Should I wait for one more cycle in AHB after pready_i is set?
                //Make a counter for incremental transfers
                ahbNextState = preadyMuxed ? HADDR : HDATA; //If APB transfer ready, transfer data from APB to AHB
            end

            default : begin
                ahbNextState = HADDR;
            end

        endcase

    end

    always_ff @(posedge hclk_i or negedge hreset_i) begin : ahbNextStateFSM
         
        if(!hreset_i) ahbThisState <= HADDR;
        else ahbThisState <= ahbNextState;

    end

    always_comb begin : ahbBusLogic
        
        unique case(ahbThisState)

            HADDR : begin
                hready_o = 1'b0;
                hresp_o = 1'b0;
                hrdata_o = 32'h0;
            end

            HDATA : begin
                hready_o = preadyMuxed;
                hresp_o = pslverrMuxed;
                hrdata_o = hwrite_i ? 32'h0 : prdataMuxed;
            end 

            default : begin
                hready_o = 1'b0;
                hresp_o = 1'b0;
                hrdata_o = 32'h0;
            end

        endcase

    end



    always_comb begin : apbNextStateLogic
        
        unique case(apbThisState)

            PIDLE : begin
                if(hsel_i /*&& htrans_i[1] == 1'b1*/) apbNextState = PSETUP;
                else apbNextState = PIDLE;
            end

            PSETUP : begin
                apbNextState = PACCESS;
            end

            PACCESS : begin
                //Check for more transfers on hold - if there are more, back to psetup. If not, go to pidle. Otherwise wait
                apbNextState = preadyMuxed ? (pslverrMuxed ? PSETUP : PIDLE) : PACCESS;
            end

            default : begin
                apbNextState = PIDLE;
            end

        endcase

    end

    always_ff @(posedge hclk_i or negedge hreset_i) begin : apbNextStateFSM
        
        if(!hreset_i) apbThisState <= PIDLE;
        else apbThisState <= apbNextState;

    end

    always_comb begin : apbBusLogic
        unique case(apbThisState)
            
            PIDLE : begin

                paddr_o = 32'h0;
                penable_o = 1'b0;
                pwrite_o = 1'b0;
                pwdata_o = 32'h0;
            end

            PSETUP : begin

                paddr_o = haddr_i;
                penable_o = 1'b0;
                pwrite_o = hwrite_i;
                if(hwrite_i) pwdata_o = hwdata_i;
                else pwdata_o = 32'h0;

            end

            PACCESS : begin

                paddr_o = haddr_i;
                penable_o = 1'b1;
                pwrite_o = hwrite_i;
                pwdata_o = hwrite_i ? hwdata_i : 32'h0;
            end

            default : begin
                paddr_o = 32'h0;
                penable_o = 1'b0;
                pwrite_o = 1'b0;
                pwdata_o = 32'h0;
            end



        endcase
    end


endmodule

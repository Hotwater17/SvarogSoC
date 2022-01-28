    
module apb_spi #(
        parameter DATA_WIDTH = 32
    )(
        //Common signals
        input									clk_i,
        input									reset_i,
        
        //APB
        input									pclk,
        input									presetn,
        input		[2:0]   					paddr,
        input									psel,
        input									penable,
        input									pwrite,
        input		[DATA_WIDTH-1:0]			pwdata,
        output reg								pready,
        output reg	[DATA_WIDTH-1:0]			prdata,
        output reg								pslverr,

        //SPI
        input                                   miso_i,
        output                                  mosi_o,
        output                                  sck_o,
        output reg                              ssn_o
    );



    
    localparam READY = 0;
    localparam BUSY = 1;
    //localparam MODE = [3:2];
    //localparam PRESCALER = 6:4;
    localparam SLEEP = 7;

    logic [7:0] spi_csr;

    logic [7:0] spi_data_reg;
    logic [7:0] spi_data_read;
    logic spi_data_ncsr;

    logic spi_clk;
    logic [6:0] clk_prescaler_counter;
    logic spi_req;
    logic spi_start;
    logic spi_ready;
    
    

    //APB controller
enum int {IDLE,ACCESS} thisState, nextState;

assign pslverr = 1'b0;

assign spi_data_ncsr = (paddr == 4); //0 - csr 1 - data

always_comb begin : apbNextStateLogic

	nextState = thisState;
	
	unique case(thisState)
	
		IDLE : if(psel && !penable) nextState =  ACCESS; 
		ACCESS : if(psel && penable && pready) nextState = IDLE;
		
	endcase
		
end

always_ff @(posedge pclk or negedge presetn) begin : apbNextStateFSM
	
	if(!presetn) begin
		thisState <= IDLE;

	end
	else begin 
		thisState <= nextState;
	end
end : apbNextStateFSM

always_comb	begin	:	apbTransferDataLogic

        
		unique case(thisState)
		
			IDLE	:	begin
				prdata	=	32'h0;
				pready	=	1'b0;
			end
		
			ACCESS	:	begin 
                prdata  =   pwrite ? 32'h0 : (spi_data_ncsr ? ( { {24{1'b0}}, spi_data_reg} ) : ( { {24{1'b0}},spi_csr} ));
				pready	=	1'b1;
			end
			
			default	:	begin
			
				prdata	=	32'h0;
				pready	=	1'b0;
				
			end
		
		endcase
end


    //SPI logic

    always_ff @(posedge clk_i or negedge reset_i) begin : clkPrescalerCnt
        if(~reset_i) clk_prescaler_counter <= 0;
        else begin
            clk_prescaler_counter <= clk_prescaler_counter + 1;
        end
    end

    always_comb begin : clkPrescalerSelect
        case(spi_csr[6:4])
            0: spi_clk = clk_i; //1
            1: spi_clk = clk_prescaler_counter[0]; //2
            2: spi_clk = clk_prescaler_counter[1]; //4
            3: spi_clk = clk_prescaler_counter[2]; //8
            4: spi_clk = clk_prescaler_counter[3]; //16
            5: spi_clk = clk_prescaler_counter[4]; //32 
            6: spi_clk = clk_prescaler_counter[5]; //64
            7: spi_clk = clk_prescaler_counter[6]; //128
        endcase
    end

    always_ff @( posedge clk_i or negedge reset_i ) begin : csrUpdate
        if(~reset_i) spi_csr <= 0;
        else if((thisState == ACCESS) && pwrite && ~spi_data_ncsr) begin
            spi_csr <= pwdata;
        end
        else begin
            if(spi_ready) spi_csr[READY] <= ~spi_req;

            if(spi_req) spi_csr[BUSY] <= 1'b1;
            else if(spi_ready) spi_csr[BUSY] <= 1'b0;
        end
    end

    //assign spi_req = ((thisState == ACCESS) && pwrite && spi_data_ncsr && spi_ready);

    always_ff @( posedge clk_i or negedge reset_i ) begin : dataRegUpdate
        if(~reset_i) begin 
            spi_data_reg <= 0;
            spi_req <= 1'b0;
        end
        else if((thisState == ACCESS) && pwrite && spi_data_ncsr && spi_ready) begin 
            spi_data_reg <= pwdata;
            spi_req <= 1'b1;
        end
        else begin
            if(spi_ready && ~spi_req && ~spi_start) spi_data_reg <= spi_data_read; //use this case ONCE, to start
            spi_req <= 1'b0; //Is 1 clock pulse enough for req?
        end
    end

    always_ff @( posedge clk_i or negedge reset_i ) begin : ssnUpdate 
        if(~reset_i) ssn_o <= 1'b1;
        else begin
            if(spi_start) ssn_o <= 1'b0;
            else if(spi_ready) ssn_o <= 1'b1;
        end
    end

    //CHANGE THIS
    /*
    always_ff @( posedge spi_req or negedge spi_ready or negedge reset_i ) begin : spiReqUpdate
        if(~reset_i) spi_start <= 1'b0;
        else if(spi_req) spi_start <= 1'b1;
        else if(~spi_ready) spi_start <= 1'b0;
        
    end
*/
    always_ff @( posedge clk_i or negedge reset_i ) begin : spiReqUpdate
        if(~reset_i) spi_start <= 1'b0;
        else if(spi_req) spi_start <= 1'b1;
        else if(~spi_ready) spi_start <= 1'b0;
    end

    spi_master  #(
			.SPI_MODE(0)
        ) SPI_DATA (

        .clk_i(clk_i),
        .spi_clk_i(spi_clk),
        .reset_i(reset_i),

        .tx_data_valid_i(spi_start),
        .tx_data_i(spi_data_reg),
        .rx_data_o(spi_data_read),
        .tx_ready_o(spi_ready),

        //.mode_i(spi_csr[3:2]),
        .mode_i(2'b00),
        .miso_i(miso_i),
        .mosi_o(mosi_o),
        .sck_o(sck_o)
        
    );
    
endmodule



module apb_uart #(
    
    parameter DATA_WIDTH = 32

    )(
    
    //Common signals
    input									clk_i,
	input									reset_i,
	
    //APB
	input									pclk,
	input									presetn,
	input		[3:0]			            paddr,
	input									psel,
	input									penable,
	input									pwrite,
	input		[DATA_WIDTH-1:0]			pwdata,
	output reg								pready,
	output reg	[DATA_WIDTH-1:0]			prdata,
	output reg								pslverr,

    //UART
    input                                   uart_rx,
    output reg                              uart_tx
);


logic data_sel;
logic baud_sel;
logic cpu_wr;
logic cpu_rd;
logic [DATA_WIDTH-1:0] uart_rdata;


assign pslverr	= 1'b0;

assign data_sel = (paddr == 4'h0);
assign baud_sel = (paddr == 4'h4);  

assign cpu_wr = psel & penable & pwrite;
assign cpu_rd = psel & penable & ~pwrite;

micro_uart UART(
    .clk(clk_i),
    .reset_n(reset_i),
    .data_select(data_sel),
    .baud_select(baud_sel),
    .cpu_read(cpu_rd),
    .cpu_write(cpu_wr),
    .cpu_wdata(pwdata[15:0]),
    .cpu_rdata(uart_rdata[15:0]),
    .ser_in(uart_rx),
    .ser_out(uart_tx)
);

enum int {IDLE,ACCESS} thisState, nextState;


always_comb begin : apbNextStateLogic

	nextState = thisState;
	
	unique case(thisState)
	
		IDLE : if(psel && !penable) nextState =  ACCESS; 
		ACCESS : if(psel && penable && pready) nextState = IDLE;
		
	endcase
		
end : apbNextStateLogic	

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
                prdata  =   cpu_rd ? uart_rdata : 32'h00000000;
				pready	=	1'b1;
			end
			
			default	:	begin
			
				prdata	=	32'h0;
				pready	=	1'b0;
				
			end
		
		endcase
end	:	apbTransferDataLogic

	



endmodule
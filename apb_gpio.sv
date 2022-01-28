
//NOTE: Clear old SETUP state

module apb_gpio#(

	parameter ADDRESS_WIDTH = 5,
	parameter DATA_WIDTH = 32
)(
	input									clk_i,
	input									reset_i,
	
	//apb_slave_int					APB,
	
	input									pclk,
	input									presetn,
	input		[ADDRESS_WIDTH-1:0]			paddr,
	input									psel,
	input									penable,
	input									pwrite,
	input		[DATA_WIDTH-1:0]			pwdata,
	output reg								pready,
	output reg	[DATA_WIDTH-1:0]			prdata,
	output reg								pslverr,
	
	input		[DATA_WIDTH-1:0]			gpio_i,
	output reg	[DATA_WIDTH-1:0]			gpio_o,
	output reg	[DATA_WIDTH-1:0]			gpio_oe,
	output reg								irq_o
);

//apb_slave_int	APB(.pclk_i(clk_i), .presetn_i(resetn_i));

//GPIO control and status registers

enum	{DIR_REG_ADR = 32'h00, OUT_REG_ADR = 32'h04, IN_REG_ADR = 32'h08, 
		IRQ_EN_REG_ADR = 32'h0C, IRQ_TRIG_REG_ADR = 32'h10, IRQ_STAT_REG_ADR = 32'h14} regAddress;


/*				
logic	[DATA_WIDTH-1:0]	gpio_regs[(ADDRESS_WIDTH*ADDRESS_WIDTH)-1:0];
*/
//Or like this

logic [DATA_WIDTH-1:0]	dir_reg,
								out_reg,
								in_reg,
								irq_en_reg,
								irq_trig_reg,
								irq_stat_reg;


//APB slave state machine
enum int {IDLE, SETUP, ACCESS} thisState, nextState;

logic 							bus_rw;
logic 							bus_we;

logic								irq_status_we;
logic	[DATA_WIDTH-1:0]		irq_status_data;
logic [DATA_WIDTH-1:0]		trig_falling;
logic	[DATA_WIDTH-1:0]		trig_rising;
logic	[DATA_WIDTH-1:0]		trig_previous;

always_comb begin : apbNextStateLogic
	
	//By default stay in the same state
	nextState = thisState;
	
	unique case(thisState)
	
		IDLE : if(psel && !penable) nextState = /*SETUP*/ ACCESS; 
		SETUP : begin
			nextState = ACCESS;
		end
		
		ACCESS : if(psel && penable && pready) nextState = IDLE;
		
	endcase
		
end : apbNextStateLogic	

always_ff @(posedge pclk or negedge presetn) begin : apbNextStateFSM
	
	if(!presetn) begin
		thisState <= IDLE;
		bus_rw <= 1'b0;
	end
	else begin 
		thisState <= nextState;
		//Read/Write has to be specified in IDLE phase when slave is activated
		if((thisState == IDLE) && psel && !penable) bus_rw <= pwrite; 
	end
end : apbNextStateFSM

always_comb	begin	:	apbTransferDataLogic

		unique case(thisState)
		
			IDLE	:	begin
				prdata	=	32'h0;
				pready	=	1'b0;
				bus_we	=	1'b0;
			end
			
			SETUP	:	begin
				prdata	=	32'h0;
				pready	=	1'b0;
				bus_we	=	1'b0;
			end
			
			ACCESS	:	begin
			
				pready	=	1'b1;
				bus_we	=	1'b1;
				if(!bus_rw)	begin
					
					case(paddr)
					
						DIR_REG_ADR			:	prdata	=	dir_reg;
						OUT_REG_ADR			:	prdata	=	out_reg;
						IN_REG_ADR			:	prdata	=	in_reg;
						IRQ_EN_REG_ADR		:	prdata	=	irq_en_reg;
						IRQ_TRIG_REG_ADR	:	prdata	=	irq_trig_reg;
						IRQ_STAT_REG_ADR	:	prdata	=	irq_stat_reg;
							
						default				:	prdata	=	32'h0;
						
					endcase
				end
				else prdata	=	32'h0;
			end
			
			default	:	begin
			
				prdata	=	32'h0;
				pready	=	1'b0;
				bus_we = 1'b0;
				
			end
		
		endcase
end	:	apbTransferDataLogic

	

assign pslverr	=		1'b0;


//GPIO logic
always_ff @(posedge clk_i or negedge reset_i) begin : gpioLogic
	
	if(!reset_i) begin

		irq_o <= 1'b0;
		
		dir_reg			<= 32'h0; 
		out_reg			<= 32'h0;
		in_reg			<= 32'h0;
		irq_en_reg		<= 32'h0;
		irq_trig_reg	<= 32'h0;
		irq_stat_reg	<= 32'h0;
		
		trig_falling	<=	32'h0;
		trig_rising		<=	32'h0;
		trig_previous	<=	32'h0;
		
		
		irq_status_data	<=	32'h0;
		irq_status_we		<=	1'b0;
		
	end
	else begin
		
		if(bus_rw && bus_we) begin
			case(paddr)
			
				DIR_REG_ADR			:	dir_reg			<=	pwdata;
				OUT_REG_ADR			:	out_reg			<=	pwdata;
				IN_REG_ADR			:	in_reg			<=	pwdata;
				IRQ_EN_REG_ADR		:	irq_en_reg		<=	pwdata;
				IRQ_TRIG_REG_ADR	:	irq_trig_reg	<=	pwdata;
				IRQ_STAT_REG_ADR	:	begin
						irq_status_we 	<= 1'b1; 
						irq_status_data <= pwdata;
					end
	
			endcase
		end
		
		in_reg			<= gpio_i;
		
		//Edge detection
		trig_previous	<=	in_reg;
		trig_falling	<=	trig_previous	&	~in_reg;
		trig_rising		<=	~trig_previous	&	in_reg;
		
		
		if(irq_status_we) begin
			irq_stat_reg	<=	irq_status_data;
			irq_status_we	<=	1'b0;
		end
		else begin
			for(int i=0; i<DATA_WIDTH; i=i+1)
			/*
			irq_stat_reg[i]	 <=	((trig_falling[i]	&	~irq_trig_reg[i]) |
								(trig_rising[i]	&	irq_trig_reg[i]));
								*/
			if((trig_falling[i]	&	~irq_trig_reg[i]) |
			(trig_rising[i]	&	irq_trig_reg[i])) irq_stat_reg[i]	<=	1'b1;
		end
		
		//If selected edge was detected and trigger interrupt was enabled, irq_o = 1
		irq_o				<=	|(irq_en_reg	&	irq_stat_reg);
		
		//irq_en 1 - enabled, 0 - disabled
		//irq_trig 1 - rising, 0 - falling
		//irq_stat - 1 - irq occured, 0 - no irq. Write 1 to clear
	end

end : gpioLogic	
/*
always_comb	begin	:	irqLogic
 
//Update trigger status register if selected edge was present on a specific pin
 for(int i=0; i<DATA_WIDTH; i=i+1)
	//This needs to be made more permament. If another edge occurs, 
	//the status bit will disappear
	irq_stat_reg[i]	=	((trig_falling[i]	&	~irq_trig_reg[i]) |
								(trig_rising[i]	&	irq_trig_reg[i]));
end	:	irqLogic
*/
assign gpio_oe = 	dir_reg;
assign gpio_o	=	out_reg;

endmodule
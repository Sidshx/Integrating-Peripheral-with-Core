module wb_pwmaudio (i_clk, i_rst, // clock and reset
i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, // Wishbone interface input signals
o_wb_ack, o_wb_stall, o_wb_data, // Wishbone interface output signals
o_pwm, o_aux, o_int) ; 

parameter DEFAULT_RELOAD = 16'd2268, // For a 100MHz clk generating a 44.1KHz audio stream by reading in a new sample every (100e6/44.1e3) 2268 samples.
NAUX=2, VARIABLE_RATE=0, TIMING_BITS=16; // Device control values
			 
input	wire i_clk, i_rst;
input	wire i_wb_cyc, i_wb_stb, i_wb_we;
input	wire i_wb_addr;
input	wire [31:0] i_wb_data;
output reg o_wb_ack;
output wire o_wb_stall;
output wire	[31:0] o_wb_data;
output reg o_pwm;
output reg [(NAUX-1):0]	o_aux;
output wire o_int;

wire [(TIMING_BITS-1):0] w_reload_value;  // To create interrupts every time reload_value clocks
generate
if (VARIABLE_RATE != 0)
begin

reg [(TIMING_BITS-1):0]	r_reload_value;
initial	r_reload_value = DEFAULT_RELOAD;

always @(posedge i_clk)		// data write
if ((i_wb_stb)&&(i_wb_addr)&&(i_wb_we))		
r_reload_value <= i_wb_data[(TIMING_BITS-1):0] - 1'b1;

assign	w_reload_value = r_reload_value;
end else begin
assign	w_reload_value = DEFAULT_RELOAD;
end endgenerate

// to create a timer for indicating the next value

reg ztimer;   // zero timer
reg [(TIMING_BITS-1):0] timer;
initial timer = DEFAULT_RELOAD;
initial ztimer =1'b0;

always@(posedge i_clk)
	if (i_rst)
		ztimer <= 1'b0;
	else
		ztimer <= (timer=={ {(TIMING_BITS-1){1'b0}},1'b1});
		
reg [15:0] sample_out;
always@(posedge i_clk)	// for accepting the next sample when the ztimer runs out
	if (ztimer==1)
	begin
		sample_out <= next_sample;
	end
		
reg [15:0] next_sample;
reg next_valid;
initial next_valid=1'b1;
initial next_sample=16'h8000;

always@(posedge i_clk)
	if ((i_wb_stb)&&(i_wb_we)&&((!i_wb_addr)||(VARIABLE_RATE==0)))		// Data write
		begin
		next_sample <= { !i_wb_data[15], i_wb_data[14:0] };
		next_valid <= 1'b1;
		if (i_wb_data[16])
			o_aux <= i_wb_data[(NAUX+20-1):20];
		end else if (ztimer)
			next_valid <= 1'b0;

assign o_int = (!next_valid);		// sends an interrupt to the processor, to know when to send a new sample

reg [15:0] pwm_counter;
initial pwm_counter = 16'h00;
always @(posedge i_clk)
	if (i_rst)
	pwm_counter <= 16'h0;
	else
	pwm_counter <= pwm_counter + 16'h01;
	
	
wire [15:0]	br_counter;
genvar k;
generate for(k=0; k<16; k=k+1)
begin : bit_reversal_loop
assign br_counter[k] = pwm_counter[15-k];
end endgenerate

always@(posedge i_clk)
	o_pwm <= (sample_out >= br_counter);
	
generate 
if (VARIABLE_RATE == 0)
begin
assign o_wb_data = { {(12-NAUX){1'b0}}, o_aux, 3'h0, o_int, sample_out };

end else 
begin
reg [31:0] r_wb_data;

always @(posedge i_clk)
if (i_wb_addr)
r_wb_data <= { (32-TIMING_BITS),w_reload_value};
else
r_wb_data <= { {(12-NAUX){1'b0}}, o_aux, 3'h0, o_int, sample_out };

assign	o_wb_data = r_wb_data;
end endgenerate

initial o_wb_ack = 1'b0;	// always ack on the clock following any request
always @(posedge i_clk)
o_wb_ack <= (i_wb_stb);

assign	o_wb_stall = 1'b0;	// does not stall the process

wire	[14:0] unused;
assign	unused = { i_wb_cyc, i_wb_data[31:21], i_wb_data[19:17] };

endmodule



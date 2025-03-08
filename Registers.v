module Registers ( input clk, write_enable,
						 input [2:0]write_address,
						 input [15:0]write_data,
						 input [2:0]read_address_1,
						 output [15:0]read_data_1,
						 input [2:0]read_address_2,
						 output [15:0]read_data_2 );
	
	reg [15:0] mem[8:0];
	integer i;
	initial begin
		for ( i=0; i<8; i=i+1 ) begin
			mem[i] = 0;
		end
	end
	
	always @ ( posedge clk ) begin
		if ( write_enable ) 
			mem[ write_address ] <= write_data;
	end
	
	assign read_data_1 = mem[ read_address_1 ];
	assign read_data_2 = mem[ read_address_2 ];
	
	wire [15:0]wr0; wire [15:0]wr1; wire [15:0]wr2; wire [15:0]wr3; wire [15:0]wr4;
	assign wr0 = mem[0];
	assign wr1 = mem[1];
	assign wr2 = mem[2];
	assign wr3 = mem[3];
	assign wr4 = mem[4];
	
endmodule
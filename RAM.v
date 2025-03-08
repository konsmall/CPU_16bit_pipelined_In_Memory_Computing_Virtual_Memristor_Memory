module RAM ( input clk, input write_enable,
				 input [6:0]pc_address,
				 input [6:0]data_address,
				 input [15:0]write_data,
				 output [15:0]pc_read_data,
				 output reg [15:0]data_read_data );
				 
	reg [15:0] mem[128:0];
	integer i;
	initial begin
		for ( i=0; i<128; i=i+1 ) begin
			mem[i] = 65535;
		end
		
		mem[0] = 16'b1000000000011101;
		mem[1] = 16'b1000010000011110;
		mem[2] = 16'b0100000010000000;
		mem[3] = 16'b0100010000000000;
		mem[4] = 16'b0110110000000001;
		mem[5] = 16'b0111000000000000;
		mem[6] = 16'b0010010010000010;
		mem[7] = 16'b0010000010100010;
		
		mem[29] = 22;
		mem[30] = 33;
		
		/*mem[0] = 16'b1000000000011101;
		mem[1] = 16'b1000010000011101;
		mem[2] = 16'b1000100000011101;
		mem[3] = 16'b1000110000011110;
		
		mem[4] = 16'b0000000010000000;
		mem[5] = 16'b0000000010000001;
		mem[6] = 16'b0000110100001011;
		mem[7] = 16'b1101000110001001;
		mem[8] = 16'b1100000000000100;
		
		mem[9] = 16'b1100000000001001;
		
		mem[29] = 1;
		mem[30] = 2;*/
		
		/*mem[0] = 16'b1000000000011101;
		mem[1] = 16'b1000010000011110;
		mem[2] = 16'b1000100000011110;
		mem[3] = 16'b0000000100000010;
		mem[4] = 16'b0000000000000001;
		mem[5] = 16'b1100000000000000;
		mem[6] = 16'b1000000000011110;
		mem[7] = 16'b1000010000011101;
		
		mem[29] = 2;
		mem[30] = 3;*/
	end
	
	always@(posedge clk) begin
		if ( write_enable ) begin
			mem[data_address] <= write_data;
		end
	end
	
	always@(posedge clk) begin
		data_read_data <= mem[data_address];
	end
	
	assign pc_read_data = mem[pc_address];
	
	wire [15:0]wr0; wire [15:0]wr1; wire [15:0]wr2;
	assign wr0 = mem[31];
		 
endmodule
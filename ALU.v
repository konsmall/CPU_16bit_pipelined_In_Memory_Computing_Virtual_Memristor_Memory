module ALU ( input [2:0]alu_control,
				 input [15:0]input_A,
				 input [15:0]input_B,
				 output zero,
				 output equal,
				 output reg [15:0] result );
				 
always @(*)
	begin
		case( alu_control )
			3'b000: result = input_A + input_B; // add
			3'b001: result = input_A - input_B; // sub
			3'b010: result = ~input_A;
			3'b011: result = input_A<<input_B;
			3'b100: result = input_A>>input_B;
			3'b101: result = input_A & input_B; // and
			3'b110: result = input_A | input_B; // or
			3'b111: begin 
				if (input_A<input_B) result = 16'd1;
					else result = 16'd0;
			end
		endcase
	end
			
	assign zero = ( result == 0 )? 1'b1: 1'b0;
	assign equal = ( input_A == input_B )? 1'b1: 1'b0;
		
endmodule
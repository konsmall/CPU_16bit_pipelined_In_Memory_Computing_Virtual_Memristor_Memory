module MEM_CONTROLLER_V2 ( input clk,
						input [15:0]instruction,
						input [7:0]in_data,
						input [7:0]in_buffer_data,
						output reg [7:0]out_data_sel_1,
						output reg [7:0]out_data_sel_2,
						output reg [7:0]control,
						output reg [7:0]word,
						output reg read_or_gate,
						output reg and_gate, 
						output reg xor_gate,
						output reg STALL );
	
	integer i;
	wire [2:0]opcode = instruction[15:13];
	wire [2:0]mem_address_A = instruction[12:10];
	wire [2:0]mem_address_B = instruction[9:7];
	wire [1:0]ram_reg_sel = instruction[6:5];
	wire [1:0]gate_select = instruction[4:3];
	wire [2:0]mem_address_C = instruction[2:0];
	
	reg [2:0]STEP;
	reg [7:0]buffer;
	
	
	initial begin
		STEP <=0;
		buffer  <=0;
		
		out_data_sel_1 <=0;
		out_data_sel_2 <=0;
		control <=0;
		word <=0;
		read_or_gate <=0;
		and_gate <=0;
		xor_gate <=0;
	end
	
	
	always @(*) begin // STALL
		buffer = in_buffer_data;
		STALL = 0;
	
		if ( opcode == 3'b001 && ram_reg_sel == 1 && STEP != 2 ) 
			STALL = 1;
	end
	
	
	always @ (posedge clk) begin // STEP 
		if ( opcode == 3'b001 && ram_reg_sel == 1 && STEP == 0 )  begin
			STEP <= 1;
		end else if ( STEP == 1 ) begin
			STEP <= 2;
		end else if ( STEP == 2 ) begin
			STEP <= 0;
		end else if ( STEP == 3 ) begin
			STEP <= 0;
		end
	end
	
	always @(posedge clk) begin // CONTROL signal
		control <= 0;
		
		if ( opcode == 3'b010 ) begin // Turn on MOS of word being selected
			control[ mem_address_A ] <= 1;
		end else if ( opcode == 3'b011 ) begin
			control[ mem_address_C ] <= 1;
		end
		
		if ( opcode == 3'b001 && STEP == 0 ) begin
			control[ mem_address_A ] <= 1;
			control[ mem_address_B ] <= 1;
		end else if ( STEP == 2 ) begin
			control[ mem_address_C ] <= 1;
		end
	end
	
	always @ (posedge clk) begin // WORD signal
		word <= 0; // DEFAULT WORD signal
		
		if ( opcode == 3'b011 ) begin // READ WORD changes to '1' if performing read or a gate
			word[ mem_address_C ] <= 1;
		end
		
		if ( opcode == 3'b001 && STEP == 0 ) begin // GATE WORD changes to '1' if performing read or a gate
			word[ mem_address_A ] <= 1;
			word[ mem_address_B ] <= 1;
		end
	end
	
	always @(*) begin // !!!!!SOS!!!!! REQUIRED OR ELSE DATA WONT BE PASSED TO (1)*
		buffer = in_buffer_data;
	end
	always @ (posedge clk) begin // OUT DATA signal
		out_data_sel_1 <= 0;
		out_data_sel_2 <= 0;
		
		if ( opcode == 3'b010 ) begin // passing elements normally
			out_data_sel_2 <= 255;
			if ( opcode == 3'b010) out_data_sel_1 <= in_data;
		end
		if ( STEP == 2 ) begin 
			out_data_sel_2 <= 255;
			out_data_sel_1 <= buffer; //(1)*
		end
	end
	
	
	always @ (posedge clk) begin // READ OR AND XOR signal
		read_or_gate <= 0;
		and_gate <= 0;
		xor_gate <= 0;
		
		if ( (opcode == 3'b011 || (opcode == 3'b001 && gate_select == 2'b00)) && STEP == 0 ) begin //PLACEHOLDER READ / OR
			read_or_gate <= 1;
		end
		
		if ( opcode == 3'b001 && gate_select == 2'b01 && STEP == 0 ) begin //PLACEHOLDER AND
			read_or_gate <= 1;
			and_gate <= 1;
		end
		
		if ( opcode == 3'b001 && gate_select == 2'b10 && STEP == 0 ) begin //PLACEHOLDER XOR
			xor_gate <= 1;
		end
	end
		 
endmodule



module VIRTUAL_REMEM ( 	input clk,
						input [7:0]bit_data_sel_1,
						input [7:0]bit_data_sel_2,
						input [7:0]control,
						input [7:0]word,
						input read_or_gate,
						input and_gate, 
						input xor_gate,
						output reg [7:0]data	);
	
	integer i;
	integer j;
	
	reg [7:0] mem[7:0];
	reg wrd_flg;
	reg [7:0] word_1;
	reg [7:0] word_2;
	
	initial begin
		for ( i=0; i<8; i=i+1 ) begin
			mem[i] <= 0;
		end
		wrd_flg = 0;
	end
	
	always @ (posedge clk) begin
		if ( bit_data_sel_2 == 255 ) begin
			for ( i=0; i<8; i=i+1 ) begin
				if ( control[i] == 1 && word[i] == 0 ) begin
					for ( j=0; j<8; j=j+1 ) begin					
						if ( bit_data_sel_1[j] == 1 ) mem[i][j] <= 1;
						else mem[i][j] <= 0;
					end
				end
			end
		end
	end
	
	always @(*) begin
		word_1 = 0;
		word_2 = 0;
	
		if ( bit_data_sel_2 == 0 ) begin
			for ( i=0; i<8; i=i+1 ) begin
				if ( control[i] == 1 && word[i] == 1 ) begin
					if ( wrd_flg == 0 ) begin
						word_1 = mem[i];
						wrd_flg = 1;
					end else begin
						word_2 = mem[i];
						wrd_flg = 0;
					end
				end
			end
		end
		
		wrd_flg = 0;
	end
	
	always @(posedge clk) begin
		data = 0;
	
		if ( read_or_gate && !and_gate ) begin
			data <= word_1 | word_2;
		end else if ( read_or_gate && and_gate ) begin
			data <= word_1 & word_2;
		end else if ( xor_gate ) begin
			data <= word_1 ^ word_2;
		end
	end
	
	wire [7:0]wr0; wire [7:0]wr1; wire [7:0]wr2; wire [7:0]wr3; wire [7:0]wr4; wire [7:0]wr5; wire [7:0]wr6; wire [7:0]wr7;
	assign wr0 = mem[0];
	assign wr1 = mem[1];
	assign wr2 = mem[2];
	assign wr3 = mem[3];
	assign wr4 = mem[4];
	assign wr5 = mem[5];
	assign wr6 = mem[6];
	assign wr7 = mem[7];
	
endmodule




module MEM_CONTROLLER_V3 ( input clk,
						input [15:0]instruction,
						input [7:0]in_data,
						input [7:0]in_buffer_data,
						output reg [7:0]out_data_sel_1,
						output reg [7:0]out_data_sel_2,
						output reg [7:0]control,
						output reg [7:0]word,
						output reg read_or_gate,
						output reg and_gate, 
						output reg xor_gate,
						output reg STALL );
	
	integer i;
	
	reg [15:0]reg_instruction;
	reg [7:0]reg_in_data;
	reg ONE_STEP_GATE_PROC;
	
	
	initial begin
		reg_instruction <= 0;
		reg_in_data <= 0;
	
		ONE_STEP_GATE_PROC <=0;
		
		out_data_sel_1 <=0;
		out_data_sel_2 <=0;
		control <=0;
		word <=0;
		read_or_gate <=0;
		and_gate <=0;
		xor_gate <=0;
	end
	
	always @(posedge clk) begin
		if ( !STALL ) begin
			reg_instruction <= instruction;
			reg_in_data <= in_data;
		end
	end
	
	
	wire [2:0]opcode = reg_instruction[15:13];
	wire [2:0]mem_address_A = reg_instruction[12:10];
	wire [2:0]mem_address_B = reg_instruction[9:7];
	wire [1:0]ram_reg_sel = reg_instruction[6:5];
	wire [1:0]gate_select = reg_instruction[4:3];
	wire [2:0]mem_address_C = reg_instruction[2:0];
	
	
	always @(*) begin // STALL
		STALL = 0;
	
		if ( opcode == 3'b001 && ram_reg_sel == 1 && ONE_STEP_GATE_PROC != 1 ) 
			STALL = 1;
	end
	
	
	always @ (posedge clk) begin // STEP 
		if ( opcode == 3'b001 && ram_reg_sel == 1 && ONE_STEP_GATE_PROC == 0 )  begin
			ONE_STEP_GATE_PROC <= 1;
			//buffer <= in_buffer_data; //$urandom_range(255,0);
		end else if ( ONE_STEP_GATE_PROC == 1 ) begin
			ONE_STEP_GATE_PROC <= 0;
			//buffer <= in_buffer_data;
		end
	end
	
	always @(*) begin // CONTROL signal
		control = 0;
		
		if ( opcode == 3'b010 ) begin // Turn on MOS of word being selected
			control[ mem_address_A ] = 1;
		end else if ( opcode == 3'b011 ) begin
			control[ mem_address_C ] = 1;
		end
		
		if ( opcode == 3'b001 && ONE_STEP_GATE_PROC == 0 ) begin
			control[ mem_address_A ] = 1;
			control[ mem_address_B ] = 1;
		end else if ( ONE_STEP_GATE_PROC == 1 ) begin
			control[ mem_address_C ] = 1;
		end
	end
	
	always @ (*) begin // WORD signal
		word = 0; // DEFAULT WORD signal
		
		if ( opcode == 3'b011 ) begin // READ WORD changes to '1' if performing read or a gate
			word[ mem_address_C ] = 1;
		end
		
		if ( opcode == 3'b001 && ONE_STEP_GATE_PROC != 1 ) begin // GATE WORD changes to '1' if performing read or a gate
			word[ mem_address_A ] = 1;
			word[ mem_address_B ] = 1;
		end
	end
	
	always @ (*) begin // OUT DATA signal
		out_data_sel_1 = 0;
		out_data_sel_2 = 0;
		
		if ( opcode == 3'b010 || ONE_STEP_GATE_PROC == 1 ) begin // passing elements normally
			out_data_sel_2 = 255;
			for ( i = 0; i < 8; i = i+1 ) begin
				if ( opcode == 3'b010 && reg_in_data[i] == 1 ) out_data_sel_1[i] = 1;
				if ( ONE_STEP_GATE_PROC == 1 && in_buffer_data[i] == 1 ) out_data_sel_1[i] = 1;
			end
		end
	end
	
	always @ (*) begin // READ OR AND XOR signal
		read_or_gate = 0;
		and_gate = 0;
		xor_gate = 0;
		
		if ( (opcode == 3'b011 || (opcode == 3'b001 && gate_select == 2'b00)) && ONE_STEP_GATE_PROC == 0 ) begin //PLACEHOLDER READ / OR
			read_or_gate = 1;
		end
		
		if ( opcode == 3'b001 && gate_select == 2'b01 && ONE_STEP_GATE_PROC == 0 ) begin //PLACEHOLDER AND
			read_or_gate = 1;
			and_gate = 1;
		end
		
		if ( opcode == 3'b001 && gate_select == 2'b10 && ONE_STEP_GATE_PROC == 0 ) begin //PLACEHOLDER XOR
			xor_gate = 1;
		end
	end
		 
endmodule
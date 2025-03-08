`include "ALU.v"
`include "RAM.v"
`include "Registers.v"
`include "Virtual_memristor_memory.v"


module Data_path ( input clk,
						 input reg_write_en, ram_write_en, ram_read_en, PC_jump,
						 input [2:0] alu_control,
						 output [2:0]opcode,
						 output [2:0]alu_decode );
						 
	reg [6:0]PC;
	wire[15:0]PC_INSTRUCTION;
	wire PC_JUMP;
	wire [6:0]PC_JUMP_DESTINATION;
	
	reg [15:0]IR_D;
	reg [15:0]IR_E;
	reg [15:0]IR_M;
	reg [15:0]IR_W;
	reg [15:0]D;
	reg [15:0]E[4:0];
	reg [15:0]M[3:0];
	reg [15:0]W;
	reg [15:0]W_TO_REG_DATA;
	reg STALL;
	reg [1:0]STALL_COUNT;
	reg [1:0]STALL_COUNT_MAX;
	
	wire reg_write_enable;
	wire [2:0]reg_write_address;
	wire [15:0]reg_write_data;
	wire [2:0]reg_address_1;
	wire [15:0]reg_data_1;
	wire [2:0]reg_address_2;
	wire [15:0]reg_data_2;
	
	wire[15:0] D_ram_address;
	wire[15:0] E_ram_address;
	wire[15:0] M_ram_address;
	//wire[15:0] D_ram_data; //same as reg_data_1
	//wire[15:0] E_ram_data;
	//wire[15:0] M_ram_data;
	
	wire[15:0] ALU_A;
	wire[15:0] ALU_B;
	wire[15:0] ALU_RESULT;
	wire[2:0] ALU_CONTROL;
	wire ALU_EQUAL;
	
	wire[6:0]RAM_ADDRESS;
	wire[15:0]RAM_WRITE_DATA;
	wire[15:0]RAM_READ_DATA;
	wire RAM_WRITE_ENABLE;
	wire RAM_OR_ALU_DATA_TO_REG_SEL;
	
	wire [7:0]REMEM_OUT_DATA_SEL_1;
	wire [7:0]REMEM_OUT_DATA_SEL_2;
	wire [7:0]REMEM_CONTROL;
	wire [7:0]REMEM_WORD;
	wire [7:0]REMEM_DATA;
	wire REMEM_READ_OR_GATE;
	wire REMEM_AND_GATE; 
	wire REMEM_XOR_GATE;
	wire REMEM_STALL;
	wire REMEM_DATA_TO_REG_SEL;
	

	//assign STALL = 0; // PLACEHOLDER, HAS TO CHANGE!!!!
	initial begin
		STALL = 0;
		STALL_COUNT = 0;
		STALL_COUNT_MAX = 0;
	end
	always @ (posedge clk) begin
		if ( STALL == 1 && STALL_COUNT < 3 )
			STALL_COUNT = STALL_COUNT + 1;
		else 
			STALL_COUNT = 0;
	end
	always @(*) begin
		STALL <= 0;
		STALL_COUNT_MAX <= 0;
	
		if ( IR_D[15:13] == 3'b000 || IR_D[15:13] == 3'b101 || IR_D[15:13] == 3'b110 || IR_D[15:13] == 3'b010 ) begin
			if ( IR_E[15:13] == 3'b100 || IR_M[15:13] == 3'b100 || IR_W[15:13] == 3'b100  ||  IR_E[15:13] == 3'b011 || IR_M[15:13] == 3'b011 || IR_W[15:13] == 3'b011 ) begin
				if ( IR_D[12:10] == IR_E[12:10] || IR_D[12:10] == IR_M[12:10] || IR_D[12:10] == IR_W[12:10] || IR_D[9:7] == IR_E[12:10] || IR_D[9:7] == IR_M[12:10] || IR_D[9:7] == IR_W[12:10] ) begin
					STALL <= 1;
					STALL_COUNT_MAX <= 2;
				end
			end
			
			if ( IR_E[15:13] == 3'b000 || IR_M[15:13] == 3'b000 || IR_W[15:13] == 3'b000 ) begin
				if ( IR_D[12:10] == IR_E[2:0] || IR_D[12:10] == IR_M[2:0] || IR_D[12:10] == IR_W[2:0] || IR_D[9:7] == IR_E[2:0] || IR_D[9:7] == IR_M[2:0] || IR_D[9:7] == IR_W[2:0] ) begin
					STALL <= 1;
					STALL_COUNT_MAX <= 1;
				end
			end
		end
		
		if ( REMEM_STALL ) begin // <-- NEEDS WORK
			STALL <= 1;
		end
		
		if ( STALL_COUNT == 3 )
			STALL <= 0;
	end
	
	always @ (posedge clk) begin
		if ( !STALL ) begin
			IR_D <= PC_INSTRUCTION;
			IR_E <= IR_D;
		end
		else begin
			IR_E <= 65535; //insert junk if we stall
		end
		IR_M <= IR_E; //if things go tits up move this below the if(PC_JUMP)
		if ( PC_JUMP ) begin
			IR_D <= 65535;
			IR_E <= 65535;
			//IR_M <= 65535;
		end
		//IR_E <= IR_D; //seems correct enough
		IR_W <= IR_M;
	end
	
	always @ (posedge clk) begin //E STAGE
		if ( !STALL ) begin
			E[0] <= reg_data_1;
			E[1] <= reg_data_2;
			E[2] <= reg_data_1;
			E[3] <= D_ram_address;
		end
	end
	
	always @ (posedge clk) begin //M STAGE
		if ( 1 ) begin
			M[0] <= ALU_RESULT;
			M[1] <= E[2];  //RAM DATA
			M[2] <= E[3];  //RAM ADDRESS
		end
	end
	
	always @ (posedge clk) begin //W STAGE
		W <= M[0];
	end
	
	always @ (*) begin //W TO REGISTER STAGE
		if ( 1 ) begin  //!!!!!!! PLACEHOLDER - NOT NEEDED?
			if ( REMEM_DATA_TO_REG_SEL ) begin
				W_TO_REG_DATA <= REMEM_DATA;
			end else if ( RAM_OR_ALU_DATA_TO_REG_SEL ) begin
				W_TO_REG_DATA <= RAM_READ_DATA;
			end	else begin
				W_TO_REG_DATA <= W;
			end
		end
	end
	
	initial begin
		PC <= 0;
	end
	always @ (posedge clk) begin
		if ( !STALL ) begin
			PC <= PC + 1;
		end 
		if ( PC_JUMP ) begin
			PC <= PC_JUMP_DESTINATION;
		end
	end
	
	RAM ram_1( .clk(clk), .write_enable( RAM_WRITE_ENABLE ),
				  .pc_address( PC ),
				  .data_address( RAM_ADDRESS ),
				  .write_data( RAM_WRITE_DATA ),
				  .pc_read_data( PC_INSTRUCTION ),
				  .data_read_data( RAM_READ_DATA ) );
	
	Registers reg_1( .clk(clk), .write_enable( reg_write_enable ),
						  .write_address( reg_write_address ),
						  .write_data( reg_write_data ),
						  .read_address_1( reg_address_1 ),
						  .read_data_1( reg_data_1 ),
						  .read_address_2( reg_address_2 ),
						  .read_data_2( reg_data_2 ) );
						  
	ALU alu_1( .alu_control( ALU_CONTROL ),
				  .input_A( ALU_A ),
				  .input_B( ALU_B ),
				  .zero(),
				  .equal(ALU_EQUAL),
				  .result( ALU_RESULT ) );
				  
	MEM_CONTROLLER_V3 mem_con_1 ( 	.clk(clk),
								.instruction( IR_E ),
								.in_data( E[1][7:0] ),
								.in_buffer_data( REMEM_DATA ),
								.out_data_sel_1( REMEM_OUT_DATA_SEL_1 ),
								.out_data_sel_2( REMEM_OUT_DATA_SEL_2 ),
								.control( REMEM_CONTROL ),
								.word (REMEM_WORD ),
								.read_or_gate( REMEM_READ_OR_GATE ),
								.and_gate( REMEM_AND_GATE ), 
								.xor_gate( REMEM_XOR_GATE ),
								.STALL( REMEM_STALL ) );	

	VIRTUAL_REMEM vir_mem_1	(  	.clk( clk ),
								.bit_data_sel_1( REMEM_OUT_DATA_SEL_1 ),
								.bit_data_sel_2( REMEM_OUT_DATA_SEL_2 ),
								.control( REMEM_CONTROL ),
								.word( REMEM_WORD ),
								.read_or_gate( REMEM_READ_OR_GATE ),
								.and_gate( REMEM_AND_GATE ), 
								.xor_gate( REMEM_XOR_GATE ),
								.data( REMEM_DATA )	);							
				  
	
	assign PC_JUMP = ( IR_E[15:13] == 3'b110 && ALU_EQUAL ) ? 1'b1 : 1'b0;
	assign PC_JUMP_DESTINATION = IR_E[6:0];
	
	assign reg_address_1 = IR_D[12:10];
	assign reg_address_2 = IR_D[9:7];
	assign reg_write_address = ( IR_W[15:13] == 3'b000 || (IR_W[15:13] == 3'b001 && IR_W[6:5] == 2'b00) ) ? IR_W[2:0] : IR_W[12:10]; // must change to acomodate ADD for RegC in 2:0
	assign reg_write_data = W_TO_REG_DATA;
	assign reg_write_enable = ( IR_W[15:13] == 3'b100 || IR_W[15:13] == 3'b000 || IR_W[15:13] == 3'b011 || (IR_W[15:13] == 3'b001 && IR_W[6:5] == 2'b00) ) ? 1'b1 : 1'b0;
	
	assign D_ram_address = IR_D[9:7] + IR_D[8:0];
	
	assign ALU_A = E[0];
	assign ALU_B = E[1];
	assign ALU_CONTROL = IR_E[5:3];
	
	assign RAM_ADDRESS = M[2];
	assign RAM_WRITE_DATA = M[1];
	assign RAM_WRITE_ENABLE = ( IR_M[15:13] == 3'b101 ) ? 1'b1 : 1'b0;
	assign RAM_OR_ALU_DATA_TO_REG_SEL = ( IR_W[15:13] == 3'b100 ) ? 1'b1 : 1'b0; //when loading word, do so from ram, used in W stage
	
	assign REMEM_DATA_TO_REG_SEL = ( IR_W[15:13] == 3'b011 || (IR_W[15:13] == 3'b001 && IR_W[6:5] == 2'b00) ) ? 1'b1 : 1'b0; //load word from REMEM to reg when 3 & bit are 0
	
	
endmodule
`include "Data_path.v"


/*	Instruction Example
	001 = [15:13]OPCODE - [12:10]REMEM - [9:7]REMEM - [6:5]REMEM/REG_SEL - [4:3]GATE_SEL - [2:0]REMEM/REG
	010 = [15:13]OPCODE - [12:10]REMEM - [9:7]REGISTER
	011 = [15:13]OPCODE - [12:10]REGISTER - [2:0]REMEM
	100 = [15:13]OPCODE - [12:10]REGISTER - [9:0]RAM
*/
module CPU_16bit_pipeline_TB ( output test );
	reg clk;
	
	initial 
   begin
		$dumpfile("CPU.vcd");
		$dumpvars(0, CPU_16bit_pipeline_TB);
		clk <= 1;
		#150;
		$finish;
   end
	
	always 
	begin
		#5 clk = ~clk;
	end
	
	Data_path dt_pth_1( .clk(clk) );
endmodule

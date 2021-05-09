`include "opcodes.v" 
// [ ] wwd
module control_unit (
	opcode,
	func_code,
	clk,
	reset_n,
	alu_src,
	is_branch,
	reg_write,
	mem_read,
	mem_write,
	mem_to_reg,
	wwd);

	input [3:0] opcode;
	input [5:0] func_code;
	input clk;
	input reset_n;
	
	output reg alu_src, is_branch, reg_write, mem_read, mem_to_reg, mem_write;
	//additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start
	// output reg pc_to_reg, halt, wwd, new_inst;
	
	output reg wwd;
	// output reg [1:0] reg_write, alu_src_A, alu_src_B;
    reg isStore = 0;
    reg isLoad = 0;
    reg isJtype = 0;
    reg isRtype = 0;
    reg isItype = 0;
    reg isBranch = 0;

	//TODO : implement control unit
	always @(*) begin
		alu_src = 0;
		is_branch = 0;
		reg_write = 0;
		mem_read = 0;
		mem_write = 0;
		mem_to_reg = 0;
		wwd = 0;
		isStore = (opcode == `SWD_OP);
		isJtype = (opcode == `JMP_OP) || (opcode == `JAL_OP);
		isRtype = opcode == `ALU_OP;
		isItype = !isJtype && !isRtype;
		isBranch = (opcode == `BNE_OP) || (opcode == `BEQ_OP) || (opcode == `BGZ_OP) || (opcode == `BLZ_OP); 
		isLoad = (opcode == `LWD_OP);
		if(isLoad) begin
			mem_read = 1;
			mem_to_reg = 1;
		end
		if(isStore) begin
			// $display("CONTROL_UNIT // mem_write");
			mem_write = 1;
		end
		if(isBranch) begin
			// $display("CONTROL_UNIT // Branch");
			is_branch = 1;
		end
		if((isStore || isItype) && (opcode != `BNE_OP)) begin
			alu_src = 1;
			// $display("CONTROL_UNIT // alu_src");
		end
		if (opcode == `WWD_OP) begin
			wwd = 1;
		end
		if(!isStore && !isBranch) begin
			reg_write = 1;
			// $display("CONTROL_UNIT // reg_write");
		end
	end
endmodule

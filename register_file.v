`include "opcodes.v" 

module register_file (read_out1, read_out2, read1, read2, dest, write_data, reg_write, clk, reset_n);

	input clk, reset_n;
	input [1:0] read1;
	input [1:0] read2;
	input [1:0] dest;
	input reg_write;
	input [`WORD_SIZE-1:0] write_data;
	

	output [`WORD_SIZE-1:0] read_out1;
	output [`WORD_SIZE-1:0] read_out2;
	
	//TODO: implement register file

	reg [`WORD_SIZE-1:0] GPR [`NUM_REGS-1:0];

	initial begin
		GPR[0] = 0;
		GPR[1] = 0;
		GPR[2] = 0;
		GPR[3] = 0;
	end

	

endmodule

module PC_REG(clk, pc_in, stall, pc_out);
	always @(posedge clk) begin
		pc_out <= pc_in;
	end
endmodule

module IF_ID_REG (clk, if_pc, if_inst, stall, id_pc, id_inst);

	input clk;
	input if_pc;
	input if_inst;
	input stall;

	output id_pc;
	output id_inst;

//stall condition is needed
	always @(posedge clk) begin
		id_pc <= if_pc;
		id_inst <= if_inst;
	end

endmodule

module ID_EX_REG (clk, id_wb, id_m, id_ex, id_pc, id_read1, id_read2, id_imm, id_alu_control, id_write_reg, stall
ex_wb, ex_m, ex_ex, ex_pc, ex_read1, ex_read2, ex_imm, ex_alu_control, ex_write_reg);

	input clk;
	input id_wb;
	input id_m;
	input id_ex;
	input id_pc;
	input id_read1;
	input id_read2;
	input id_imm;
	input id_alu_control;
	input id_write_reg;
	input stall;

	output ex_wb;
	output ex_m;
	output ex_ex;
	output ex_pc;
	output ex_read1;
	output ex_read2;
	output ex_imm;
	output ex_alu_control;
	output ex_write_reg;

//stall condition is needed
	always @(posedge clk) begin
		ex_wb <= id_wb;
	    ex_m <= id_m;
	    ex_ex <= id_ex;
	    ex_pc <= id_pc;
	    ex_read1 <= id_read1;
	    ex_read2 <= id_read2;
	    ex_imm <= id_imm;
	    ex_alu_control <= id_alu_control;
	    ex_write_reg <= id_write_reg;
	end

endmodule

module EX_MEM_REG (clk, ex_wb, ex_m, ex_pc_added, ex_bcond, ex_alu_result, ex_read2, ex_write_reg, stall,
mem_wb, mem_m, mem_bcond, mem_alu_result, mem_read2, mem_write_reg);

	input clk;
	input ex_wb;
	input ex_m;
	input ex_pc_added;
	input ex_bcond;
	input ex_alu_result;
	input ex_read2;
	input ex_write_reg;
	input stall;

	output mem_wb;
	output mem_m;
	output mem_bcond;
	output mem_alu_result;
	output mem_read2;
	output mem_write_reg;

//stall condition is needed
	always @(posedge clk) begin
		mem_wb <= ex_wb;
		mem_m <= ex_m;
		mem_bcond <= ex_bcond;
		mem_alu_result <= ex_alu_result;
		mem_read2 <= ex_read2;
		mem_write_reg <= ex_write_reg;
	end

endmodule

module MEM_WB_REG (clk, mem_wb, mem_read_data, mem_alu_result, mem_write_reg, stall, 
wb_read_data, wb_alu_result, wb_write_reg);

	input clk;
	input mem_wb;
	input mem_read_data;
	input mem_alu_result;
	input mem_write_reg;
	input stall;

	output wb_read_data;
	output wb_alu_result;
	output wb_write_reg;

//stall needed
	always @(posedge clk) begin
		wb_read_data <= mem_read_data;
		wb_alu_result <= mem_alu_result;
		wb_write_reg <= mem_write_reg;
	end

endmodule
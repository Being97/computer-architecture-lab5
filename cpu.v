`timescale 1ns/1ns

`include "datapath.v"

module cpu(clk, reset_n, read_m1, address1, data1, read_m2, write_m2, address2, data2, num_inst, output_port, is_halted);

	input clk;
	input reset_n;

	output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;

	output [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	output is_halted;

	// data
	reg [1:0] rs, rt, rd;
	reg [5:0] func;
	reg [7:0] imm;
	reg [`WORD_SIZE-1:0] imm_extended;
	reg [11:0] target_addr;
	reg [`WORD_SIZE-1:0] alu_input_A;
	reg [`WORD_SIZE-1:0] alu_input_B;
	wire [`WORD_SIZE-1:0] alu_out;
	reg [1:0] branch_type;
	wire overflow_flag;
	reg [3:0] opcode;
	wire [5:0] funct;
	reg [3:0] alu_func_code;
	reg alu_op;
	wire [`WORD_SIZE-1:0] read_out1;
	wire [`WORD_SIZE-1:0] read_out2;
	reg [`WORD_SIZE-1:0] write_data;
	reg [1:0] write_reg;
	wire [`WORD_SIZE-1:0] alu_result;
	reg [`WORD_SIZE-1:0] pc_calced;
	reg [`WORD_SIZE-1:0] pc;

	// signals
	reg is_stall;
	reg instr_read;
	reg mem_read;
	reg mem_write;
	reg reg_write;
	reg pc_src;
	wire bcond;

	// not used signals
	wire new_alu_src;
	wire new_alu_op;
	wire new_is_branch;
	wire new_reg_write;
	wire new_mem_read;
	wire new_mem_write;
	wire new_mem_to_reg;

	// ex signals
	reg ex_alu_op;
	reg ex_reg_write;
	reg ex_alu_src;
	reg ex_is_branch;
	reg ex_mem_read;
	reg ex_mem_write;
	reg ex_mem_to_reg;

	// ex data
	reg [5:0] ex_func;
	reg [3:0] ex_opcode;
	wire [3:0] ex_alu_func_code;
	wire [1:0] ex_branch_type;
	reg [`WORD_SIZE-1:0] ex_imm_extended;
	reg [1:0] ex_write_reg;
	reg [`WORD_SIZE-1:0] ex_read_data_1;
	reg [`WORD_SIZE-1:0] ex_read_data_2;
	reg [`WORD_SIZE-1:0] ex_pc;
	reg [`WORD_SIZE-1:0] ex_pc_calced;

	// mem signals
	reg mem_is_branch;
	reg mem_mem_read;
	reg mem_mem_write;
	reg mem_reg_write;
	reg mem_pc_src;
	reg mem_bcond;

	// mem data
	reg [`WORD_SIZE-1:0] mem_pc;
	reg [`WORD_SIZE-1:0] mem_pc_calced;
	reg [`WORD_SIZE-1:0] mem_mem_to_reg;
	reg [`WORD_SIZE-1:0] mem_alu_result;
	reg [`WORD_SIZE-1:0] mem_write_data;
	reg [1:0] mem_write_reg;

	// wb signals
	reg wb_reg_write;
	reg wb_pc_src;

	// wb data
	reg [1:0] wb_write_reg;
	reg [`WORD_SIZE-1:0] wb_mem_to_reg;
	reg [`WORD_SIZE-1:0] wb_alu_result;
	reg [`WORD_SIZE-1:0] wb_read_data;
	reg [`WORD_SIZE-1:0] wb_pc;
	reg [`WORD_SIZE-1:0] wb_pc_calced;

	// id data
	reg [`WORD_SIZE-1:0] id_pc;
	reg [`WORD_SIZE-1:0] id_instr;

	// if data
	reg [`WORD_SIZE-1:0] if_pc;
	wire [`WORD_SIZE-1:0] if_instr;

	assign read_m1 = instr_read;
	assign read_m2 = mem_read;
	assign write_m2 = mem_write;
    assign data2 = write_m2 ? mem_write_data : `WORD_SIZE'bz;
	assign address1 = if_pc;
	assign address2 = mem_alu_result;


	alu_control_unit alu_control_unit(
		.funct(ex_func),
		.opcode(ex_opcode),
		.ALUOp(new_alu_op),
		.clk(clk),
		.funcCode(ex_alu_func_code),
		.branchType(ex_branch_type)
	);
	alu alu(
		.A(alu_input_A),
		.B(alu_input_B),
		.func_code(ex_alu_func_code),
		.branch_type(branch_type),
		.alu_out(alu_out),
		.overflow_flag(overflow_flag),
		.bcond(bcond)
	);
	control_unit control_unit (
		.opcode(opcode),
		.func_code(func),
		.clk(clk),
		.reset_n(reset_n),
		.alu_src(new_alu_src),
		.is_branch(new_is_branch),
		.reg_write(new_reg_write),
		.mem_read(new_mem_read),
		.mem_write(new_mem_write),
		.mem_to_reg(new_mem_to_reg)
	);
	register_file register_file (
		.read_out1(read_out1),
		.read_out2(read_out2),
		.read1(rs),
		.read2(rt),
		.dest(write_reg),
		.write_data(write_data),
		.reg_write(reg_write),
		.clk(clk),
		.reset_n(reset_n)
	);

	always @(*) begin
		if ((rs == ex_write_reg) && use_rs1(opcode, func) && ex_reg_write) begin
			is_stall = 1;
		end
		else if ((rs == mem_write_reg) && use_rs1(opcode, func) && mem_reg_write) begin
			is_stall = 1;
		end
		else if ((rs == wb_write_reg) && use_rs1(opcode, func) && wb_reg_write) begin
			is_stall = 1;
		end
		else if ((rt == ex_write_reg) && use_rs2(opcode, func) && ex_reg_write) begin
			is_stall = 1;
		end
		else if ((rt == mem_write_reg) && use_rs2(opcode, func) && mem_reg_write) begin
			is_stall = 1;
		end
		else if ((rt == wb_write_reg) && use_rs2(opcode, func) && wb_reg_write) begin
			is_stall = 1;
		end
		else begin
			is_stall = 0;
		end
	end


	// IF/ID
	always @(posedge clk) begin
		// passing data
		id_pc <= if_pc;
		// using data
		id_instr <= if_instr;
	end
	// ID
	always @(*) begin
		opcode = id_instr[`WORD_SIZE-1:12];
		rs = id_instr[11:10];
		rt = id_instr[9:8];
		rd = id_instr[7:6];
		func = id_instr[5:0];
		target_addr = {4'd0, id_instr[11:0]};
		imm = id_instr[7:0];
		if (opcode != `ORI_OP) begin
			imm_extended = $signed(id_instr[7:0]);
		end
		else begin
			imm_extended[15:0] = {{8{id_instr[7]}}, id_instr[7:0]};
		end
	end
	// ID/EX
	always @(posedge clk) begin
		if (!is_stall) begin
			// using control signals
			ex_alu_src <= new_alu_src;
			ex_alu_op <= new_alu_op;
			// passing control signals
			ex_reg_write <= new_reg_write;
			ex_is_branch <= new_is_branch;
			ex_mem_read <= new_mem_read;
			ex_mem_write <= new_mem_write;
			ex_mem_to_reg <= new_mem_to_reg;
			// using data
			ex_read_data_1 <= read_out1;
			ex_read_data_2 <= read_out2;
			ex_imm_extended <= imm_extended;
			ex_func <= func;
			ex_opcode <= opcode;
			// passing data
			ex_write_reg <= rd;
			// using & passing data
			ex_pc <= id_pc;
		end
		else begin
			ex_reg_write <= 0;
		end
	end
	// EX
	always @(*) begin
		ex_pc_calced = (ex_imm_extended << 1) + ex_pc;
		alu_input_A = ex_read_data_1;
		alu_input_B = ex_alu_src ? ex_imm_extended : ex_read_data_2;
		alu_op = ex_alu_op;
		alu_func_code = ex_alu_func_code;
		branch_type = ex_branch_type;
	end
	// EX/MEM
	always @(posedge clk) begin
		// passing control signals
		mem_reg_write <= ex_reg_write;
		// using control signals
		mem_is_branch <= ex_is_branch;
		mem_mem_read <= ex_mem_read;
		mem_mem_write <= ex_mem_write;
		// passing data
		mem_pc <= ex_pc;
		mem_pc_calced <= ex_pc_calced;
		mem_mem_to_reg <= ex_mem_to_reg;
		mem_write_reg <= ex_write_reg;
		// using data
		mem_bcond <= bcond;
		mem_alu_result <= alu_result;
		mem_write_data <= ex_read_data_2;
	end
	// MEM
	always @(*) begin
		mem_read = mem_mem_read;
		mem_write = mem_mem_write;
		mem_pc_src = mem_is_branch && mem_bcond;
	end
	// MEM/WB
	always @(posedge clk) begin
		// passing control signals
		wb_pc_src <= mem_pc_src; // 브랜치 프리딕션 구현 후 수정
		// using control signals
		wb_mem_to_reg <= mem_mem_to_reg;
		// passing data
		wb_pc <= mem_pc;
		wb_pc_calced <= mem_pc_calced;
		// using data
		wb_alu_result <= mem_alu_result;
		wb_write_reg <= mem_write_reg;
		wb_reg_write <= mem_reg_write;
		wb_read_data <= data2;
	end
	// WB
	always @(*) begin
		write_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;
		write_reg = wb_write_reg;
		reg_write = wb_reg_write;
	end
	// WB/IF
	always @(posedge clk) begin
		// using data
		pc_calced <= wb_pc_calced;
		pc <= wb_pc;
		pc_src <= wb_pc_src;
	end
	// IF
	always @(*) begin
		if_pc = pc_src ? pc_calced : pc + 1;
		instr_read = 1;
	end
	// IF/ID
	always @(posedge clk) begin
		// passing data
		id_pc <= if_pc;
		// using data
		id_instr <= data1;
	end

	function use_rs1;
		input opcode_temp1;
		input func_temp1;
		begin
			if (opcode_temp1 === `LHI_OP || opcode_temp1 === `JMP_OP || opcode_temp1 === `JAL_OP) begin
				use_rs1 = 0;
			end
			else if (func_temp1 === 27 || func_temp1 == 29 || func_temp1 === 30 || func_temp1 === 31) begin
				use_rs1 = 0;
			end
			else begin
				use_rs1 = 1;
			end
		end
	endfunction

	function use_rs2;
		input [3:0] opcode_temp2;
		input [5:0] func_temp2;
		begin
			if (opcode_temp2 === `BLZ_OP || opcode_temp2 === `BGZ_OP || opcode_temp2 === `JAL_OP) begin
				use_rs2 = 0;
			end
			else if (func_temp2 === 4 || func_temp2 == 5 || func_temp2 === 6 || func_temp2 === 7) begin
				use_rs2 = 0;
			end
			else if (func_temp2 > 24) begin
				use_rs2 = 0;
			end
			else begin
				use_rs2 = 1;
			end
		end
	endfunction
endmodule



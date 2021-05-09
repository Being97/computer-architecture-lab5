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

	output reg [`WORD_SIZE-1:0] num_inst;
	output reg [`WORD_SIZE-1:0] output_port;
	output is_halted;

	// data
	reg [1:0] rs, rt, rd;
	reg [5:0] func;
	reg [7:0] imm;
	reg [`WORD_SIZE-1:0] imm_extended;
	reg [11:0] target_addr;
	reg [`WORD_SIZE-1:0] alu_input_A;
	reg [`WORD_SIZE-1:0] alu_input_B;
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
	reg [`WORD_SIZE-1:0] next_pc;

	// signals
	reg is_stall;
	reg is_flush;
	reg instr_read;
	reg mem_read;
	reg mem_write;
	reg reg_write;
	reg pc_src;
	wire bcond;
	wire wwd;

	// not used signals
	wire new_alu_src;
	wire new_alu_op;
	wire new_is_branch;
	wire new_reg_write;
	wire new_mem_read;
	wire new_mem_write;
	wire new_mem_to_reg;
	wire new_wwd;

	// ex signals
	reg ex_alu_op;
	reg ex_reg_write;
	reg ex_alu_src;
	reg ex_is_branch;
	reg ex_mem_read;
	reg ex_mem_write;
	reg ex_mem_to_reg;
	reg ex_wwd;

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
	reg mem_wwd;

	// mem data
	reg [`WORD_SIZE-1:0] mem_pc;
	reg [`WORD_SIZE-1:0] mem_pc_calced;
	reg [`WORD_SIZE-1:0] mem_mem_to_reg;
	reg [`WORD_SIZE-1:0] mem_alu_result;
	reg [`WORD_SIZE-1:0] mem_write_data;
	reg [`WORD_SIZE-1:0] mem_read_data_1;
	reg [1:0] mem_write_reg;

	// wb signals
	reg wb_reg_write;
	reg wb_pc_src;
	reg wb_wwd;

	// wb data
	reg [1:0] wb_write_reg;
	reg [`WORD_SIZE-1:0] wb_mem_to_reg;
	reg [`WORD_SIZE-1:0] wb_alu_result;
	reg [`WORD_SIZE-1:0] wb_read_data;
	reg [`WORD_SIZE-1:0] wb_pc;
	reg [`WORD_SIZE-1:0] wb_pc_calced;
	reg [`WORD_SIZE-1:0] wb_read_data_1;

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


	initial begin
		instr_read <= 0;
		mem_alu_result <= 0;
		mem_write <= 0;
		num_inst <= -4;
	end

	always @(posedge clk) begin
		if (!reset_n) begin
			instr_read <= 1;
			mem_write <= 0;
			mem_read <= 0;
			pc_src <= 0;
			num_inst <= -4;
			is_flush <= 0;
			opcode <= 0;
			func <= 0;
			is_stall <= 0;
		end
	end

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
		.alu_out(alu_result),
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
		.mem_to_reg(new_mem_to_reg),
		.wwd(new_wwd)
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

	// pc harzard
	always @(negedge clk) begin
		if (opcode == `JMP_OP || opcode == `JAL_OP) begin
			next_pc <= target_addr;
			is_flush <= 1;
		end
		else if (func == 5'd25 || func == 5'd26) begin
			next_pc <= read_out1;
			is_flush <= 1;
		end
		else if (opcode == `BNE_OP || opcode == `BEQ_OP || opcode == `BGZ_OP || opcode == `BLZ_OP) begin
			next_pc <= imm_extended + id_pc;
			is_flush <= 1;
		end
		else begin
			is_flush <= 0;		
		end
	end

	always @(negedge clk) begin
		if ((rs == ex_write_reg) && use_rs1(opcode, func) && (ex_reg_write || ex_wwd)) begin
			is_stall <= 1;
		end
		else if ((rs == mem_write_reg) && use_rs1(opcode, func) && (mem_reg_write || mem_wwd)) begin
			is_stall <= 1;
		end
		else if ((rs == wb_write_reg) && use_rs1(opcode, func) && (wb_reg_write || wb_wwd)) begin
			is_stall <= 1;
		end
		else if ((rt == ex_write_reg) && use_rs2(opcode, func) && (ex_reg_write || ex_wwd)) begin
			is_stall <= 1;
		end
		else if ((rt == mem_write_reg) && use_rs2(opcode, func) && (mem_reg_write || mem_wwd)) begin
			is_stall <= 1;
		end
		else if ((rt == wb_write_reg) && use_rs2(opcode, func) && (wb_reg_write|| wb_wwd)) begin
			is_stall <= 1;
		end
		else begin
			is_stall <= 0;
		end
	end

	// IF
	always @(*) begin
		if (!reset_n) begin
			if_pc = 0;
			id_pc = -1;
			instr_read = 1;
			$display("======================= %d ========================", if_pc);
		end
		else if (is_flush) begin
			if_pc = next_pc;
			$display(">>>>>>> next_pc = %d", next_pc);
			is_flush = 0;
			instr_read = 1;
			$display("======================= %d ========================", if_pc);			
		end
		else begin
			if_pc = id_pc + 1;		
			instr_read = 1;
			$display("======================= %d ========================", if_pc);			
		end
	end
	// IF/ID
	always @(posedge clk) begin
		if (!is_stall) begin
			// passing data
			id_pc <= if_pc;			
			// using data
			id_instr <= data1;
			num_inst <= num_inst + 1;
			$display("%d [IF] instruction: %b, num_inst: %d", if_pc, data1, num_inst);
			instr_read <= 0;			
		end
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
			// using control signals
			ex_alu_src <= new_alu_src;
			ex_alu_op <= new_alu_op;
			// passing control signals
			ex_reg_write <= is_stall ? 0 : new_reg_write;
			ex_is_branch <= new_is_branch;
			ex_mem_read <= new_mem_read;
			ex_mem_write <= is_stall ? 0 : new_mem_write;
			ex_mem_to_reg <= new_mem_to_reg;
			ex_wwd <= is_stall ? 0 : new_wwd;
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
		// end
		// else begin
			// $display("%d [ID] stall", id_pc);
			// ex_reg_write <= 0;
		// end
		$display("%d [ID] opcode: %d, rs: %d, rt: %d, rd: %d, target_addr: %d", id_pc, opcode, rs, rt, rd, target_addr);
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
		mem_wwd <= ex_wwd;
		// using control signals
		mem_is_branch <= ex_is_branch;
		mem_mem_read <= ex_mem_read;
		mem_mem_write <= ex_mem_write;
		// passing data
		mem_pc <= ex_pc;
		mem_pc_calced <= ex_pc_calced;
		mem_mem_to_reg <= ex_mem_to_reg;
		mem_write_reg <= ex_write_reg;
		mem_read_data_1 <= ex_read_data_1;
		// using data
		mem_bcond <= bcond;
		mem_alu_result <= alu_result;
		mem_write_data <= ex_read_data_2;
		$display("%d [EX] wwd: %d, read1: %d, read2: %d, alu_result: %d",ex_pc, ex_wwd, ex_read_data_1, ex_read_data_2, alu_result);
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
		wb_wwd <= mem_wwd;
		// passing data
		wb_pc <= mem_pc;
		wb_pc_calced <= mem_pc_calced;
		// using data
		wb_alu_result <= mem_alu_result;
		wb_write_reg <= mem_write_reg;
		wb_reg_write <= mem_reg_write;
		wb_read_data <= data2;
		wb_read_data_1 <= mem_read_data_1;
		if (mem_read) begin
			$display("%d [MEM] mem read at %d, value is %d", mem_pc, mem_alu_result, data2);
		end
		else if (mem_write) begin
			$display("%d [MEM] mem write at %d, value is %d", mem_pc, mem_alu_result, mem_write_data);
		end
		else begin
			$display("%d [MEM] pass", mem_pc);
		end

	end
	// WB
	always @(*) begin
		if(wb_wwd) begin
			$display(">>>>> WWD : %d", wb_read_data_1);
			output_port = wb_read_data_1;
		end
		else begin
			write_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;
			write_reg = wb_write_reg;
			reg_write = wb_reg_write;
			$display("%d [WB] reg_write: %d,  write %d at reg %d",wb_pc, reg_write, write_data, write_reg);		
		end
	end


	function use_rs1;
		input opcode_temp1;
		input func_temp1;
		begin
			if (opcode_temp1 == `LHI_OP || opcode_temp1 == `JMP_OP || opcode_temp1 == `JAL_OP) begin
				use_rs1 = 0;
			end
			else if (func_temp1 == 27 || func_temp1 == 29 || func_temp1 == 30 || func_temp1 == 31) begin
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
			if (opcode_temp2 == `BLZ_OP || opcode_temp2 == `BGZ_OP || opcode_temp2 == `JAL_OP) begin
				use_rs2 = 0;
			end
			else if (func_temp2 == 4 || func_temp2 == 5 || func_temp2 == 6 || func_temp2 == 7) begin
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



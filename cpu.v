`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

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

	wire [`WORD_SIZE-1:0] alu_input_A;
	wire [`WORD_SIZE-1:0] alu_input_B;
	wire [`WORD_SIZE-1:0] alu_out;
	wire [3:0] alu_func_code;
	wire [1:0] branch_type;
	wire overflow_flag;
	wire bcond;
	wire ALUOp;
	wire [3:0] opcode;
	wire [5:0] funct;


	//TODO: implement pipelined CPU

	//alu, alu_control_unit
	alu_control_unit alu_control_unit(funct, opcode, ALUOp, clk, alu_func_code, branch_type);
	alu alu(alu_input_A, alu_input_B, alu_func_code, branch_type, alu_out, overflow_flag, bcond);	




endmodule



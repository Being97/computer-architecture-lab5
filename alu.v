`include "opcodes.v" 

module alu (A, B, func_code, branch_type, alu_out, overflow_flag, bcond);

	input [`WORD_SIZE-1:0] A;
	input [`WORD_SIZE-1:0] B;
	input [3:0] func_code;
	input [1:0] branch_type;

	output reg [`WORD_SIZE-1:0] alu_out;
	output reg overflow_flag; 
	output reg bcond;

	//TODO: implement alu 

  wire [15:0] carry1;
  wire [15:0] carry2;
  reg [`WORD_SIZE-1:0] C;
  assign carry1 = (A ^~B)&(A ^ C);
  assign carry2 = (A ^ B)&(A ^ C);

  initial begin
  	alu_out = 0;
	overflow_flag = 0;
	bcond = 0;
  end

  always @(*) begin
	case(func_code)
		4'b0000: begin
		alu_out = A + B;
		overflow_flag = carry1[15];
		end
		4'b0001: begin
		alu_out = A - B;
		overflow_flag = carry2[15];
		end 
		4'b0010: alu_out = A & B;
		4'b0011: alu_out = A | B;
		4'b0100: alu_out = ~A;
		4'b0101: alu_out = ~A + 1;
		4'b0110: alu_out = A << 1;
		4'b0111: alu_out = $signed(A) >>> 1;
		4'b1000: alu_out = A;
		// 4'b1001: alu_out = B;
	endcase

	case(branch_type)
		2'b00: begin
		if (A!=B) bcond = 1;
		else bcond = 0;
		end
		2'b01: begin
		if (A==B) bcond = 1;
		else bcond = 0;
		end
		2'b10: begin
		if ($signed(A)>0) bcond = 1;
		else bcond = 0;
		end
		2'b11: begin
		if ($signed(A)<0) bcond = 1;
		else bcond = 0;
		end
	endcase
	$display("[ALU] func_code: %d, A: %d, B: %d, alu_out: %d", func_code, A, B, alu_out);
  end

endmodule
`include "opcodes.v" 

module alu_control_unit(funct, opcode, ALUOp, clk, funcCode, branchType);
  input ALUOp;
  input clk;
  input [5:0] funct;
  input [3:0] opcode;

  output reg [3:0] funcCode;
  output reg [1:0] branchType;

  initial begin
    branchType = 2'b00;
    funcCode = 4'b0000;
  end

  always @(posedge clk) begin
    if (ALUOp == 1) begin
      func_code = 4'b0000;
      if (opcode == `ALU_OP) begin
        case(funct)
          `INST_FUNC_ADD: funcCode = 4'b0000;
          `INST_FUNC_SUB: funcCode = 4'b0001;
          `INST_FUNC_AND: funcCode = 4'b0010;
          `INST_FUNC_ORR: funcCode = 4'b0011;
          `INST_FUNC_NOT: funcCode = 4'b0100;
          `INST_FUNC_TCP: funcCode = 4'b0101;
          `INST_FUNC_SHL: funcCode = 4'b0110;
          `INST_FUNC_SHR: funcCode = 4'b0111;
          `INST_FUNC_JPR: funcCode = 4'b1000;
          `INST_FUNC_JRL: funcCode = 4'b1000;
          //`INST_FUNC_WWD: 
          //`INST_FUNC_HLT: 
      endcase
      end
      else if(opcode == `ADI_OP) begin funcCode = 4'b0000; end
      else if(opcode == `ORI_OP) begin funcCode = 4'b0011; end
      else if(opcode == `LHI_OP) begin funcCode = 4'b1000; end
      else if(opcode == `LWD_OP) begin funcCode = 4'b0000; end
      else if(opcode == `SWD_OP) begin funcCode = 4'b0000; end
      else if(opcode == `JAL_OP) begin funcCode = 4'b1000; end

    end
    else begin
      if(opcode == `BNE_OP) begin branchType = 2'b00; end
      else if(opcode == `BEQ_OP) begin branchType = 2'b01; end
      else if(opcode == `BGZ_OP) begin branchType = 2'b10; end
      else if(opcode == `BLZ_OP) begin branchType = 2'b11; end
    end

    //$display("-----ALU CONTROL----- opcode: %b, funct: %b, funcCode: %b, ALUOp: %b", opcode, funct, funcCode, ALUOp);
  end
endmodule
`include "opcodes.v" 

module register_file (read_out1, read_out2, read1, read2, dest, write_data, reg_write, clk, reset_n);

	input clk, reset_n;
	input [1:0] read1;
	input [1:0] read2;
	input [1:0] dest;
	input reg_write;
	input [`WORD_SIZE-1:0] write_data;
	
	output reg [`WORD_SIZE-1:0] read_out1;
	output reg [`WORD_SIZE-1:0] read_out2;
	
	//TODO: implement register file

	reg [`WORD_SIZE-1:0] GPR [`NUM_REGS-1:0];

	initial begin
		GPR[0] = 0;
		GPR[1] = 0;
		GPR[2] = 0;
		GPR[3] = 0;
	end

    // write_data
    always @(*) begin
        if (reg_write) begin
            GPR[dest] = write_data;
            // $display("REGISTER // WRITE_REG GPR[%d] = %d", dest, write_data);
        end
    end
    always @(*) begin
		// $display("REGISTER // rs = %d, rd = %d", read1, read2);
		// $display("         // GPR0 = %d, 1 = %d, 2 = %d, 3 = %d", GPR[0], GPR[1], GPR[2], GPR[3]);
		read_out1 = GPR[read1];
		read_out2 = GPR[read2];
		// $display("         // read_out1 = %d, read_out2 = %d", read_out1, read_out2);
    end
endmodule

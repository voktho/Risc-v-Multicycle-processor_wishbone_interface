module DAT_REG #(parameter DATA_LENGTH=32)
    (
	input clk, reset,
	input read_en, write_en,
	input [DATA_LENGTH-1:0] DAT_I,
	input [DATA_LENGTH-1:0] DAT_mem_to_reg,
	output reg [DATA_LENGTH-1:0] DAT_STR, DAT_O);

	always @(posedge clk, negedge reset)
	begin

		if(~reset)
		begin
			DAT_STR <= 32'b0;
			DAT_O <= 32'b0;
        end
        
		else
			begin 
				DAT_STR <= write_en? DAT_I :  DAT_STR;
				DAT_O <= read_en? DAT_mem_to_reg :DAT_O;
			end
	end

endmodule 

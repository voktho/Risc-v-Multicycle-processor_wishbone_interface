module ADR_REG #(parameter ADDRESS_LENGTH=32) 
    (
	input clk, reset,
	input [ADDRESS_LENGTH-1:0] ADR_I,
	input adr_en,
	output reg [ADDRESS_LENGTH-1:0] ADR_STR);

	always @(posedge clk, negedge reset)
		begin
			if(~reset)
				ADR_STR <= 32'b0;

			else
				ADR_STR <= adr_en? ADR_I : ADR_STR;
		end
endmodule


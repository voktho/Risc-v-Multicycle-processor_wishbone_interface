module WISH_TOP #(parameter ADDRESS_LENGTH=32, parameter DATA_LENGTH=32)
    (
	input clk, reset, 
	input we, stb, cyc,
	input [ADDRESS_LENGTH-1:0]  DAT_I,
	input [ADDRESS_LENGTH-1:0] ADR_I,
	input [DATA_LENGTH-1:0] DAT_mem_to_reg,
	output ack,
	output [ADDRESS_LENGTH-1:0] ADR_STR, 
	output [DATA_LENGTH-1:0] DAT_STR, DAT_O,
	output read_en,write_en);
    
    

	WISH_FSM U_WISH_FSM(
		.clk(clk),
		.reset(reset),
		.we(we),
		.stb(stb),
		.cyc(cyc),
		.ack(ack),
		.adr_en(adr_en),
		.read_en(read_en),
		.write_en(write_en)
		);

	ADR_REG U_ADR_REG (
		.clk(clk),
		.reset(reset),
		.adr_en(adr_en),
		.ADR_I(ADR_I),
		.ADR_STR(ADR_STR)
		);

	DAT_REG U_DAT_REG(
		.clk(clk),
		.reset(reset),
		.read_en(read_en),
		.write_en(write_en),
		.DAT_I(DAT_I),
		.DAT_O(DAT_O),
		.DAT_mem_to_reg(DAT_mem_to_reg),
		.DAT_STR(DAT_STR)
		);

endmodule 


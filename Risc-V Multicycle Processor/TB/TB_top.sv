module TB_top();

	reg clk=0, reset;
	reg we, stb, cyc;
	reg [31:0]  DAT_I, ADR_I, DAT_mem_to_reg = 32'hAA;
	wire ack;
	wire [31:0] ADR_STR, DAT_STR, DAT_O;
	
	wire [31:0] address1=32'h04, address2=32'h08,data=32'hAB;
	wire read_en,write_en;

	WISH_TOP dut(
				.clk(clk),
				.reset(reset),
				.we(we),
				.stb(stb),
				.cyc(cyc),
				.ack(ack),
				.DAT_I(DAT_I),
				.DAT_STR(DAT_STR),
				.DAT_mem_to_reg(DAT_mem_to_reg),
				.DAT_O(DAT_O),
				.ADR_I(ADR_I),
				.ADR_STR(ADR_STR),
				.read_en(read_en),
				.write_en(write_en));
  
  initial    forever #5 clk<=~clk; 
  
  initial
    begin
		reset<=0;
		stb<=0;
		cyc<=0;
		we<=0;
		@(posedge clk);
		
		reset<=1;
		we<=1;
		stb<=1;
		cyc<=1;
		@(posedge clk);
		
		ADR_I<=address1;
		@(posedge clk);		
		if(ack)
		    DAT_I<=data;
		
		@(posedge clk);
		
		#20
		we<=0;
		#40
		$finish;
    end

endmodule

module MEM__CTRL_TOP_TB();

	reg clk=0, reset;
	reg we, stb, cyc, core_select=0;
	reg [31:0]  DAT_I, ADR_I;
	wire ack;
	wire [31:0] DAT_O;
    reg [31:0] i;
	
	reg [31:0] address1, address2, data1, data2;


	MEM_CTRL_TOP dut(
				.clk(clk),
				.reset(reset),
				.we(we),
				.stb(stb),
				.cyc(cyc),
				.ack(ack),
				.core_select(core_select),
				.DAT_I(DAT_I),
				.DAT_O(DAT_O),
				.ADR_I(ADR_I));
  
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
		
		
		
		for(i=0;i<10;i=i+1)
	    begin
	        data1 = $urandom_range( 65535, 0 );		        
	        ADR_I<=i;
	        @(posedge clk);
	
	        if(ack)
	            DAT_I<=data1;
	
	        @(posedge clk);
	    end
	    stb<=0;
		cyc<=0;
	    repeat(1) @(posedge clk);
	    
		address2 = $urandom_range( 9, 0 );
		
		
		//read_data(address2);
		we<=0;
		stb<=1;
		cyc<=1;
		@(posedge clk);
		
		ADR_I<=address2;
		@(posedge clk);
		
				
		@(posedge clk);
	    stb<=0;
		cyc<=0;
	    repeat(4) @(posedge clk);


		$finish;
    end
    
    //task write_data(input [31:0] address,data);
    //    we<=1;
	//	stb<=1;
	//	cyc<=1;
	//	@(posedge clk);
	//	
	//	ADR_I<=address;
	//	@(posedge clk);
	//	
	//	if(ack)
	//	    DAT_I<=data;
	//	
	//	@(posedge clk);   
    //endtask


    //task read_data(input address);
    //    we<=0;
	//	stb<=1;
	//	cyc<=1;
	//	@(posedge clk);
	//	
	//	ADR_I<=address;
	//	@(posedge clk);
		
				
	//	@(posedge clk);
	//    stb<=0;
	//	cyc<=0;
	//    repeat(4) @(posedge clk);	    
    //endtask


endmodule

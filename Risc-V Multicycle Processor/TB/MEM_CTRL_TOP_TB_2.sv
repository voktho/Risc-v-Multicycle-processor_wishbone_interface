module MEM__CTRL_TOP_TB_2();

	reg clk=0, reset;
	reg we, stb, cyc, core_select=0;
	reg [31:0]  DAT_I, ADR_I;
	wire ack;
	wire [31:0] DAT_O;
    reg [31:0] i;
    reg [31:0] test[127:0];
	
	reg [31:0] address1, address2, data1, data2;


	MEM_CTRL_TOP U_MEM_CTRL_TOP(
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
				
	
  
  initial    forever #3 clk<=~clk; 
  
  initial
    begin
        $readmemh("example.txt",test);
        
        core_select<=0;
		reset<=0;
		stb<=0;
		cyc<=0;
		we<=0;
		@(posedge clk);		
		reset<=1;
		
		//////////////////////////////////////////////////////////start the transfer
		we<=1;
		stb<=1;
		cyc<=1;
		@(posedge clk);	
		
		
		for(i=0;i<10;i=i+1)
	        begin
	            data1 = test[i];	
	            //$display("data = %h",data1);	        
	            ADR_I<=i;
	            @(posedge clk);
	
	            if(ack)
	                DAT_I<=data1;
	
	            @(posedge clk);
	        end
	        
        stb<=0;/////////////////////////////////////////////////////hold the transfer but not stop it
        #66
        stb<=1;/////////////////////////////////////////////////////restart the transfer
        
        for(i=10;i<100;i=i+1)
	        begin
	            data1 = test[i];	
	            //$display("data = %h",data1);	        
	            ADR_I<=i;
	            @(posedge clk);
	
	            if(ack)
	                DAT_I<=data1;
	
	            @(posedge clk);
	        end
        
        //////////////////////////////////////////////////////////end the transfer
	    stb<=0;
		cyc<=0;
	    repeat(1) @(posedge clk);
	    
	    core_select<=1;

	    #20000 $stop;
		$finish;
    end  
        
endmodule

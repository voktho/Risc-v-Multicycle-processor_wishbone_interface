module MEM_CTRL_TOP_FSM( input clk,reset,ack,                                              
                    input read_en_from_interf,write_en_from_interf,
                    output reg mem_en_from_interf_to_mem, read_en_from_interf_to_mem, write_en_from_interf_to_mem);
    
    reg [1:0] pstate, nstate;
	reg [1:0] IDLE=0, MEM_ENABLE=2, ACCESS=1;
    
	always @(*) 
		begin
			case (pstate)
				IDLE :      nstate <= ack? ACCESS : IDLE;
				ACCESS :    nstate <= ack? MEM_ENABLE : IDLE;				
				MEM_ENABLE :nstate <= ack? ACCESS : IDLE;
			endcase

		end
		
	always @(*) 
		begin
			case (pstate)
				IDLE : 
				begin
				    mem_en_from_interf_to_mem =0;
				    read_en_from_interf_to_mem=0;
				    write_en_from_interf_to_mem=0;
				end		
						
				ACCESS : 
				begin
				    mem_en_from_interf_to_mem =read_en_from_interf;
				    read_en_from_interf_to_mem=read_en_from_interf;
				    write_en_from_interf_to_mem=0;
				end	
				
				MEM_ENABLE:
                begin
				    mem_en_from_interf_to_mem =1;
				    read_en_from_interf_to_mem=read_en_from_interf;
				    write_en_from_interf_to_mem=write_en_from_interf;
				end
			endcase

		end

	always @(posedge clk, negedge reset)
		begin 
			if(~reset)
				pstate<= IDLE;

			else
				pstate<= nstate;
		end
		                
                
    	                                    
    
    endmodule

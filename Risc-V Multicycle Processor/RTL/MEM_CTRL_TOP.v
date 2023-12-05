module MEM_CTRL_TOP #(parameter ADDRESS_LENGTH=32, parameter DATA_LENGTH=32)
              ( input clk,reset,
                input [ADDRESS_LENGTH-1:0] ADR_I, DAT_I,
                input we, stb , cyc,
                input core_select,
                output [DATA_LENGTH-1:0] DAT_O,                
                output ack );
                
 
    wire [ADDRESS_LENGTH-1:0] from_intf_mem_ctrl_mem_address;
    wire [DATA_LENGTH-1:0] from_intf_mem_ctrl_mem_data_in, to_intf_mem_ctrl_mem_data_out;                        
    wire from_intf_mem_ctrl_mem_rd_en, from_intf_mem_ctrl_mem_wr_en, from_intf_mem_ctrl_mem_en;
    wire [1:0] from_intf_mem_ctrl_mem_data_length=2'b11;
    
    wire MemWrite, MemRead;
    wire [ADDRESS_LENGTH-1:0] WriteData,ReadData;
    wire [DATA_LENGTH-1:0] DataAdr;
    
    WISH_TOP U_WISH_TOP(.clk(clk),
		                .reset(reset),
		                .we(we),
		                .stb(stb),
		                .cyc(cyc),
		                .ack(ack),
		                .DAT_I(DAT_I),
		                .DAT_O(DAT_O),
		                .ADR_I(ADR_I), 
		                .DAT_mem_to_reg(to_intf_mem_ctrl_mem_data_out),
		                .DAT_STR(from_intf_mem_ctrl_mem_data_in),
		                .ADR_STR(from_intf_mem_ctrl_mem_address),
		                .read_en(read_en_from_interf),
		                .write_en(write_en_from_interf));
		                
    MEM_CTRL_TOP_FSM U_MEM_CTRL_TOP_FSM(.clk(clk),
                              .ack(ack),
		                      .reset(reset),
		                      .read_en_from_interf(read_en_from_interf),
		                      .write_en_from_interf(write_en_from_interf),
		                      .read_en_from_interf_to_mem(from_intf_mem_ctrl_mem_rd_en),
		                      .write_en_from_interf_to_mem(from_intf_mem_ctrl_mem_wr_en),
		                      .mem_en_from_interf_to_mem(from_intf_mem_ctrl_mem_en));
		                      
	
	Risc_top U_Risc_top(core_select, clk, reset, WriteData, DataAdr, MemWrite, MemRead, ReadData);
		                
    
    data_memory_wrapper #( 32, 32)   
                         U_data_memory_wrapper ( .clk(clk),
                                                .core_select(core_select), 
                                               
                                               
                                                .from_intf_mem_ctrl_mem_en(from_intf_mem_ctrl_mem_en),
                                                .from_intf_mem_ctrl_mem_wr_en(from_intf_mem_ctrl_mem_wr_en), 
                                                .from_intf_mem_ctrl_mem_rd_en(from_intf_mem_ctrl_mem_rd_en), 
                                                .from_intf_mem_ctrl_mem_address(from_intf_mem_ctrl_mem_address), 
                                                .from_intf_mem_ctrl_mem_data_in(from_intf_mem_ctrl_mem_data_in), 
                                                .from_intf_mem_ctrl_mem_data_length(from_intf_mem_ctrl_mem_data_length), 
                                                .to_intf_mem_ctrl_mem_data_out(to_intf_mem_ctrl_mem_data_out),
                                                  
                                                .from_core_mem_en(MemWrite|MemRead),
                                                .from_core_mem_wr_en(MemWrite),
                                                .from_core_mem_rd_en(MemRead),
                                                .from_core_mem_address(DataAdr),
                                                .from_core_mem_data_in(WriteData),
                                                .from_core_mem_data_length(2'b00),
                                                .to_core_mem_data_out(ReadData));
    
                            
    
    endmodule

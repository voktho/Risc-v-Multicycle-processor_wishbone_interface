module testbench();
    logic core_select = 1, clk;
    logic reset;
    logic [31:0] WriteData, DataAdr;
    logic MemWrite;
      
    // instantiate device to be tested
    Risc_top dut(core_select, clk, reset, WriteData, DataAdr, MemWrite, MemRead, ReadData);
      
    // initialize test
    initial
        begin
             reset <= 0; # 2; reset <= 1;
        end
      
    // generate clock to sequence tests
    always
        begin
            clk <= 1; # 5; clk <= 0; # 5;
        end
      
    // check results
    always @(negedge clk)
        begin
            if(MemWrite)
             begin
                if(DataAdr === 50 & WriteData === 4140) 
                begin
                    $display("Simulation succeeded");
                    $stop;
                end
            end
              #20000 $stop;
        end
   
endmodule

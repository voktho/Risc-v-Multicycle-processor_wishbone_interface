module Risc_top #(parameter ADDRESS_LENGTH=32, parameter DATA_LENGTH=32)
    (input logic core_select, clk, reset,
    output logic [DATA_LENGTH-1:0] WriteData, 
    output logic [ADDRESS_LENGTH-1:0]DataAdr,
    output logic MemWrite,
    output logic MemRead,
    input logic [DATA_LENGTH-1:0] ReadData);
    

    risc_multi u_risc_multi(core_select, clk, reset, MemWrite, DataAdr, WriteData, ReadData, MemRead);
    
endmodule


module risc_multi #(parameter ADDRESS_LENGTH=32, parameter DATA_LENGTH=32)
    (input logic core_select, clk, reset,
    output logic MemWrite,
    output logic [ADDRESS_LENGTH-1:0] Adr, 
    output logic [DATA_LENGTH-1:0] WriteData,
    input logic [DATA_LENGTH-1:0] ReadData,
    output logic MemRead);
    
    logic RegWrite, jump;
    logic [1:0] ResultSrc;
    logic [2:0] ImmSrc; // expand to 3-bits for lui and auipc
    logic [3:0] ALUControl;
    logic PCWrite;
    logic IRWrite;
    logic [1:0] ALUSrcA;
    logic [1:0] ALUSrcB;
    logic AdrSrc;
    logic [3:0] Flags; // added for other branches
    logic [6:0] op;
    logic [2:0] funct3;
    logic funct7b5;
    logic LoadType; // added for lbu
    logic StoreType; // added for sb
    logic PCTargetSrc; // added for jalr
    
    controller u_controller(core_select, clk, reset, op, funct3, funct7b5, Flags, ImmSrc, ALUSrcA, ALUSrcB, ResultSrc,AdrSrc, 
                 ALUControl, IRWrite, PCWrite, RegWrite, MemWrite, LoadType, StoreType, PCTargetSrc, MemRead);
    
    datapath u_datapath(clk, reset, ImmSrc, ALUSrcA, ALUSrcB,ResultSrc, AdrSrc, IRWrite, PCWrite, RegWrite, MemWrite,
                ALUControl, LoadType, StoreType, PCTargetSrc, op, funct3, funct7b5, Flags, Adr, ReadData, WriteData);
endmodule


module controller(input logic core_select, clk,
    input logic reset,
    input logic [6:0] op,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [3:0] Flags,
    output logic [2:0] ImmSrc,
    output logic [1:0] ALUSrcA, ALUSrcB,
    output logic [1:0] ResultSrc,
    output logic AdrSrc,
    output logic [3:0] ALUControl,
    output logic IRWrite, PCWrite,
    output logic RegWrite, MemWrite,
    output logic LoadType, // lbu
    output logic StoreType, // sb
    output logic PCTargetSrc, // jalr
    output logic MemRead); 
    
    logic [1:0] ALUOp;
    logic Branch, PCUpdate;
    logic branchtaken; // added for other branches
    
    // Main FSM
    mainfsm u_mainfsm(core_select, clk, reset, op, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, IRWrite, PCUpdate,
                       RegWrite, MemWrite, ALUOp, Branch, MemRead);
    
    // ALU Decoder
    aludec u_aludec(op[5], funct3, funct7b5, ALUOp, ALUControl);
    // Instruction Decoder
    
    instr_dec u_instr_dec(op, ImmSrc);
    
    // Branch logic
    lsu u_lsu(funct3, LoadType, StoreType);
    
    branch_unit u_branch_unit(Branch, Flags, funct3, branchtaken); // added for bne,blt, etc.
    
    assign PCWrite = branchtaken | PCUpdate;
endmodule


module mainfsm(input logic core_select, clk,
    input logic reset,
    input logic [6:0] op,
    output logic [1:0] ALUSrcA, ALUSrcB,
    output logic [1:0] ResultSrc,
    output logic AdrSrc,
    output logic IRWrite, PCUpdate,
    output logic RegWrite, MemWrite,
    output logic [1:0] ALUOp,
    output logic Branch,
    output logic MemRead);
    
    typedef enum logic [3:0] 
        {FETCH, READ, DECODE, MEMADR, MEMREAD, MEMWB, MEMWRITE, MEMBUFF, EXECUTER, EXECUTEI,EXECUTEA,EXECUTEL, ALUWB, BEQ, JAL, UNKNOWN} statetype;
        
    statetype state, nextstate;
    logic [14:0] controls;
    logic xxxx;
    
    // state register    
    always @(posedge clk or negedge reset)
        if (~reset ) state <= FETCH;
        else state <= core_select? nextstate : FETCH;/////////////////////////////////////////////////////////////////
    
    // next state logic
    always_comb
        case(state)
            FETCH: nextstate = READ;///////////////////////////////////////////////////////////////////
            READ: nextstate = DECODE;
            DECODE: 
                    casez(op)
                        7'b0?00011: nextstate = MEMADR; // lw or sw
                        7'b0110011: nextstate = EXECUTER; // R-type
                        7'b0010011: nextstate = EXECUTEI; // addi
                        7'b1100011: nextstate = BEQ; // beq
                        7'b1101111: nextstate = JAL; // jal
                        7'b1100111: nextstate = EXECUTEI;//jalr
                        7'b0010111: nextstate = EXECUTEA; // auipc
                        7'b0110111: nextstate = EXECUTEL;
                        default: nextstate = UNKNOWN;
                    endcase
                
            MEMADR:
                    if (op[5]) nextstate = MEMWRITE; // sw
                    else nextstate = MEMREAD; // lw
                
            //MEMREAD: nextstate = MEMWB;
            MEMREAD: nextstate = MEMBUFF;
            MEMBUFF: nextstate = MEMWB;
            EXECUTER: nextstate = ALUWB;
            //EXECUTEI: nextstate = ALUWB;
            EXECUTEI:
                    if (op[5]) nextstate = JAL; // sw
                    else nextstate = ALUWB; // lw
            EXECUTEA: nextstate = ALUWB;
            EXECUTEL: nextstate = ALUWB;
            JAL: nextstate = ALUWB;
            
            default: nextstate = FETCH;
        endcase
        
    // state-dependent output logic
    always_comb
        case(state)
            FETCH: controls =   15'b00_10_10_0_0_0_0_0_00_0_1;
            READ: controls =    15'b00_10_10_0_1_1_0_0_00_0_0;///////////////////////
            DECODE: controls =  15'b01_01_00_0_0_0_0_0_00_0_0;
            MEMADR: controls =  15'b10_01_00_0_0_0_0_0_00_0_0;
            MEMREAD: controls = 15'b00_00_00_1_0_0_0_0_00_0_1;
            MEMBUFF: controls = 15'b00_00_00_1_0_0_0_0_00_0_0;
            MEMWRITE: controls =15'b00_00_00_1_0_0_0_1_00_0_0;
            MEMWB: controls =   15'b00_00_01_0_0_0_1_0_00_0_0;
            EXECUTER: controls =15'b10_00_00_0_0_0_0_0_10_0_0;
            EXECUTEI: controls =15'b10_01_00_0_0_0_0_0_10_0_0;
            EXECUTEA: controls =15'b00_01_10_0_0_0_0_0_00_0_0;/////////
            EXECUTEL: controls =15'b11_01_10_0_0_0_0_0_00_0_0;/////////
            ALUWB: controls =   15'b00_00_00_0_0_0_1_0_00_0_0;
            BEQ: controls =     15'b10_00_00_0_0_0_0_0_01_1_0;
            JAL: controls =     15'b01_10_00_0_0_1_0_0_00_0_0; //////////////////////////
            
            default: controls = 15'bxx_xx_xx_x_x_x_x_x_xx_x_x;
        endcase
    
    assign {ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, IRWrite, xxxx, RegWrite, MemWrite, ALUOp, Branch, MemRead} = controls;
    assign PCUpdate = (state == READ | state ==JAL) & core_select;/////////////////////////////////////////////////////////
    
endmodule


module aludec(input logic opb5,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [1:0] ALUOp,
    output logic [3:0] ALUControl); // expand to 4 bits for sra
    
    logic RtypeSub;
    assign RtypeSub = funct7b5 & opb5; // TRUE for R-type subtract instruction
    
    always_comb
        case(ALUOp)
            2'b00: ALUControl = 4'b000; // addition
            2'b01: ALUControl = 4'b001; // subtraction        
            default: 
                case(funct3) // R-type or I-type ALU
                    3'b000: if (RtypeSub)  ALUControl = 4'b0001; // sub
                            else           ALUControl = 4'b0000; // add, addi
                    3'b001: ALUControl = 4'b0110; // sll, slli
                    3'b010: ALUControl = 4'b0101; // slt, slti
                    3'b100: ALUControl = 4'b0100; // xor, xori
                    3'b101: if (funct7b5)  ALUControl = 4'b1000; // sra, srai
                            else           ALUControl = 4'b0111; // srl, srli
                    3'b110: ALUControl = 4'b0011; // or, ori
                    3'b111: ALUControl = 4'b0010; // and, andi
                    default: ALUControl = 4'bxxx; // ???
                endcase
        endcase
endmodule


module instr_dec (input logic [6:0] op,
    output logic [2:0] ImmSrc);
    
    always_comb
        case(op)
            7'b0110011: ImmSrc = 3'bxxx; // R-type
            7'b0010011: ImmSrc = 3'b000; // I-type ALU
            7'b0000011: ImmSrc = 3'b000; // lw / lbu
            7'b0100011: ImmSrc = 3'b001; // sw / sb
            7'b1100011: ImmSrc = 3'b010; // branches
            7'b1101111: ImmSrc = 3'b011; // jal
            7'b0110111: ImmSrc = 3'b100; // lui
            7'b1100111: ImmSrc = 3'b000; // jalr
            7'b0010111: ImmSrc = 3'b100; // auipc
            default: ImmSrc = 3'bxxx; // ???
        endcase
    
endmodule


module datapath #(parameter ADDRESS_LENGTH=32, parameter DATA_LENGTH=32)
    (input logic clk, reset,
    input logic [2:0] ImmSrc,
    input logic [1:0] ALUSrcA, ALUSrcB,
    input logic [1:0] ResultSrc,
    input logic AdrSrc,
    input logic IRWrite, PCWrite,
    input logic RegWrite, MemWrite,
    input logic [3:0] alucontrol,
    input logic LoadType, StoreType, // lbu, sb
    input logic PCTargetSrc,
    output logic [6:0] op,
    output logic [2:0] funct3,
    output logic funct7b5,
    output logic [3:0] Flags,
    output logic [ADDRESS_LENGTH-1:0] Adr,
    input logic [DATA_LENGTH-1:0] ReadData,
    output logic [DATA_LENGTH-1:0] WriteData);
    
    logic [DATA_LENGTH-1:0] PC, OldPC, Instr, immext, ALUResult;
    logic [DATA_LENGTH-1:0] SrcA, SrcB, RD1, RD2, A;
    logic [DATA_LENGTH-1:0] Result, Data, ALUOut;
    
    // next PC logic
    flopenr #(32) pcreg(clk, reset, PCWrite, Result, PC);
    flopenr #(32) oldpcreg(clk, reset, IRWrite, PC, OldPC);
        
    
    // memory logic
    mux2 #(32) adr_mux(PC , Result, AdrSrc, Adr);
    flopenr #(32) instr_reg(clk, reset, IRWrite, ReadData, Instr);
    flopr #(32) data_reg(clk, reset, ReadData, Data);
    
    // register file logic
    regfile reg_file(clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, RD1, RD2);    
    imm_extend u_imm_extend(Instr[DATA_LENGTH-1:7], ImmSrc, immext);
    flopr #(DATA_LENGTH) src_a_reg(clk, reset, RD1, A);
    flopr #(DATA_LENGTH) write_data_reg(clk, reset, RD2, WriteData);
    
    // ALU logic
    mux4 #(DATA_LENGTH) src_a_mux(PC, OldPC, A,32'b0, ALUSrcA, SrcA);
    mux3 #(DATA_LENGTH) src_b_mux(WriteData, immext, 32'd4, ALUSrcB, SrcB);
    alu u_alu(SrcA, SrcB, alucontrol, ALUResult, Flags);
    flopr #(DATA_LENGTH) alu_out_reg(clk, reset, ALUResult, ALUOut);
    mux3 #(DATA_LENGTH) result_mux(ALUOut, Data, ALUResult, ResultSrc, Result);
    
    // outputs to control unit
    assign op = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7b5 = Instr[30];
endmodule


module regfile #(parameter DATA_LENGTH=32)
    (input logic clk,
    input logic we3,
    input logic [ 4:0] a1, a2, a3,
    input logic [DATA_LENGTH-1:0] wd3,
    output logic [DATA_LENGTH-1:0] rd1, rd2);
    logic [DATA_LENGTH-1:0] register[31:0];
    
    always_ff @(posedge clk)
       // if (we3) register[a3] <= wd3;
        if (we3) register[a3] <= (a3!=0)? wd3:0;

    assign rd1 = (a1 != 0) ? register[a1] : 0;
    assign rd2 = (a2 != 0) ? register[a2] : 0;


    
endmodule


module adder #(parameter DATA_LENGTH=32)
    (input [DATA_LENGTH-1:0] a, b,
    output [DATA_LENGTH-1:0] y);
    assign y = a + b;
endmodule


module imm_extend(input logic [31:7] instr,
    input logic [2:0] immsrc, // extended to 3 bits for lui
    output logic [31:0] immext);
    
    always_comb
        case(immsrc)    
            3'b000: immext = {{20{instr[31]}}, instr[31:20]}; // I-type    
            3'b001: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type (stores)    
            3'b010: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type (branches)    
            3'b011: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type (jal)    
            3'b100: immext = {instr[31:12], 12'b0}; // U-type (lui, auipc)
            default: immext = 32'bx; // undefined
        endcase
endmodule


// zeroextend module added for lbu---------------------------------------------------------------------?
module zeroextend(input logic [7:0] a, output logic [31:0] zeroimmext);    
    assign zeroimmext = {24'b0, a};
endmodule

module flopr #(parameter WIDTH = 32)
        (input logic clk, reset,
        input logic [WIDTH-1:0] d,
        output logic [WIDTH-1:0] q);
            
    always_ff @(posedge clk, negedge reset)
        if (~reset) q <= 0;
        else q <= d ;
        
        
endmodule


module flopenr #(parameter WIDTH = 32)
    (input logic clk, reset, en,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q);
    
    always_ff @(posedge clk, negedge reset)
        if (~reset) q <= 0;
        else if (en) q <= d ;
        
endmodule


module mux2 #(parameter WIDTH = 32)
    (input logic [WIDTH-1:0] d0, d1,
    input logic s,
    output logic [WIDTH-1:0] y);
    
    assign y = s ? d1 : d0 ;
    
endmodule


module mux3 #(parameter WIDTH = 32)
    (input logic [WIDTH-1:0] d0, d1, d2,
    input logic [1:0] s,
    output logic [WIDTH-1:0] y);
    assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule


module mux4 #(parameter WIDTH = 32)///--------------------------------------------------------------------------------?????
    (input logic [WIDTH-1:0] d0, d1, d2, d3,
    input logic [1:0] s,
    output logic [WIDTH-1:0] y);
    assign y = s[1] ? (s[0] ? d3: d2) : (s[0] ? d1 : d0);
endmodule



module alu #(parameter WIDTH = 32)
    (input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic [3:0] alucontrol, // expanded to 4 bits for sra
    output logic [WIDTH-1:0] result,
    output logic [3:0] flags); // added for blt and other branches
    logic [WIDTH-1:0] condinvb, sum;
    logic v, c, n, z; // flags: overflow, carry out, negative, zero
    logic cout; // carry out of adder
    logic isAdd; // true if is an add operation
    logic isSub; // true if is a subtract operation
    
    assign flags = {v, c, n, z};
    assign condinvb = alucontrol[0] ? ~b : b;
    assign {cout, sum} = a + condinvb + alucontrol[0];
    assign isAddSub = ~alucontrol[3] & ~alucontrol[2] & ~alucontrol[1] | ~alucontrol[3] & ~alucontrol[1] & alucontrol[0];
    
    always_comb
        case (alucontrol)
            4'b0000: result = sum; // add
            4'b0001: result = sum; // subtract
            4'b0010: result = a & b; // and
            4'b0011: result = a | b; // or
            4'b0100: result = a ^ b; // xor
            4'b0101: result = sum[WIDTH-1] ^ v; // slt
            4'b0110: result = a << b[4:0]; // sll
            4'b0111: result = a >> b[4:0]; // srl
            4'b1000: result = $signed(a) >>> b[4:0]; // sra
            default: result = 32'bx;
        endcase
    
    // added for blt and other branches
    assign z = (result == 32'b0);
    assign n = result[WIDTH-1];
    assign c = cout & isAddSub;
    assign v = ~(alucontrol[0] ^ a[WIDTH-1] ^ b[WIDTH-1]) & (a[WIDTH-1] ^ sum[WIDTH-1]) & isAddSub;
endmodule


// Load/store Unit (lsu) added for lbu
module lsu(input logic [2:0] funct3,
    output logic LoadType, StoreType);
    always_comb
        case(funct3)
            3'b000: {LoadType, StoreType} = 2'b01;
            3'b010: {LoadType, StoreType} = 2'b00;
            3'b100: {LoadType, StoreType} = 2'b1x;
            default: {LoadType, StoreType} = 2'bxx;
        endcase
endmodule


// Branch Unit (bu) added for bne, blt, bltu, bge, bgeu
module branch_unit (input logic Branch,
    input logic [3:0] Flags,
    input logic [2:0] funct3,
    output logic taken);
    logic v, c, n, z; // Flags: overflow, carry out, negative, zero
    logic cond; // cond is 1 when condition for branch met
    assign {v, c, n, z} = Flags;
    assign taken = cond & Branch;
    always_comb
    case (funct3)
    3'b000: cond = z; // beq
      3'b001: cond = ~z; // bne
    3'b100: cond = (n ^ v); // blt
    3'b101: cond = ~(n ^ v); // bge
    3'b110: cond = ~c; // bltu
    3'b111: cond = c; // bgeu
    default: cond = 1'b0;
    endcase
endmodule


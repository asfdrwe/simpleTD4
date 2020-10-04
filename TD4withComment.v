module TD4;
/*
 * Copyright (c) 2020 asfdrwe (asfdrwe@gmail.com)
 * SPDX-License-Identifier: MIT
 */

  //  
  // TD4 MAIN
  //

  // CLOCK
  reg clock = 1'b0;

  // IN PORT
  reg [3:0] reg_in = 4'b0000;
  reg reset_n = 1'b0;

  // REGISTER
  reg [3:0] reg_a = 4'b0;
  reg [3:0] reg_b = 4'b0;
  reg [3:0] reg_out = 4'b0;
  reg [3:0] pc = 4'b0;

  // CARRY FLAG
  reg cflag = 1'b1;

  //  ROM
  reg [7:0] rom[0:15];
  initial $readmemb("ROM.bin", rom);

  //
  // FETCH
  //   input: pc[3:0]
  //   output: opcode[7:0]
  wire [7:0] opcode;
  assign opcode = rom[pc];

  //
  // DECODE
  //   input: opcode[7:0]
  //   output: alu_sel[1:0], load_sel[1:0], jmp, imm[3:0]
  //
  // FORMAT: OP[7:4] + IM[3:0]
  // 0000 ADD A, Im    A + IM to A
  // 0001 MOV A, B     B + IM(0000) to A
  // 0010 IN  A        IN + IM(0000) to A
  // 0011 MOV A, Im    0 + IM to A
  // 0100 MOV B, A     A + IM(0000) to B
  // 0101 ADD B, Im    B + IM to B
  // 0110 IN  B        IN + IM(0000) to B
  // 0111 MOV B, Im    0 + IM to B
  // 1001 OUT B        B + IM(0000) to OUT
  // 1011 OUT Im       0 + IM to OUT
  // 1110 JNC Im (JUMP IF NOT CARRY) 
  // 1111 JMP Im (JUMP) 0 + IM to PC
  wire [1:0] alu_sel;
  wire [1:0] load_sel;
  wire jmp;
  wire [3:0] im; // IMMEDIATE 
  assign alu_sel = (opcode[7:6] == 2'b11) ? 2'b11 : opcode[5:4];
  assign load_sel = opcode[7:6];
  assign jmp = opcode[4];
  assign im = opcode[3:0];

  //
  // EXECUTION
  //   input: alu_sel[1:0], im[3:0]
  //   output: alu_out[3:0], nextcflag

  // SELECTOR
  wire [3:0] alu_in;
  assign alu_in = (alu_sel == 2'b00) ? reg_a : // from A
                  (alu_sel == 2'b01) ? reg_b : // from B
                  (alu_sel == 2'b10) ? reg_in : // from input port
                                       4'b0000; // zero
  
  // ALU
  wire [3:0] alu_out;
  wire nextcflag;
  assign {nextcflag, alu_out} = alu_in + im;

  //
  // WRITE BACK
  //   input: alu_out[3:0], load_sel[1:0], jmp
  //   write back to: reg_a[3:0], reg_b[3:0], reg_out[3:0], pc, cflag;
  wire load_a, load_b, load_out, load_pc;
  assign load_a = (load_sel == 2'b00) ? 1'b0 : 1'b1; // negative logic
  assign load_b = (load_sel == 2'b01) ? 1'b0 : 1'b1; // negative logic
  assign load_out = (load_sel == 2'b10) ? 1'b0 : 1'b1; // negative logic
  assign load_pc = (load_sel == 2'b11 && (jmp == 1'b1 || cflag)) ? 1'b0 : 1'b1; // negative logic

  wire [3:0] next_pc;
  assign next_pc = (load_pc == 1'b0) ? alu_out : pc + 1;

  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      reg_a <= 4'b0;
      reg_b <= 4'b0;
      reg_out <= 4'b0;
      cflag <= 1'b1;
      pc <= 4'b0;
    end else begin
      reg_a <= #1 (load_a == 1'b0) ? alu_out : reg_a;
      reg_b <= #1 (load_b == 1'b0) ? alu_out : reg_b;
      reg_out <= #1 (load_out == 1'b0) ? alu_out : reg_out;
      cflag  <= #1 ~nextcflag; // negative logic carry 
      pc <= #1 next_pc;
    end
  end

  //
  // TEST benchmark
  //
  initial begin
    $dumpfile("TD4.vcd");
    $dumpvars(0, TD4);
    $monitor("%t: PC = %h, OPCODE = %h, ALU_SEL = %b, LOAD_SEL = %b, JMP = %b, IM = %h, A = %h, B = %h, OUT = %h, IN = %h, CFLAG = %b, ALU_IN = %h, LOAD_A = %b, LOAD_B = %b, LOAD_OUT = %b, LOAD_PC = %b, NEXTCFLAG = %b, ALU_OUT = %h", 
             $time, pc, opcode, alu_sel, load_sel, jmp, im, reg_a, reg_b, reg_out, reg_in, cflag, alu_in, load_a, load_b, load_out, load_pc, nextcflag, alu_out);
  end

  initial begin
    clock = 1'b0;
    forever begin
      #1 clock = ~clock;
    end
  end

  initial begin
    reset_n = 1'b0;

    #1 reset_n = 1'b1;
    #1000 $finish;
  end
endmodule

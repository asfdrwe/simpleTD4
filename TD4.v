module TD4 (input wire clock, input wire reset_n, input wire [3:0] in_port, output wire [3:0] pc_out, output wire [7:0] op, output wire [3:0] out_port, output wire [3:0] alu_data);
// Copyright (c) 2020 asfdrwe (asfdrwe@gmail.com)
// SPDX-License-Identifier: MIT
  reg [3:0] reg_a, reg_b, reg_out; 
  reg [3:0] pc = 4'b0;
  reg cflag = 1'b1;
  assign out_port = reg_out;
  assign pc_out = pc;

  reg [7:0] rom[0:15];
  initial $readmemb("ROM.bin", rom);

  wire [7:0] opcode;
  assign opcode = rom[pc];
  assign op = opcode;

  wire [1:0] alu_sel, load_sel;
  wire jmp;
  wire [3:0] im; // IMMEDIATE 
  assign alu_sel = (opcode[7:6] == 2'b11) ? 2'b11 : opcode[5:4];
  assign load_sel = opcode[7:6];
  assign jmp = opcode[4];
  assign im = opcode[3:0];

  wire [3:0] alu_in;
  assign alu_in = (alu_sel == 2'b00) ? reg_a : // from A
                  (alu_sel == 2'b01) ? reg_b : // from B
                  (alu_sel == 2'b10) ? in_port : // from input port
                                       4'b0000; // zero
  
  wire [3:0] alu_out;
  wire nextcflag;
  assign {nextcflag, alu_out} = alu_in + im;
  assign alu_data = alu_out;

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
endmodule

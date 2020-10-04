module TD4_test;
//  Copyright (c) 2020 asfdrwe (asfdrwe@gmail.com)
// SPDX-License-Identifier: MIT

  // 
  reg clock = 1'b0;
  reg reset_n = 1'b0;
  reg [3:0] reg_in = 4'b0000;
  wire [7:0] opcode;
  wire [3:0] out_port;
  wire [3:0] pc_out;
  wire [3:0] alu_data;

  TD4 td4_1(clock, reset_n, reg_in, pc_out, opcode, out_port, alu_data);

  initial begin
    $dumpfile("TD4.vcd");
    $dumpvars(0, TD4_test);
    $monitor("%t: pc = %h, opcode = %h, in_port = %h, out_port = %h, alu_data = %h", 
             $time, pc_out, opcode, reg_in, out_port, alu_data);
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

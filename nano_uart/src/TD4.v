/*
 * Copyright (c) 2020 asfdrwe (asfdrwe@gmail.com)
 * SPDX-License-Identifier: MIT
 */
module TD4 (
  input reset_n,
  input wire fpga_rx,
  input [3:0] in1,
  output [3:0] out,
  output wire fpga_tx
);
  //
  // main clock from PLL 50MHz
  //
  wire osc_clock, clock;

  Gowin_OSC osc1(osc_clock); // 120MHz
  Gowin_PLL pll1(clock, osc_clock); // 50MHz

  //
  // UART
  //
  reg tx_en ;
  wire [2:0] wadr;
  reg [7:0] wdata;
  wire rx_en =1'b0;
  wire [2:0] radr;
  wire [7:0] rdata;
  wire rx_rdy_n;
  wire tx_rdy_n;
  wire ddis;
  wire intr;
  wire dcd_n = 1'b1;
  wire cts_n = 1'b1;
  wire dsr_n = 1'b1;
  wire ri_n = 1'b1;
  wire dtr_n;
  wire rts_n;

  assign rx_en = 1'b0;
  assign rx_rdy_n = 1'b0;

  assign wadr = 3'd0 ;
  reg tx_rdy = 1'b0;
  assign tx_rdy_n = tx_rdy;

  UART_MASTER_Top uart1 (
    .I_CLK(clock),
    .I_RESETN(reset_n),
    .I_TX_EN(tx_en),
    .I_WADDR(wadr),
    .I_WDATA(wdata),
    .I_RX_EN(rx_en),
    .I_RADDR(radr),
    .O_RDATA(rdata),
    .SIN(fpga_rx),
    .RxRDYn(rx_rdy_n),
    .SOUT(fpga_tx),
    .TxRDYn(tx_rdy_n),
    .DDIS(ddis),
    .INTR(intr),
    .DCDn(dcd_n),
    .CTSn(cts_n),
    .DSRn(dsr_n),
    .RIn(ri_n),
    .DTRn(dtr_n),
    .RTSn(rts_n)
  );

  //
  // hex number to ascii charcode for UART
  function [7:0] hextochar(
    input [3:0] din
  );
    hextochar = din < 4'd10 ? 8'h30 + din : 8'h41 + din - 8'ha;
  endfunction

  //  
  // TD4 MAIN
  //
  // CLOCK
  reg [31:0] counter = 32'b0;
  reg mclock = 1'b0;

  // REGISTER
  reg [3:0] reg_a = 4'b0;
  reg [3:0] reg_b = 4'b0;
  reg [3:0] reg_out = 4'b0;
  reg [3:0] pc = 4'b0;

  // IN PORT
  wire [3:0] reg_in;
  assign reg_in = ~in1; // negative logic

  // OUT PORT
  assign out = ~reg_out; // negative logic to internal led

  // CARRY FLAG
  reg cflag = 1'b1;

  //  ROM
  reg [7:0] rom[0:15];
  initial $readmemb("../../src/ROM.bin", rom); // path is "../../src/"

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
  wire [3:0] op;
  wire [3:0] im; // IMMEDIATE 
  assign op = opcode[7:4];
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

  always @(posedge mclock or negedge reset_n) begin
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
  // for TD4
  // 50MHz to 1Hz machine clock (mclock)
  //
  // for UART
  // dump TD4 status to UART
  // PC OP,IM A,B,OUT in CFLAG,(LOAD_A,LOAD_B,LOAD_OUT,LOAD_PC),NEXTCFLAG,ALU_OUT 
  //
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      tx_rdy <= 1'b0;
      counter <= 32'b0;
      mclock <= 1'b0;
    end else begin
      case(counter)
      (32'd25_000_000 - 1): begin
        counter <= counter + 1;
        mclock <= 1'b1;
      end

      (32'd25_200_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(pc);
      end
      (32'd25_210_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= 8'h20;
      end
      (32'd25_220_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(op);
      end
      (32'd25_230_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(im);
      end
      (32'd25_240_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= 8'h20;
      end
      (32'd25_250_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(reg_a);
      end
      (32'd25_260_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(reg_b);
      end
      (32'd25_270_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(reg_out);
      end
      (32'd25_280_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= 8'h20;
      end
      (32'd25_290_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(reg_in);
      end
      (32'd25_300_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= 8'h20;
      end
      (32'd25_310_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(cflag);
      end
      (32'd25_320_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar({load_a, load_b, load_out, load_pc});
      end
      (32'd25_330_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(nextcflag);
      end
      (32'd25_340_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= hextochar(alu_out);
      end

      (32'd25_350_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= (out[3] == 1'b1) ? 8'h07 : 8'h20; // bell
      end

      (32'd25_380_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= 8'h0d;
      end
      (32'd25_390_000 - 1): begin
        counter <= counter + 1;
        tx_en <= 1'b1;
        tx_rdy <= 1'b1;
        wdata <= 8'h0a;
      end
      (32'd50_000_000 - 1): begin
        counter <= 0;
        mclock <= 1'b0;
      end

      default: begin
        tx_en <= 1'b0;
        tx_rdy <= 1'b0;
        counter <= counter + 1;
      end

      endcase
    end
  end
endmodule

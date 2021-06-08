// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`include "yonga_lz4_decoder_top.v"
`include "yonga_lz4_decoder.v"
`include "yonga_lz4_decoder_controller.v"
`include "dual_ram.v"
`include "FIFO_v.v"
`include "list_ch08_04_uart.v"
`include "list_ch08_03_uart_tx.v"
`include "list_ch08_01_uart_rx.v"
`include "list_ch04_20_fifo.v"
`include "list_ch04_11_mod_m_counter.v"

`default_nettype none

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vdda1,    // User area 1 3.3V supply
    inout vdda2,    // User area 2 3.3V supply
    inout vssa1,    // User area 1 analog ground
    inout vssa2,    // User area 2 analog ground
    inout vccd1,    // User area 1 1.8V supply
    inout vccd2,    // User area 2 1.8v supply
    inout vssd1,    // User area 1 digital ground
    inout vssd2,    // User area 2 digital ground
`endif
    // Wishbone Slave ports (WB MI A)
    input  wb_clk_i,
    input  wb_rst_i,
    input  wbs_cyc_i,
    input  wbs_stb_i,
    input  wbs_we_i,
    input  [3:0] wbs_sel_i,
    input  [31:0] wbs_dat_i,
    input  [31:0] wbs_adr_i,
    output  wbs_ack_o,
    output  [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input   [127:0] la_data_in,
    output  [127:0] la_data_out,
    input   [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output  [2:0] irq
);

wire clk;
wire rst;

wire tx, rx;

wire valid;
wire [31:0] rdata;
wire [31:0] wdata;

wire [7:0] compressed_data1;
wire [7:0] decompressed_data1;

// WB
assign wbs_dat_o = rdata;
assign wdata = wbs_dat_i;
assign valid = wbs_cyc_i && wbs_stb_i;

// IO
assign io_out[0] = tx;
assign io_oeb[0] = 1'b1;

assign rx = io_in[1];
assign io_oeb[1] = 1'b0;

assign io_oeb[(`MPRJ_IO_PADS-1):2] = {(`MPRJ_IO_PADS-3){rst}};

// LA
assign la_data_out = {{(88){1'b0}}, decompressed_data1,{(32){1'b0}}}; 
assign compressed_data1 = la_data_in[7:0];

assign clk = (~la_oenb[32]) ? la_data_in[64]: wb_clk_i;
assign rst = (~la_oenb[33]) ? la_data_in[65]: wb_rst_i;

assign irq = 3'b000;

yonga_lz4_decoder_top yonga_lz4_decoder_top (
    
    .clk(clk),
    .rst(rst),

    // MGMT SoC Wishbone Slave
    .valid(valid),
    .rdata(rdata),
    .wdata(wdata),
    .ready(wbs_ack_o),
    .wr_en(wbs_we_i),

    .compressed_data1(compressed_data1),
    .decompressed_data1(decompressed_data1),

    .rx(rx),
    .tx(tx)
);

endmodule

`default_nettype wire

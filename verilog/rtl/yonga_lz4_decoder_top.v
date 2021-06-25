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

`default_nettype none
module yonga_lz4_decoder_top (
    input  clk,
    input  rst,

    input  valid,
    output reg [31:0] rdata,
    input  [31:0] wdata,
    output reg ready,
    input wr_en,

    input [7:0] compressed_data1,
    output [7:0] decompressed_data1,

    input rx,
    output tx
);

wire rstn;
reg select;
 
reg  decompress_data_read_en1;
reg  i_fifo_wr_en1;
reg [7:0] i_fifo_w_data1;
reg decompress_fifo_data_ready1;

reg uart_tx_full_flag_control1;
reg [2:0] uart_tx_full_flag_count1;

wire decompress_fifo_empty1;

wire o_in_fifo_full1;
wire idle1;

reg lz4_o_fifo_read_request1;
wire rx_fifo_not_empty1;
wire rx_empty1;
wire [7:0] uart_r_data1;
wire tx_full1;
wire [5:0] decompress_fifo_data_count1;

assign rstn = !rst;
assign rx_fifo_not_empty1 = !rx_empty1;

always@(*) begin
    rdata = 32'b0;
    rdata[0]  = idle1;
    rdata[4]  = decompress_fifo_empty1;
    rdata[8]  = decompress_fifo_data_ready1;
    rdata[12] = o_in_fifo_full1;
end

    yonga_lz4_decoder U1 //  LZ4-CORE-1
        (
            .clk    (clk),
            .rstn   (rstn),

            .i_lz4_decompress_enable  (1'b0),
            .lz4_decompress_start     (1'b0),
            
            .i_compress_data_write    (i_fifo_wr_en1),
            .o_compress_fifo_full     (o_in_fifo_full1),    
            .i_compress_data          (i_fifo_w_data1),
            
            .i_decompress_data_read   (decompress_data_read_en1),
            .o_decompress_fifo_empty  (decompress_fifo_empty1),
            .o_fifo2_data_count       (decompress_fifo_data_count1),
            .o_decompress_data        (decompressed_data1),
            
            .o_idle      (idle1)
        );
        
    // ------------------------------UART------------------
    uart    // UART-1
        #(
           .DBIT(8), 
           .SB_TICK(16), 
           .DVSR(163), 
           .DVSR_BIT(8), 
           .FIFO_W(2) 
         )
        U5(
            .clk(clk),
            .reset(rst),
            .tx(tx),
            .rx(rx),
            .rd_uart(rx_fifo_not_empty1),
            .wr_uart(lz4_o_fifo_read_request1),
            .r_data(uart_r_data1),
            .w_data(decompressed_data1),
            .tx_full(tx_full1),
            .rx_empty(rx_empty1)          
        ); 
        
//------------------------------------------------------------------------------------------------------------//    
//-----------------Uart or Logic Analyzer Select--------------------------------------------------------------//       
        always @(posedge clk) begin
            if(rstn == 1'b0) 
                select <= 1'b1;
            else begin
                if(valid && !ready) begin
                    if(wr_en ==1'b1 && wdata[8] == 1'b1) // uart enable
                        select <= 1'b0;
                    else if(wr_en ==1'b1 && wdata[9] == 1'b1) // Logic Analyzer enable
                        select <= 1'b1;
                end     
            end  
        end
//------------------------------------------------------------------------------------------------------------//            
//-----------------Decompress Fifo Data Ready Control---------------------------------------------------------// 
        always @(posedge clk) begin
            if(rstn == 1'b0) begin
                decompress_fifo_data_ready1 <= 1'b0;
            end else begin
                if(decompress_fifo_data_count1> 20)
                    decompress_fifo_data_ready1 <= 1'b1;
                else
                    decompress_fifo_data_ready1 <= 1'b0;
            end  
        end
//------------------------------------------------------------------------------------------------------------//            
                      
        always @(posedge clk) begin
            if(rstn == 1'b0) begin 
                ready         <= 1'b0; 
                i_fifo_wr_en1 <= 1'b0;
                decompress_data_read_en1 <= 1'b0;
                lz4_o_fifo_read_request1 <= 1'b0;
                i_fifo_w_data1 <= 0;
                uart_tx_full_flag_control1 <= 1'b1;
                uart_tx_full_flag_count1 <= 0;
            end else begin             
                ready         <= 1'b0;
                i_fifo_wr_en1 <= 1'b0;
                decompress_data_read_en1 <= 1'b0;
                
                if(valid && !ready) 
                    ready  <= 1'b1;
//------------------------------------------Uart---------------------------------------------------------------//                         
                if(select == 1'b0) begin // uart enable
//                           Write fifo data
                    lz4_o_fifo_read_request1 <= decompress_data_read_en1;
                  
                    if(rx_fifo_not_empty1 == 1'b1)begin
                        i_fifo_wr_en1  <= 1'b1;
                        i_fifo_w_data1 <= uart_r_data1;
                    end
//------------------------------------------------------------------------------------------------------------//                                                
//                      Read fifo data                    
                    if(!decompress_fifo_empty1 && uart_tx_full_flag_control1 == 1 && tx_full1 == 1'b0)begin 
                       decompress_data_read_en1   <=  1'b1;
                       uart_tx_full_flag_control1 <=  1'b0;
                    end
//------------------------------------------------------------------------------------------------------------//                          
//                      uart_tx_full_flag_control                     
                    if(uart_tx_full_flag_control1 ==  1'b0 )begin                        
                        if(uart_tx_full_flag_count1 == 2)begin
                            uart_tx_full_flag_count1   <= 0;
                            uart_tx_full_flag_control1 <= 1'b1;
                        end else
                            uart_tx_full_flag_count1 <= uart_tx_full_flag_count1+1;
                    end                   
//------------------------------------------------------------------------------------------------------------//   
//-------------------------------------------Logic Analyzer---------------------------------------------------//
                end else begin 
                    if(valid && !ready) begin // Logic Analyzer enable
//                       Write fifo data
                        if(wr_en ==1'b1 && wdata[0]) begin
                            i_fifo_wr_en1  <= 1'b1;
                            i_fifo_w_data1 <= compressed_data1;
                        end
//------------------------------------------------------------------------------------------------------------//                                                
//                      Read fifo data
                        if(wr_en ==1'b1 && wdata[4])
                            decompress_data_read_en1 <=  1'b1;      
                    end     
//------------------------------------------------------------------------------------------------------------//                                                                                              
                end                                             
            end
        end
            
endmodule

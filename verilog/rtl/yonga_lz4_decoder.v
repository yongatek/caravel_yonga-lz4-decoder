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

module yonga_lz4_decoder
(                                   
	input wire clk,
	input wire rstn,
	
	input wire i_lz4_decompress_enable,
    input wire lz4_decompress_start,
	
	input wire i_compress_data_write,
    output wire o_compress_fifo_full,
	input wire [7:0] i_compress_data,
		
    input wire i_decompress_data_read,
	output wire o_decompress_fifo_empty,
	output wire [5:0] o_fifo2_data_count,
	output wire [7:0] o_decompress_data,
	
	output wire o_idle
);

	wire [7:0]  i_read_ram_data;	
	wire        o_read_ram_en;      
	wire [6:0]  o_read_ram_address;

	wire        o_write_ram_en;        
	wire [6:0]  o_write_ram_address;    
	wire [7:0]  o_write_ram_data;

	wire        i_fifo1_empty;
	wire        o_fifo1_read;
    wire [7:0]  i_fifo1_compressed_data;
	
	wire        i_fifo2_full;
	wire        o_fifo2_write;
	wire [7:0]  o_fifo2_decompress_data; 
	wire        i_fifo2_almst_full;

    wire [7:0]  temp;
    wire        not_rstn;
          
	yonga_lz4_decoder_controller U1
       (
			.clk 	                 (clk), 	               			
			.rstn				   	 (rstn),				   							 
			.i_lz4_decompress_enable (i_lz4_decompress_enable),
			.lz4_decompress_start    (lz4_decompress_start),   							   
			.i_read_ram_data         (i_read_ram_data),        
			.o_read_ram_en           (o_read_ram_en),         
			.o_read_ram_address      (o_read_ram_address),     							   
			.o_write_ram_en          (o_write_ram_en),         
			.o_write_ram_address     (o_write_ram_address),   
			.o_write_ram_data        (o_write_ram_data),
									
			.i_fifo1_empty           (i_fifo1_empty),   
			.o_fifo1_read            (o_fifo1_read),			
			.i_fifo1_compressed_data (i_fifo1_compressed_data),            
									
	        .i_fifo2_full            (i_fifo2_full),   
	        .i_fifo2_almst_full      (i_fifo2_almst_full),       
            .o_fifo2_write           (o_fifo2_write),
	        .o_fifo2_decompress_data (o_fifo2_decompress_data),
								
			.o_idle                  (o_idle)   			     
		);
		
    dual_ram U2
       (
			.clka    (clk),
			.data_a	 (o_write_ram_data),
			.addr_a  (o_write_ram_address),
			.ena     (1'b1),
			.we_a    (o_write_ram_en),
			.q_a     (),	
			.clkb 	 (clk),
			.data_b	 (temp),
			.addr_b  (o_read_ram_address),
			.enb     (1'b1),
			.we_b    (1'b0),
			.q_b     (i_read_ram_data)		
		);
		
	FIFO_v U3
		(
		    .clk         (clk),   
		    .n_reset     (rstn),  
		    .wr_en       (i_compress_data_write),  
		    .data_in     (i_compress_data),   
		    .rd_en       (o_fifo1_read),  
						 
		    .data_out    (i_fifo1_compressed_data),   
		    .data_count  (),   
		    .empty       (i_fifo1_empty),  
		    .full        (o_compress_fifo_full),   
		    .almst_empty (),   
		    .almst_full  (),   
		    .err         ()   		
		);	

	FIFO_v U4
		(
		    .clk         (clk),   
		    .n_reset     (rstn),  
		    .wr_en       (o_fifo2_write),  
		    .data_in     (o_fifo2_decompress_data),   
		    .rd_en       (i_decompress_data_read),  
						 
		    .data_out    (o_decompress_data),   
		    .data_count  (o_fifo2_data_count),   
		    .empty       (o_decompress_fifo_empty),  
		    .full        (i_fifo2_full),   
		    .almst_empty (),   
		    .almst_full  (i_fifo2_almst_full),   
		    .err         ()   		
		);		
endmodule

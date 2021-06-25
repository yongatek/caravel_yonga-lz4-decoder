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

`timescale 1ns / 1ps

module yonga_lz4_decoder_controller(
	input wire          clk,
	input wire          rstn,
	
	input wire          i_lz4_decompress_enable,         
    input wire          lz4_decompress_start,
	
	output reg          o_read_ram_en,
	input  wire[7:0]    i_read_ram_data,  
	output reg[6:0]     o_read_ram_address,
	
	output reg          o_write_ram_en,
	output reg[6:0]     o_write_ram_address,  
	output reg[7:0]     o_write_ram_data,
	
	input  wire         i_fifo1_empty,
	output reg          o_fifo1_read,  
	input  wire[7:0]    i_fifo1_compressed_data,
	
	input  wire         i_fifo2_full,
	input  wire         i_fifo2_almst_full,  
	output reg          o_fifo2_write,
	output reg[7:0]     o_fifo2_decompress_data,
	
	output reg          o_idle
    );
	
	
////--------------- internal variables ---------------------------------------------------------			
			
			reg  [1:0]     block_size_byte;			
			reg	 [30:0]    block_size_parameter;
				 
			reg	 [16:0]    literal_length_parameter;		
				 	
			reg	 [16:0]    match_length_parameter;
			reg	           match_length_overflow;			
			reg	 	       offset_byte;		
			reg	 [15:0]    offset_parameter;	
			
			reg	[6:0]      write_ram_address_int;
            reg	[6:0]      write_ram_address_ptr;
            reg [6:0]      read_ram_address_int;
			reg [15:0]     offset_count;
			
			reg            read_ram_int;         
			reg            ram_read_request;     
			reg            last_data_read_ram;   
			reg            last_data_write_ram;  
			
			reg [1:0]      end_of_block_byte;
			reg [7:0]      write_ram_data_int;
			
			reg            write_ram_en_int;  
			reg            fifo1_read_int;    
			reg            fifo1_read_request;
			reg            read_fifo_enable;  
			
			reg[3:0] lz4_decompress_state;
			
/*             parameter idle = 10'b0000000001, block_size_assign = 10'b0000000010, block_uncompressed = 10'b0000000100, token_assign = 10'b0000001000, 
                      literal_length_optional = 10'b0000010000, literals_assign = 10'b0000100000, offset_assing = 10'b0001000000,
					  match_length_optional = 10'b0010000000, literals_copy = 10'b0100000000, end_of_block = 10'b1000000000; */
					  
            parameter idle = 1, block_size_assign = 2, block_uncompressed = 3, token_assign = 4, 
                      literal_length_optional = 5, literals_assign = 6, offset_assing = 7,
					  match_length_optional = 8, literals_copy = 9, end_of_block = 10;
//// ------------------------------------------------------------------------------------------------	


//// Control for read fifo
	always @(i_fifo1_empty,read_fifo_enable)
		begin
			if(i_fifo1_empty == 1'b0 && read_fifo_enable == 1'b1)
				fifo1_read_int    = 1'b1;
			else
				fifo1_read_int    = 1'b0;		
		end

	always @ (lz4_decompress_state,offset_byte,match_length_overflow,i_fifo1_compressed_data,end_of_block_byte,
			  fifo1_read_request,i_fifo2_almst_full,last_data_write_ram)
		begin
			if(offset_byte == 1'b1  && match_length_overflow ==  1'b0 && fifo1_read_request == 1'b1)
				read_fifo_enable = 1'b0;		
			else if(lz4_decompress_state == token_assign  &&  i_fifo1_compressed_data[7:4] != 4'b1111  && i_fifo2_almst_full == 1'b1 && fifo1_read_request == 1'b1)
				read_fifo_enable = 1'b0;
			else if(lz4_decompress_state == literal_length_optional  &&  i_fifo1_compressed_data[7:0] != 8'b11111111  && i_fifo2_almst_full == 1'b1 && fifo1_read_request == 1'b1) 
				read_fifo_enable = 1'b0;
			else if(lz4_decompress_state == literals_assign  && i_fifo2_almst_full == 1'b1)
				read_fifo_enable = 1'b0;	
			else if(lz4_decompress_state == match_length_optional  && i_fifo1_compressed_data[7:0] != 8'b11111111 && fifo1_read_request == 1'b1)
				read_fifo_enable = 1'b0;
			else if(lz4_decompress_state == literals_copy  && last_data_write_ram == 1'b0)
				read_fifo_enable = 1'b0;
			else if(end_of_block_byte == 2'b11  && fifo1_read_request == 1'b1)
				read_fifo_enable = 1'b0;
			else
				read_fifo_enable = 1'b1;
        end
//// --------------------------------------------------------------------------------------------------

//// Connect internal regs to ouput ports
	always @ (write_ram_data_int,write_ram_en_int,read_ram_address_int,read_ram_int,fifo1_read_int)
		begin
			o_fifo2_decompress_data = write_ram_data_int;
			o_fifo2_write           = write_ram_en_int;
			
			o_write_ram_en          = write_ram_en_int;
			o_write_ram_data        = write_ram_data_int;
			
			o_read_ram_address      = read_ram_address_int;
			o_read_ram_en           = read_ram_int;
			
			o_fifo1_read            = fifo1_read_int;
		end
//// --------------------------------------------------------------------------------------------------

//// LZ4 Decompress State Machine
	always @(posedge clk or negedge rstn)
		begin
			if(rstn == 1'b0)
				begin
					o_idle                   <= 1'b1;
				    last_data_write_ram      <= 1'b0;
				    match_length_overflow    <= 1'b0;
                    offset_byte              <= 1'b0;
                    read_ram_int             <= 1'b0;
                    ram_read_request         <= 1'b0;
                    last_data_read_ram       <= 1'b0;
                    block_size_byte          <= 0;
                    block_size_parameter     <= 0;
                    literal_length_parameter <= 0;
                    match_length_parameter   <= 0;
                    offset_parameter         <= 0;
                    write_ram_address_int    <= 0;
                    write_ram_address_ptr    <= 0;
                    read_ram_address_int     <= 0;
                    offset_count      <= 0;
				    end_of_block_byte        <= 0;
				    o_write_ram_address      <= 0;
				    write_ram_en_int         <= 1'b0;
				    fifo1_read_request       <= 1'b0;	
				    write_ram_data_int       <= 0;
				    lz4_decompress_state	 <= idle;
				end
			else
				begin
					last_data_read_ram   <= 1'b0;
					write_ram_en_int     <= 1'b0;
					read_ram_int         <= 1'b0;
					
					ram_read_request     <= read_ram_int;		
					fifo1_read_request   <= fifo1_read_int;
					
					last_data_write_ram  <= last_data_read_ram;
					o_write_ram_address  <= write_ram_address_int;	
					
					case(lz4_decompress_state)
					
						idle:							
						   begin	
						    o_idle <= 1'b1;
						    write_ram_address_int <= 0;	
						    read_ram_address_int  <= 0;
							if(i_fifo1_empty == 1'b0)
								begin
							        o_idle <= 1'b0;
									lz4_decompress_state <= block_size_assign;													
								end			  
						   end
						   
						block_size_assign:
							    
							if(fifo1_read_request == 1'b1)
								begin
									case(block_size_byte)
										2'b00  :
											begin
												block_size_byte <= 1;
												block_size_parameter[7:0] <= i_fifo1_compressed_data;	
											end
										2'b01  :
											begin
												block_size_byte <= 2;
												block_size_parameter[15:8] <= i_fifo1_compressed_data;	
											end																				
										2'b10  :
											begin
												block_size_byte <= 3;
												block_size_parameter[23:16] <= i_fifo1_compressed_data;	
											end										
										2'b11  :
											begin
												block_size_byte <= 0;
												block_size_parameter[30:24] <= i_fifo1_compressed_data;
													if(i_fifo1_compressed_data[7] == 1'b0)	//block is compressed												
														lz4_decompress_state <= token_assign;									
													else // block is uncompressed.
														lz4_decompress_state <=  block_uncompressed;		
											end	
									endcase								
							    end
							
						token_assign:
							if(fifo1_read_request == 1'b1)
								begin
									lz4_decompress_state <= literals_assign;
									block_size_parameter <= block_size_parameter -1;
									
									literal_length_parameter[3:0] <= i_fifo1_compressed_data[7:4];
									match_length_parameter        <= i_fifo1_compressed_data[3:0] + 4;
									
									if(i_fifo1_compressed_data[7:4] ==  4'b1111)
										lz4_decompress_state <= literal_length_optional;							
									
									if(i_fifo1_compressed_data[3:0] ==  4'b1111)
										match_length_overflow <= 1'b1;															
								end 								

						literal_length_optional:
							if(fifo1_read_request == 1'b1)
								begin
									literal_length_parameter <= literal_length_parameter +  i_fifo1_compressed_data;
									block_size_parameter <= block_size_parameter -1;
									if(i_fifo1_compressed_data[7:0] != 8'b11111111)
										lz4_decompress_state <= literals_assign;									
								end 

						literals_assign	:
							if(fifo1_read_request == 1'b1)
								begin
									write_ram_en_int        <= 1'b1;
									block_size_parameter    <= block_size_parameter -1;
									write_ram_data_int      <= i_fifo1_compressed_data;
									if (write_ram_address_int == 127) 
										write_ram_address_int   <= 0;
									else
										write_ram_address_int   <= write_ram_address_int +1;									
									
									if(literal_length_parameter == 1'b1 && block_size_parameter == 1)
										begin
											lz4_decompress_state     <= end_of_block;
											literal_length_parameter <= 0;
										end
									else if(literal_length_parameter == 1'b1)
									    begin
											lz4_decompress_state     <= offset_assing;
                                            literal_length_parameter <= 0;									    
									    end
									else
										literal_length_parameter <= literal_length_parameter - 1;																							
						    	end 
								
						offset_assing:	
							if(fifo1_read_request == 1'b1)
							    begin
									write_ram_address_ptr  <= write_ram_address_int;
									block_size_parameter   <= block_size_parameter -1; 
									case (offset_byte)
										1'b0  :
										    begin
											    offset_byte <= 1'b1;
											    offset_parameter[7:0] <= i_fifo1_compressed_data; 	
											end							
										1'b1  :
											begin												    								 	
												offset_byte <= 1'b0;
												offset_parameter[15:8] <= i_fifo1_compressed_data; 
												if(offset_parameter[7:0] == 0 && i_fifo1_compressed_data == 0 && block_size_parameter == 1)
													lz4_decompress_state <= end_of_block;
												else if(offset_parameter[7:0] == 0 && i_fifo1_compressed_data == 0 && block_size_parameter != 1)
													lz4_decompress_state <= token_assign;
												else
													begin
														if(match_length_overflow == 1'b1)
															lz4_decompress_state <= match_length_optional;
														else
															lz4_decompress_state <= literals_copy;
													end	
                                                	
                                            end												
									endcase
								end 	
								
						match_length_optional:
							if(fifo1_read_request == 1'b1)					
								begin
									match_length_parameter <= match_length_parameter +  i_fifo1_compressed_data;
									block_size_parameter <= block_size_parameter -1;									
									if(i_fifo1_compressed_data[7:0] != 8'b11111111)
										lz4_decompress_state <= literals_copy;									
								end 
								
						literals_copy:
						    begin
								if(i_fifo2_almst_full == 1'b0)
									begin
										if(match_length_parameter != 0)
											begin
												match_length_parameter <= match_length_parameter -1;
												if (match_length_parameter == 1)
													last_data_read_ram  <= 1'b1;
																																			
												if(offset_count == 0 || offset_parameter == 1 )
													begin
														read_ram_int <= 1'b1;
														
														if(write_ram_address_ptr >= offset_parameter)
															read_ram_address_int  <= write_ram_address_ptr - offset_parameter;
														else
															read_ram_address_int  <= 128 -  offset_parameter + write_ram_address_ptr;
															
														if(offset_parameter == 1)
                                                            offset_count   <= 0; 
                                                        else   
                                                        	offset_count   <= offset_count +1; 
													end
													
												else if(offset_count < offset_parameter)
													begin
														read_ram_int <= 1'b1;
														offset_count  <= offset_count +1;
														
														if(read_ram_address_int == 127) 
															read_ram_address_int <= 0;
														else									
															read_ram_address_int <= read_ram_address_int + 1;
																																								
														if(offset_count == offset_parameter-1)
															     offset_count <= 0;																							
													end 
													
											end 
									end 
									
								if(ram_read_request == 1'b1)	
									begin
										write_ram_en_int        <= 1'b1;
										write_ram_data_int      <= i_read_ram_data;
										if (write_ram_address_int == 127)
											write_ram_address_int   <= 0;
										else
											write_ram_address_int   <= write_ram_address_int +1;
									end	
								
									
								if(last_data_write_ram == 1'b1)
									begin
										offset_count <= 0;
										if(block_size_parameter == 0)
											lz4_decompress_state <= end_of_block;
										else
											lz4_decompress_state <= token_assign;
									end 		
							end
							
						block_uncompressed:
							if(fifo1_read_request == 1'b1)
								begin
									write_ram_en_int        <= 1'b1;
									write_ram_data_int      <= i_fifo1_compressed_data;	
									if (write_ram_address_int == 127)
										write_ram_address_int   <= 0;
									else
										write_ram_address_int   <= write_ram_address_int +1;
									
									if(block_size_parameter == 1)
										lz4_decompress_state <= end_of_block;
									else
										block_size_parameter <= block_size_parameter -1;													
						        end
								
						end_of_block:
							if(i_fifo1_compressed_data == 0 && fifo1_read_request == 1'b1) // 4 byte zero	
								begin
									case (end_of_block_byte)
										2'b00  :
											end_of_block_byte <= 1;
										2'b01  :		
											end_of_block_byte <= 2;
										2'b10  : 
											end_of_block_byte <= 3;
										2'b11  : 
											begin
												end_of_block_byte <= 0;
												lz4_decompress_state <= idle;
											end
									endcase
							    end 																
					endcase	
				end	
		end
//// ------------------------------------------------------------------------------------------------
endmodule

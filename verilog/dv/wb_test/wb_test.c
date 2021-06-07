/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// updated on 210604

// This include is relative to $CARAVEL_PATH (see Makefile)
#include "verilog/dv/caravel/defs.h"
#include "verilog/dv/caravel/stub.c"

/*
	Wishbone Test:
		- Checks YONGA LZ4 Decoder functionality through the wishbone port
*/

int i = 0; 
int clk = 0;

int yonga_lz4_decoder_status;

#define NUM_OF_INPUT_ELEMENTS 25
#define NUM_OF_OUTPUT_ELEMENTS 32

void read_yonga_lz4_decoder_status();

void main()
{

	int yonga_lz4_decoder_test_seq[NUM_OF_INPUT_ELEMENTS];
	yonga_lz4_decoder_test_seq[0] = 0x11;
	yonga_lz4_decoder_test_seq[1] = 0x00;
	yonga_lz4_decoder_test_seq[2] = 0x00;
	yonga_lz4_decoder_test_seq[3] = 0x00;
	yonga_lz4_decoder_test_seq[4] = 0x44;
	yonga_lz4_decoder_test_seq[5] = 0x41;
	yonga_lz4_decoder_test_seq[6] = 0x42;
	yonga_lz4_decoder_test_seq[7] = 0x43;
	yonga_lz4_decoder_test_seq[8] = 0x44;
	yonga_lz4_decoder_test_seq[9] = 0x04;
	yonga_lz4_decoder_test_seq[10] = 0x00;
	yonga_lz4_decoder_test_seq[11] = 0x1a;
	yonga_lz4_decoder_test_seq[12] = 0x43;
	yonga_lz4_decoder_test_seq[13] = 0x01;
	yonga_lz4_decoder_test_seq[14] = 0x00;
	yonga_lz4_decoder_test_seq[15] = 0x50;
	yonga_lz4_decoder_test_seq[16] = 0x43;
	yonga_lz4_decoder_test_seq[17] = 0x43;
	yonga_lz4_decoder_test_seq[18] = 0x43;
	yonga_lz4_decoder_test_seq[19] = 0x43;
	yonga_lz4_decoder_test_seq[20] = 0x0a;
	yonga_lz4_decoder_test_seq[21] = 0x00;
	yonga_lz4_decoder_test_seq[22] = 0x00;
	yonga_lz4_decoder_test_seq[23] = 0x00;
	yonga_lz4_decoder_test_seq[24] = 0x00;

	int yonga_lz4_decoder_expected_result_seq[NUM_OF_OUTPUT_ELEMENTS];
	yonga_lz4_decoder_expected_result_seq[0] = 0x41;
	yonga_lz4_decoder_expected_result_seq[1] = 0x42;
	yonga_lz4_decoder_expected_result_seq[2] = 0x43;
	yonga_lz4_decoder_expected_result_seq[3] = 0x44;
	yonga_lz4_decoder_expected_result_seq[4] = 0x41;
	yonga_lz4_decoder_expected_result_seq[5] = 0x42;
	yonga_lz4_decoder_expected_result_seq[6] = 0x43;
	yonga_lz4_decoder_expected_result_seq[7] = 0x44;
	yonga_lz4_decoder_expected_result_seq[8] = 0x41;
	yonga_lz4_decoder_expected_result_seq[9] = 0x42;
	yonga_lz4_decoder_expected_result_seq[10] = 0x43;
	yonga_lz4_decoder_expected_result_seq[11] = 0x44;
	yonga_lz4_decoder_expected_result_seq[12] = 0x43;
	yonga_lz4_decoder_expected_result_seq[13] = 0x43;
	yonga_lz4_decoder_expected_result_seq[14] = 0x43;
	yonga_lz4_decoder_expected_result_seq[15] = 0x43;
	yonga_lz4_decoder_expected_result_seq[16] = 0x43;
	yonga_lz4_decoder_expected_result_seq[17] = 0x43;
	yonga_lz4_decoder_expected_result_seq[18] = 0x43;
	yonga_lz4_decoder_expected_result_seq[19] = 0x43;
	yonga_lz4_decoder_expected_result_seq[20] = 0x43;
	yonga_lz4_decoder_expected_result_seq[21] = 0x43;
	yonga_lz4_decoder_expected_result_seq[22] = 0x43;
	yonga_lz4_decoder_expected_result_seq[23] = 0x43;
	yonga_lz4_decoder_expected_result_seq[24] = 0x43;
	yonga_lz4_decoder_expected_result_seq[25] = 0x43;
	yonga_lz4_decoder_expected_result_seq[26] = 0x43;
	yonga_lz4_decoder_expected_result_seq[27] = 0x43;
	yonga_lz4_decoder_expected_result_seq[28] = 0x43;
	yonga_lz4_decoder_expected_result_seq[29] = 0x43;
	yonga_lz4_decoder_expected_result_seq[30] = 0x43;
	yonga_lz4_decoder_expected_result_seq[31] = 0x0a;

	int yonga_lz4_decoder_actual_result_seq[NUM_OF_OUTPUT_ELEMENTS];

	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

	reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

    reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // Configure LA probes
	reg_la0_oenb = reg_la0_iena = 0x00000000;    // [31:0]
	reg_la1_oenb = reg_la1_iena = 0xFFFFFFFF;    // [63:32]
	reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF;    // [95:64]
	reg_la3_oenb = reg_la3_iena = 0xFFFFFFFF;    // [127:96]

	// Flag start of the test
	reg_mprj_datal = 0xAB600000;

	reg_mprj_slave = 0x200; // enable WB mode

	int idx_i = 0;
	int idx_o = 0;

	int yonga_lz4_decoder_is_idle_mask = 0x1;
	int yonga_lz4_decoder_o_fifo_is_empty_mask = 0x10;
	int yonga_lz4_decoder_o_fifo_is_almost_full_mask = 0x100;
	int yonga_lz4_decoder_i_fifo_is_full_mask = 0x1000;

	read_yonga_lz4_decoder_status();
	// Send 1 byte to i_fifo in the first place to run the decoder
	if((yonga_lz4_decoder_status & yonga_lz4_decoder_is_idle_mask) == 0x1){
	  reg_la0_data = yonga_lz4_decoder_test_seq[idx_i++];
	  reg_mprj_slave = 0x01; // Write 1 byte to i_fifo
	}

	read_yonga_lz4_decoder_status();
	while((yonga_lz4_decoder_status & yonga_lz4_decoder_is_idle_mask) == 0x0){ // Check whether the decoder is running or not
	  if(yonga_lz4_decoder_status & yonga_lz4_decoder_o_fifo_is_almost_full_mask){ // Check if the decoder of o_fifo is almost full
	  	while((yonga_lz4_decoder_status & yonga_lz4_decoder_o_fifo_is_empty_mask) == 0x0){
	  		reg_mprj_slave = 0x10; // Read 1 byte from o_fifo
	  		yonga_lz4_decoder_actual_result_seq[idx_o++] = reg_la1_data; // Result is read from LA
	  		read_yonga_lz4_decoder_status();
	  	}
	  }
	  else if((yonga_lz4_decoder_status & yonga_lz4_decoder_i_fifo_is_full_mask) == 0x0){
	  	reg_la0_data = yonga_lz4_decoder_test_seq[idx_i++];
	  	reg_mprj_slave = 0x01; // Write 1 byte to i_fifo
	  }
	  read_yonga_lz4_decoder_status();
	}

	read_yonga_lz4_decoder_status();
	if((yonga_lz4_decoder_status & yonga_lz4_decoder_o_fifo_is_empty_mask) == 0x0){
		while((yonga_lz4_decoder_status & yonga_lz4_decoder_o_fifo_is_empty_mask) == 0x0){
	  		reg_mprj_slave = 0x10; // Read 1 byte from o_fifo
	  		yonga_lz4_decoder_actual_result_seq[idx_o++] = reg_la1_data; // Result is read from LA
	  		read_yonga_lz4_decoder_status();
	  	}
	}

	// Verify the result
	for(idx_o = 0; idx_o < NUM_OF_OUTPUT_ELEMENTS; idx_o++){
		if(yonga_lz4_decoder_actual_result_seq[idx_o] != yonga_lz4_decoder_expected_result_seq[idx_o]){
			// Flag end of the test
			reg_mprj_datal = 0xAB600000;
			break;
		}
	}
	
	// Flag end of the test
	if(idx_o == NUM_OF_OUTPUT_ELEMENTS){
		reg_mprj_datal = 0xAB610000;
	}

	// Run forever
  while(1);
}

void read_yonga_lz4_decoder_status()
{

  yonga_lz4_decoder_status = reg_mprj_slave;

}

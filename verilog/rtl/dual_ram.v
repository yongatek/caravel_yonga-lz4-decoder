module dual_ram
(	                    
	input [7:0] data_a, data_b,
	input [6:0] addr_a, addr_b,
	input we_a, we_b, clka, clkb, ena, enb, 
	output reg [7:0] q_a, q_b
);
	// Declare the RAM variable
	(* ram_style="distributed" *) // distributed -- block
	reg [7:0] ram[127:0];
	// Port A
	always @ (posedge clka)//write
	begin
		//if (ena) 
		//begin
			if (we_a) begin
				ram[addr_a] <= data_a;			
			//else
				//q_a <= ram[addr_a];
		end
	end
	
	// Port B
	always @ (posedge clkb) //read
	begin
		//if (enb) 
		//begin
			//if (we_b)
				//ram[addr_b] <= data_b;				
			//else
				q_b <= ram[addr_b];
		//end
	end
	
endmodule

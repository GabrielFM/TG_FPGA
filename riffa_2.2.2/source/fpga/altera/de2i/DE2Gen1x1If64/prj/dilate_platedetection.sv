
`include "defines_platedetection.svh"

module dilate_platedetection
	(	input clk,
		input i_reset,	
		
		input i_pixels_data_valid,
		input [`DATA_WIDTH-1:0] i_pixels_data,
				
		output reg [`DATA_WIDTH-1:0] o_pixels_data,
		output reg o_pixels_data_valid,
		output reg o_end_dilate	
	);
		
	reg [(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:0]r_data_L0;
	reg [(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:0]r_data_L1;
	
	reg [`LOG2_NUM_WORDS_FIFO-1:0]r_contador_data_pixels;
	reg [`LOG2_NUM_WORDS_FIFO-1:0]r_contador_data_pixels_line;
	
	wire [`PIXEL_IN_WIDTH-1:0] w_pixels_data_valid;	
	
	reg [`DATA_WIDTH-1:0] r_pixel_up;
	reg [`DATA_WIDTH-1:0] r_pixel_down;
	reg [`DATA_WIDTH-1:0] r_pixel_left;
	reg [`DATA_WIDTH-1:0] r_pixel_right;
	reg [`DATA_WIDTH-1:0] r_pixel_center;
	
	reg r_pixels_data_valid;
	reg r_pixels_data_valid_1;
	
	reg [`DATA_WIDTH-1:0] r_pixels_data;
	
	enum {	
		bit_wait_line_1             				=0,
		bit_process_dilate_pixel_0     				=1,
		bit_process_dilate_line     				=2,
		bit_process_dilate_pixel_final     			=3,
		bit_process_dilate_line_final_pixel_0     	=4,
		bit_process_dilate_line_final     			=5,
		bit_process_dilate_line_final_pixel_final 	=6,
		bit_wait_finished_dilate				 	=7
		} state_bit;	
			
	enum logic[7:0]{
		state_wait_line_1             				= 8'd1 << bit_wait_line_1,
		state_process_dilate_pixel_0             	= 8'd1 << bit_process_dilate_pixel_0,
		state_process_dilate_line             		= 8'd1 << bit_process_dilate_line,
		state_process_dilate_pixel_final            = 8'd1 << bit_process_dilate_pixel_final,
		state_process_dilate_line_final_pixel_0     = 8'd1 << bit_process_dilate_line_final_pixel_0,
		state_process_dilate_line_final            	= 8'd1 << bit_process_dilate_line_final,
		state_process_dilate_line_final_pixel_final	= 8'd1 << bit_process_dilate_line_final_pixel_final,
		state_wait_finished_dilate					= 8'd1 << bit_wait_finished_dilate
		} r_state_UC_dilate, w_next_state_UC_dilate;	
	
	genvar Iter;
	
	generate
				
		for(Iter = 0; Iter < `NUM_PIXEL_CHANEL_IN; Iter += 1) begin:PE
					  
			dilate_kernel_platedetection dilate_kernel_platedetection_i (	.clk(clk),
																			.i_start_kernel(r_pixels_data_valid_1),
																			.i_pixel_up(r_pixel_up[(`PIXEL_IN_WIDTH*(Iter+1))-1:`PIXEL_IN_WIDTH*Iter]),
																			.i_pixel_down(r_pixel_down[(`PIXEL_IN_WIDTH*(Iter+1))-1:`PIXEL_IN_WIDTH*Iter]),
																			.i_pixel_left(r_pixel_left[(`PIXEL_IN_WIDTH*(Iter+1))-1:`PIXEL_IN_WIDTH*Iter]),	
																			.i_pixel_right(r_pixel_right[(`PIXEL_IN_WIDTH*(Iter+1))-1:`PIXEL_IN_WIDTH*Iter]),	
																			.i_pixel_center(r_pixel_center[(`PIXEL_IN_WIDTH*(Iter+1))-1:`PIXEL_IN_WIDTH*Iter]),	
																			
																			.o_pixel_dilate(o_pixels_data[(`PIXEL_IN_WIDTH*(Iter+1))-1:`PIXEL_IN_WIDTH*Iter]),
																			.o_end_kernel(w_pixels_data_valid[Iter]));	
		end		
		
	endgenerate	

	assign o_pixels_data_valid = w_pixels_data_valid[0];
	
	always_comb begin
		
		unique case(1'b1)
										
			r_state_UC_dilate[bit_wait_line_1]: 
				if(r_contador_data_pixels_line < `NUM_WORDS_LINE_DILATE-1)
					w_next_state_UC_dilate <= state_wait_line_1;
				else
					w_next_state_UC_dilate <= state_process_dilate_pixel_0;
							
			r_state_UC_dilate[bit_process_dilate_pixel_0]:
				if(r_pixels_data_valid)
					w_next_state_UC_dilate <= state_process_dilate_line;
				else
					w_next_state_UC_dilate <= state_process_dilate_pixel_0;
				
			r_state_UC_dilate[bit_process_dilate_line]:
				if(r_contador_data_pixels_line < `NUM_WORDS_LINE_DILATE-2)
					w_next_state_UC_dilate <= state_process_dilate_line;
				else
					w_next_state_UC_dilate <= state_process_dilate_pixel_final;
				
			r_state_UC_dilate[bit_process_dilate_pixel_final]:
				if(r_contador_data_pixels < `NUM_WORDS_FIFO-`NUM_WORDS_LINE_DILATE)
					w_next_state_UC_dilate <= state_process_dilate_pixel_0;
				else
					w_next_state_UC_dilate <= state_process_dilate_line_final_pixel_0;
				
			r_state_UC_dilate[bit_process_dilate_line_final_pixel_0]:
					w_next_state_UC_dilate <= state_process_dilate_line_final;
				
			r_state_UC_dilate[bit_process_dilate_line_final]:
				if(r_contador_data_pixels_line < `NUM_WORDS_LINE_DILATE-2)
					w_next_state_UC_dilate <= state_process_dilate_line_final;
				else
					w_next_state_UC_dilate <= state_process_dilate_line_final_pixel_final;
				
			r_state_UC_dilate[bit_process_dilate_line_final_pixel_final]:
					w_next_state_UC_dilate <= state_wait_finished_dilate;
			
			r_state_UC_dilate[bit_wait_finished_dilate]:
				if(w_pixels_data_valid[0])
					w_next_state_UC_dilate <= state_wait_finished_dilate;
				else
					w_next_state_UC_dilate <= state_wait_line_1;
				
			default:
				w_next_state_UC_dilate <= state_wait_line_1;	
				
		endcase

	end
	
	always_ff @(posedge clk  or posedge i_reset)begin 
		
		r_pixels_data_valid <= i_pixels_data_valid;
		r_pixels_data <= i_pixels_data;
		
		if(i_reset) begin

			r_data_L0 <= 0;
			r_data_L1 <= 0;
				
			r_contador_data_pixels <= `NUM_WORDS_LINE_DILATE;
			r_contador_data_pixels_line <= 0;
							
			r_pixel_up <= 0;
			r_pixel_down <= 0;
			r_pixel_left <= 0;
			r_pixel_right <= 0;
			r_pixel_center <= 0;
				
			r_pixels_data_valid_1 <= 0;
			
			o_end_dilate <= 0;
			
			r_state_UC_dilate <= state_wait_line_1;
		end
		else begin
		
			r_state_UC_dilate <= w_next_state_UC_dilate;
			
			unique case(1'b1)	
				
				
				r_state_UC_dilate[bit_wait_line_1]: begin	
										
					r_data_L0 <= r_pixels_data_valid ? {r_data_L1[`DATA_WIDTH-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L0;
					r_data_L1 <= r_pixels_data_valid ? {r_pixels_data[`DATA_WIDTH-1:0],r_data_L1[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L1;
					
						
					r_contador_data_pixels <= `NUM_WORDS_LINE_DILATE;
					r_contador_data_pixels_line <= r_pixels_data_valid ? r_contador_data_pixels_line + 1: r_contador_data_pixels_line;
									
					r_pixel_up <= 0;
					r_pixel_down <= 0;
					r_pixel_left <= 0;
					r_pixel_right <= 0;
					r_pixel_center <= 0;
						
					r_pixels_data_valid_1 <= 0;
					
					o_end_dilate <= 0;
					
				end		
				
				r_state_UC_dilate[bit_process_dilate_pixel_0]: begin		

					r_data_L0 <= r_pixels_data_valid ? {r_data_L1[`DATA_WIDTH-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L0;
					r_data_L1 <= r_pixels_data_valid ? {r_pixels_data[`DATA_WIDTH-1:0],r_data_L1[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L1;
					
						
					r_contador_data_pixels <= r_contador_data_pixels;
					r_contador_data_pixels_line <= 1;
									
					r_pixel_up     <= r_pixels_data_valid ? r_data_L0[`DATA_WIDTH-1:0] : r_pixel_up;
					r_pixel_down   <= r_pixels_data_valid ? r_pixels_data[`DATA_WIDTH-1:0] : r_pixel_down;
					
					r_pixel_left   <= r_pixels_data_valid ? {r_data_L1[(`DATA_WIDTH+`PIXEL_IN_WIDTH)-1:`DATA_WIDTH],r_data_L1[`DATA_WIDTH-1:`PIXEL_IN_WIDTH]} : r_pixel_left;
					r_pixel_right  <= r_pixels_data_valid ? {r_data_L1[(`DATA_WIDTH-`PIXEL_IN_WIDTH)-1:0],8'd0} : r_pixel_right;
					
					r_pixel_center <= r_pixels_data_valid ? r_data_L1[`DATA_WIDTH-1:0] : r_pixel_center;
						
					r_pixels_data_valid_1 <= r_pixels_data_valid;
					
					o_end_dilate <= 0;

				end		
							
				r_state_UC_dilate[bit_process_dilate_line]: begin					
					r_data_L0 <= r_pixels_data_valid ? {r_data_L1[`DATA_WIDTH-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L0;
					r_data_L1 <= r_pixels_data_valid ? {r_pixels_data[`DATA_WIDTH-1:0],r_data_L1[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L1;
					
					r_contador_data_pixels <= r_contador_data_pixels;
					r_contador_data_pixels_line <= r_pixels_data_valid ? r_contador_data_pixels_line + 1: r_contador_data_pixels_line;
					
					r_pixel_up     <= r_pixels_data_valid ? r_data_L0[`DATA_WIDTH-1:0] : r_pixel_up;
					r_pixel_down   <= r_pixels_data_valid ? r_pixels_data[`DATA_WIDTH-1:0] : r_pixel_down;
					
					r_pixel_left   <= r_pixels_data_valid ? {r_data_L1[(`DATA_WIDTH+`PIXEL_IN_WIDTH)-1:`DATA_WIDTH],r_data_L1[`DATA_WIDTH-1:`PIXEL_IN_WIDTH]} : r_pixel_left;
					r_pixel_right  <= r_pixels_data_valid ? {r_data_L1[(`DATA_WIDTH-`PIXEL_IN_WIDTH)-1:0], r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-`PIXEL_IN_WIDTH]} : r_pixel_right;
					
					r_pixel_center <= r_pixels_data_valid ? r_data_L1[`DATA_WIDTH-1:0] : r_pixel_center;

					r_pixels_data_valid_1 <= r_pixels_data_valid;
					
					o_end_dilate <= 0;
					
				end			
						
				r_state_UC_dilate[bit_process_dilate_pixel_final]: begin					
					
					r_data_L0 <= r_pixels_data_valid ? {r_data_L1[`DATA_WIDTH-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L0;
					r_data_L1 <= r_pixels_data_valid ? {r_pixels_data[`DATA_WIDTH-1:0],r_data_L1[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]} : r_data_L1;
					
					r_contador_data_pixels <= r_pixels_data_valid ? r_contador_data_pixels + `NUM_WORDS_LINE_DILATE: r_contador_data_pixels;;
					r_contador_data_pixels_line <= r_pixels_data_valid ? r_contador_data_pixels_line + 1: r_contador_data_pixels_line;
					
					r_pixel_up     <= r_pixels_data_valid ? r_data_L0[`DATA_WIDTH-1:0] : r_pixel_up;
					r_pixel_down   <= r_pixels_data_valid ? r_pixels_data[`DATA_WIDTH-1:0] : r_pixel_down;
					
					r_pixel_left   <= r_pixels_data_valid ? {8'd0,r_data_L1[`DATA_WIDTH-1:`PIXEL_IN_WIDTH]} : r_pixel_left;
					r_pixel_right  <= r_pixels_data_valid ? {r_data_L1[(`DATA_WIDTH-`PIXEL_IN_WIDTH)-1:0], r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-`PIXEL_IN_WIDTH]} : r_pixel_right;
					
					r_pixel_center <= r_pixels_data_valid ? r_data_L1[`DATA_WIDTH-1:0] : r_pixel_center;
					
					r_pixels_data_valid_1 <= r_pixels_data_valid;
					
					o_end_dilate <= 0;
					
				end	
				
				r_state_UC_dilate[bit_process_dilate_line_final_pixel_0]: begin					
					
					r_data_L0 <= {r_data_L1[`DATA_WIDTH-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]};
					r_data_L1 <= {64'd0,r_data_L1[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]};
					
					r_contador_data_pixels <= r_contador_data_pixels;
					r_contador_data_pixels_line <= 1;
					
					r_pixel_up     <= r_data_L0[`DATA_WIDTH-1:0];
					r_pixel_down   <= 64'd0;
					
					r_pixel_left   <= {r_data_L1[(`DATA_WIDTH+`PIXEL_IN_WIDTH)-1:`DATA_WIDTH],r_data_L1[`DATA_WIDTH-1:`PIXEL_IN_WIDTH]};
					r_pixel_right  <= {r_data_L1[(`DATA_WIDTH-`PIXEL_IN_WIDTH)-1:0],8'd0};
					
					r_pixel_center <= r_data_L1[`DATA_WIDTH-1:0];
					
					r_pixels_data_valid_1 <= 1'b1;
					
					o_end_dilate <= 0;
					
				end	
								
				r_state_UC_dilate[bit_process_dilate_line_final]: begin					
					
					r_data_L0 <= {r_data_L1[`DATA_WIDTH-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]};
					r_data_L1 <= {64'd0,r_data_L1[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:`DATA_WIDTH]};
					
					r_contador_data_pixels <= r_contador_data_pixels;
					r_contador_data_pixels_line <= 1'b1 ? r_contador_data_pixels_line + 1: r_contador_data_pixels_line;
					
					r_pixel_up     <= r_data_L0[`DATA_WIDTH-1:0];
					r_pixel_down   <= 64'd0;
					
					r_pixel_left   <= {r_data_L1[(`DATA_WIDTH+`PIXEL_IN_WIDTH)-1:`DATA_WIDTH],r_data_L1[`DATA_WIDTH-1:`PIXEL_IN_WIDTH]};
					r_pixel_right  <= {r_data_L1[(`DATA_WIDTH-`PIXEL_IN_WIDTH)-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-`PIXEL_IN_WIDTH]};
					
					r_pixel_center <= r_data_L1[`DATA_WIDTH-1:0];
					
					r_pixels_data_valid_1 <= 1'b1;	
					
					o_end_dilate <= 0;
					
				end	
												
				r_state_UC_dilate[bit_process_dilate_line_final_pixel_final]: begin					
					
					r_data_L0 <= 0;
					r_data_L1 <= 0;
					
					r_contador_data_pixels <= `NUM_WORDS_LINE_DILATE;
					r_contador_data_pixels_line <= 0;
					
					r_pixel_up     <= r_data_L0[`DATA_WIDTH-1:0];
					r_pixel_down   <= 64'd0;
					
					r_pixel_left   <= {8'd0,r_data_L1[`DATA_WIDTH-1:`PIXEL_IN_WIDTH]};
					r_pixel_right  <= {r_data_L1[(`DATA_WIDTH-`PIXEL_IN_WIDTH)-1:0],r_data_L0[(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-1:(`WIDTH_FRAME*`PIXEL_IN_WIDTH)-`PIXEL_IN_WIDTH]};
					
					r_pixel_center <= r_data_L1[`DATA_WIDTH-1:0];
					
					r_pixels_data_valid_1 <= 1'b1;	
					
					o_end_dilate <= 1;
					
				end	
				
				r_state_UC_dilate[bit_wait_finished_dilate]: begin					
					
					r_data_L0 <= 0;
					r_data_L1 <= 0;
					
						
					r_contador_data_pixels <= `NUM_WORDS_LINE_DILATE;
					r_contador_data_pixels_line <= 0;
					
					r_pixel_up <= 0;
					r_pixel_down <= 0;
					r_pixel_left <= 0;
					r_pixel_right <= 0;
					r_pixel_center <= 0;
						
					r_pixels_data_valid_1 <= 0;
					
					o_end_dilate <= 1;
					
				end	
											
				default: begin		
					r_data_L0 <= 0;
					r_data_L1 <= 0;
						
					r_contador_data_pixels <= `NUM_WORDS_LINE_DILATE;
					r_contador_data_pixels_line <= 0;
									
					r_pixel_up <= 0;
					r_pixel_down <= 0;
					r_pixel_left <= 0;
					r_pixel_right <= 0;
					r_pixel_center <= 0;
						
					r_pixels_data_valid_1 <= 0;
					
					o_end_dilate <= 0;
					
				end
				
			endcase
		
		end
	
	end

endmodule
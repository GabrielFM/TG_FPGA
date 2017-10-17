
`include "defines_platedetection.svh"

module control_unit_platedetection
	(	input clk,
		input i_reset,
		
		// interface RX do Riffa
		input i_channel_rx, 
		input i_channel_rx_last, 
		input [31:0] i_channel_rx_length, 
		input [30:0] i_channel_rx_offset,
		input [`DATA_WIDTH-1:0] i_channel_rx_data,
		input i_channel_rx_data_valid,
		
		output o_channel_rx_clk,
		output o_channel_rx_ack,
		output o_channel_rx_data_ren,
		
		// interface TX do Riffa
		input i_channel_tx_ack, 
		input i_channel_tx_data_ren,
				
		output o_channel_tx_clk, 
		output o_channel_tx, 
		output o_channel_tx_last, 
		output [31:0] o_channel_tx_length, 
		output [30:0] o_channel_tx_offset, 
		output [`DATA_WIDTH-1:0] o_channel_tx_data, 
		output o_channel_tx_data_valid
		
	);
				
	wire [`LOG2_NUM_WORDS_FIFO-1:0]w_fifo_pixels_usedw;
	
	reg r_fifo_pixels_clear;
	wire w_fifo_pixels_almost_empty;
	wire w_fifo_pixels_almost_full;
		
	wire [`DATA_WIDTH-1:0] w_pixel_dilate; 
	wire w_pixel_dilate_valid;
	wire w_end_dilate;
	
	enum {	
		bit_wait_rx_comunication           =0,
		bit_wait_clear_fifo				   =1,
		bit_read_data_comunication         =2,
		bit_set_tx_comunication       	   =3,
		bit_write_data_comunication        =4
		} state_bit;	
			
	enum logic[4:0]{
		state_wait_rx_comunication 			= 5'd1 << bit_wait_rx_comunication,
		state_wait_clear_fifo 			    = 5'd1 << bit_wait_clear_fifo,
		state_read_data_comunication 		= 5'd1 << bit_read_data_comunication,
		state_set_tx_comunication 			= 5'd1 << bit_set_tx_comunication,
		state_write_data_comunication		= 5'd1 << bit_write_data_comunication
		} r_state_UC_comunication, w_next_state_UC_comunication;	
		
	//passando o clk pro rx e tx
	assign o_channel_rx_clk = clk;
	assign o_channel_tx_clk = clk;				
		
	assign o_channel_rx_ack = (r_state_UC_comunication == state_wait_clear_fifo);  
	assign o_channel_rx_data_ren = (r_state_UC_comunication == state_read_data_comunication);
	
	assign o_channel_tx_last = ((r_state_UC_comunication == state_set_tx_comunication) || (r_state_UC_comunication == state_write_data_comunication));  
	assign o_channel_tx_length = `NUM_WORDS_FIFO*2;
	assign o_channel_tx_offset = 0;	
	
	assign o_channel_tx = ((r_state_UC_comunication == state_set_tx_comunication) || (r_state_UC_comunication == state_write_data_comunication)); 
	assign o_channel_tx_data_valid = (r_state_UC_comunication == state_write_data_comunication);	
	
	dilate_platedetection dilate_platedetection_i
	(	.clk(clk),
		.i_reset(i_reset),	
		
		.i_pixels_data_valid(o_channel_rx_data_ren & i_channel_rx_data_valid),
		.i_pixels_data(i_channel_rx_data),
				
		.o_pixels_data(w_pixel_dilate),
		.o_pixels_data_valid(w_pixel_dilate_valid),
		.o_end_dilate(w_end_dilate)
		
	);
		
	fifo_pixel fifo_pixel_i (.clock(clk),
							 .data(w_pixel_dilate),
							 .rdreq(i_channel_tx_data_ren & o_channel_tx_data_valid),
							 .sclr(r_fifo_pixels_clear),
							 .wrreq(w_pixel_dilate_valid),
							 .almost_empty(w_fifo_pixels_almost_empty),
							 .almost_full(w_fifo_pixels_almost_full),
							 .q(o_channel_tx_data),
							 .usedw(w_fifo_pixels_usedw)
						     );		

	
	always_comb begin
		
		unique case(1'b1)
			
			//read
			r_state_UC_comunication[bit_wait_rx_comunication]: // espera vim um frame no canal
				if(i_channel_rx == 1'b1)
					w_next_state_UC_comunication <= state_wait_clear_fifo;
				else
					w_next_state_UC_comunication <= state_wait_rx_comunication;	
			
			r_state_UC_comunication[bit_wait_clear_fifo]: // espera vim um frame no canal
				w_next_state_UC_comunication <= state_read_data_comunication;	
			
			r_state_UC_comunication[bit_read_data_comunication]: // estado que ler, subindo o rx_ren e processa 1 step de 128pixels
				if(w_fifo_pixels_almost_full)
					w_next_state_UC_comunication <= state_set_tx_comunication;	
				else
					w_next_state_UC_comunication <= state_read_data_comunication;				

			//write
			r_state_UC_comunication[bit_set_tx_comunication]: // prepara pra escrever o frame no canal, zera os contadores	
				if(w_end_dilate)	
					w_next_state_UC_comunication <= state_write_data_comunication;
				else
					w_next_state_UC_comunication <= state_set_tx_comunication;
																				
			r_state_UC_comunication[bit_write_data_comunication]:	
				if(w_fifo_pixels_almost_empty)			
					w_next_state_UC_comunication <= state_wait_rx_comunication;	
				else
					w_next_state_UC_comunication <= state_write_data_comunication;	
			
			default:
				w_next_state_UC_comunication <= state_wait_rx_comunication;	
				
		endcase

	end
	
	always_ff @(posedge clk  or posedge i_reset)begin 
			
		if(i_reset) begin	
			
			r_fifo_pixels_clear <= 1;
			
			r_state_UC_comunication <= state_wait_rx_comunication;
		end
		else begin
		
			r_state_UC_comunication <= w_next_state_UC_comunication;
			
			unique case(1'b1)	
				
				//read
				r_state_UC_comunication[bit_wait_rx_comunication]: begin			
					
					r_fifo_pixels_clear <= 1;
				end
				
				r_state_UC_comunication[bit_wait_clear_fifo]: begin			
					
					r_fifo_pixels_clear <= 0;
				end
				
				r_state_UC_comunication[bit_read_data_comunication]: begin			
					
					r_fifo_pixels_clear <= 0;
				end
				
				//write
				r_state_UC_comunication[bit_set_tx_comunication]: begin			
					
					r_fifo_pixels_clear <= 0;
				end
				
				r_state_UC_comunication[bit_write_data_comunication]: begin		
					
					r_fifo_pixels_clear <= 0;
				end

				default: begin		
					
					r_fifo_pixels_clear <= 1;
				end
				
			endcase
		
		end
	
	end

endmodule
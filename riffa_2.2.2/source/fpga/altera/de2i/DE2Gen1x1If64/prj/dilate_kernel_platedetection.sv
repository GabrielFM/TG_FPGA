
`include "defines_platedetection.svh"

module dilate_kernel_platedetection
	(	input	clk,
		input  	i_start_kernel,
		input	[`PIXEL_IN_WIDTH-1:0] i_pixel_up,
		input 	[`PIXEL_IN_WIDTH-1:0] i_pixel_down,
		input 	[`PIXEL_IN_WIDTH-1:0] i_pixel_left,	
		input 	[`PIXEL_IN_WIDTH-1:0] i_pixel_right,	
		input 	[`PIXEL_IN_WIDTH-1:0] i_pixel_center,	
		
		output reg [`PIXEL_OUT_WIDTH-1:0] o_pixel_dilate,
		output reg o_end_kernel
	);
	
	reg	[`PIXEL_IN_WIDTH-1:0] r_pixel_up;
	reg [`PIXEL_IN_WIDTH-1:0] r_pixel_down;
	reg [`PIXEL_IN_WIDTH-1:0] r_pixel_left;	
	reg [`PIXEL_IN_WIDTH-1:0] r_pixel_right;	
	reg [`PIXEL_IN_WIDTH-1:0] r_pixel_center;	
	
	reg r_start_kernel_1;
	reg r_start_kernel_2;
	reg r_start_kernel_3;
	reg r_start_kernel_4;
	
	wire w_up_greater_down;
	wire w_left_greater_right;	
	wire w_greater;
	wire w_greater_center;
	
	reg [`PIXEL_IN_WIDTH-1:0] r_up_greater_down_value;
	reg [`PIXEL_IN_WIDTH-1:0] r_left_greater_right_value;
	reg [`PIXEL_IN_WIDTH-1:0] r_greater_value;
	reg [`PIXEL_IN_WIDTH-1:0] r_greater_center_value;
	
	reg [`PIXEL_IN_WIDTH-1:0] r_pixel_center_1;
	reg [`PIXEL_IN_WIDTH-1:0] r_pixel_center_2;	
	
	
	//--------------------------------------------------------------------- estagio 1 --------------------------------------
	always_ff @(posedge clk)begin
		if(i_start_kernel) begin
			r_pixel_up <= i_pixel_up;
			r_pixel_down <= i_pixel_down;
			r_pixel_left <= i_pixel_left;
			r_pixel_right <= i_pixel_right;
			r_pixel_center <= i_pixel_center;
			
			r_start_kernel_1 <= i_start_kernel;
		end
		else begin
			r_pixel_up <= r_pixel_up;
			r_pixel_down <= r_pixel_down;
			r_pixel_left <= r_pixel_left;
			r_pixel_right <= r_pixel_right;
			r_pixel_center <= r_pixel_center;
			
			r_start_kernel_1 <= 0;
		end
	end
	
	//--------------------------------------------------------------------- estagio 2 --------------------------------------
	assign w_up_greater_down = r_pixel_up >= r_pixel_down; // 1 = up, 0 = down	
	
	assign w_left_greater_right = r_pixel_left >= r_pixel_right; // 1 = left, 0 = right	
	
	always_ff @(posedge clk)begin
		if(r_start_kernel_1) begin

			if(w_up_greater_down)begin
				r_up_greater_down_value <= r_pixel_up;
			end
			else begin
				r_up_greater_down_value <= r_pixel_down;
			end	

			if(w_left_greater_right)begin
				r_left_greater_right_value <= r_pixel_left;
			end
			else begin
				r_left_greater_right_value <= r_pixel_right;
			end	
			
			r_pixel_center_1 <= r_pixel_center;
			
			r_start_kernel_2 <= r_start_kernel_1;
					
		end
		else begin
			r_up_greater_down_value <= r_up_greater_down_value;
			
			r_left_greater_right_value <= r_left_greater_right_value;
			
			r_pixel_center_1 <= r_pixel_center_1;
			
			r_start_kernel_2 <= 0;
		end
	end
	
	//--------------------------------------------------------------------- estagio 3 --------------------------------------
	assign w_greater = r_up_greater_down_value >= r_left_greater_right_value; // 1 = r_up_greater_down_value, 0 = r_left_greater_right_value	

	
	always_ff @(posedge clk)begin
		if(r_start_kernel_2) begin

			if(w_greater)begin
				r_greater_value <= r_up_greater_down_value;
			end
			else begin
				r_greater_value <= r_left_greater_right_value;
			end	

			r_pixel_center_2 <= r_pixel_center_1;
			
			r_start_kernel_3 <= r_start_kernel_2;
					
		end
		else begin
			r_greater_value <= r_greater_value;
			
			r_pixel_center_2 <= r_pixel_center_2;
			
			r_start_kernel_3 <= 0;
		end
	end
		
	//--------------------------------------------------------------------- estagio 4 --------------------------------------
	assign w_greater_center = r_greater_value >= r_pixel_center_2; // 1 = r_greater_value, 0 = r_pixel_center_2	

	
	always_ff @(posedge clk)begin
		if(r_start_kernel_3) begin

			if(w_greater_center)begin
				r_greater_center_value <= r_greater_value;
			end
			else begin
				r_greater_center_value <= r_pixel_center_2;
			end	
			
			r_start_kernel_4 <= r_start_kernel_3;
					
		end
		else begin
			r_greater_center_value <= r_greater_center_value;
						
			r_start_kernel_4 <= 0;
		end
	end
		
	//--------------------------------------------------------------------- saida --------------------------------------	
	always_ff @(posedge clk)begin //registrando as entradas
		if(r_start_kernel_4) begin
			o_pixel_dilate <= r_greater_center_value;
			
			o_end_kernel <= r_start_kernel_4;
		end
		else begin
			o_pixel_dilate <= o_pixel_dilate;
			
			o_end_kernel <= 0;
		end
	end
	 
endmodule
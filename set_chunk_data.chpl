/*
 * 		SET CHUNK DATA KERNEL
 * 		Initialises the chunk's mesh data.
 */

// Extended kernel for the chunk initialisation
module set_chunk{
	var x_min: real;
	var y_min: real;
	use settings;
	use chunks;

	proc set_chunk_data(){
		x_min = setting_var.grid_x_min + setting_var.dx * chunk_var.left:real;
		y_min = setting_var.grid_y_min + setting_var.dy * chunk_var.bottom:real;

		forall ii in 0..chunk_var.x do {
			chunk_var.vertex_x[ii] = x_min + setting_var.dx * (ii - setting_var.halo_depth);  // ii - 1 to account for index offset
		}

		forall ii in 0..chunk_var.y do {
			chunk_var.vertex_y[ii] = y_min + setting_var.dy * (ii - setting_var.halo_depth);  
		}

		// forall ii in 0..chunk_var.x+1 do {
		// 	chunk_var.vertex_x[ii] = x_min + setting_var.dx * (ii-1 - setting_var.halo_depth);  
		// }

		// forall ii in 0..<chunk_var.y+1 do {
		// 	chunk_var.vertex_y[ii] = y_min + setting_var.dy * (ii-1 - setting_var.halo_depth);  
		// }
		
		forall ii in 0..<chunk_var.x do {
			chunk_var.cell_x = 0.5 * (chunk_var.vertex_x[ii] + chunk_var.vertex_x[ii+1]);

		}
		forall ii in 0..<chunk_var.y do {
			chunk_var.cell_y = 0.5 * (chunk_var.vertex_y[ii] + chunk_var.vertex_y[ii+1]);

		}
		forall ii in 0..<(chunk_var.x * chunk_var.y) do {
			chunk_var.volume[ii] = setting_var.dx * setting_var.dy;
			chunk_var.x_area[ii] = setting_var.dy;
			chunk_var.y_area[ii] = setting_var.dx;
		}

		
	}

}

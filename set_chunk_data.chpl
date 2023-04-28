/*
 * 		SET CHUNK DATA KERNEL
 * 		Initialises the chunk's mesh data.
 */

// Extended kernel for the chunk initialisation
module set_chunk_data{
	var x_min: real;
	var y_min: real;
	use settings;
	use chunks;

	proc set_chunk_data(ref chunk_var: chunks.Chunk, ref setting_var : settings.setting){ 
		x_min = setting_var.grid_x_min + setting_var.dx * (chunk_var.left:real);
		y_min = setting_var.grid_y_min + setting_var.dy * (chunk_var.bottom:real);

		//as this is just set up, serial execution is used
		for ii in 0..chunk_var.x do { 
			chunk_var.vertex_x[ii] = x_min + setting_var.dx * (ii - setting_var.halo_depth); 
		}

		for ii in 0..chunk_var.y do {
			chunk_var.vertex_y[ii] = y_min + setting_var.dy * (ii - setting_var.halo_depth);  
		}
		
		for ii in 0..<chunk_var.x do {
			chunk_var.cell_x[ii] = 0.5 * (chunk_var.vertex_x[ii] + chunk_var.vertex_x[ii+1]);

		}
		for ii in 0..<chunk_var.y do {
			chunk_var.cell_y[ii] = 0.5 * (chunk_var.vertex_y[ii] + chunk_var.vertex_y[ii+1]);

		}
		chunk_var.volume = setting_var.dx * setting_var.dy;
		chunk_var.x_area = setting_var.dy;
		chunk_var.y_area = setting_var.dx;
	}

/*
 * 		SET CHUNK DATA DRIVER
 */
	// Invokes the set chunk data kernel
	proc set_chunk_data_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting){

		set_chunk_data(chunk_var[0], setting_var);
	}

}

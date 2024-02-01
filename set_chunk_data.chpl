/*
 * 		SET CHUNK DATA KERNEL
 * 		Initialises the chunk's mesh data.
 */

// Extended kernel for the chunk initialisation
module set_chunk_data{
	use settings;
	use chunks;
	use profile;
	
	
	proc set_chunk_data_driver(ref chunk_var: chunks.Chunk,  const ref setting_var : settings.setting){ 
		//  // profiler.startTimer("set_chunk_data");
			const x_min: real = setting_var.grid_x_min + setting_var.dx * (chunk_var.left:real);
			const  y_min: real = setting_var.grid_y_min + setting_var.dy * (chunk_var.bottom:real);

			// As this is just set up, serial execution is used 
			// TODO look into multi locale execution and parallelism for this
			for ii in chunk_var.vertex_x.domain do { 
				chunk_var.vertex_x[ii] = x_min + setting_var.dx * (ii - setting_var.halo_depth); 
			}

			for ii in chunk_var.vertex_y.domain do {
				chunk_var.vertex_y[ii] = y_min + setting_var.dy * (ii - setting_var.halo_depth);  
			}
			
			for ii in chunk_var.cell_x.domain do {
				chunk_var.cell_x[ii] = 0.5 * (chunk_var.vertex_x[ii] + chunk_var.vertex_x[ii+1]);

			}
			for ii in chunk_var.cell_x.domain do {
				chunk_var.cell_y[ii] = 0.5 * (chunk_var.vertex_y[ii] + chunk_var.vertex_y[ii+1]);

			}
			
			for ii in chunk_var.volume.domain do {
				chunk_var.volume[ii] = setting_var.dx * setting_var.dy;
			}

		
		//  // profiler.stopTimer("set_chunk_data");
	}
}

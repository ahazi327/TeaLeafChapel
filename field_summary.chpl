

module field_summary {
    use settings;
    use chunks;
    use IO;

   /*
    * 		FIELD SUMMARY KERNEL
    * 		Calculates aggregates of values in field.
    */	
    // The field summary kernel
    proc field_summary (in x: int, in y: int, in halo_depth: int, ref volume: [?Domain] real,
    ref density: [Domain] real, ref energy0: [Domain] real, ref u: [Domain] real, ref vol: real,
    ref mass: real, ref ie: real, ref temp: real){

        var inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];

        for j in {halo_depth..<x-halo_depth} do { // TODO maybe make this into a forall loop
            for i in {halo_depth..<y-halo_depth} do {
                var cellVol : real;
                cellVol = volume[i, j];

                var cellMass: real;
                cellMass = cellVol * density[i, j];

                vol += cellVol;
                mass += cellMass;
                ie += cellMass * energy0[i, j];
                temp += cellMass * u[i, j];
                                
            }
        }
        // writeln("Mass Value : ", mass);
        // writeln("Checking Value : ", temp);
    }

/*
 * 		FIELD SUMMARY DRIVER
 */	

    // Invokes the set chunk data kernel
    proc field_summary_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting,
        in is_solve_finished: bool){
        
        var vol, ie, temp, mass : real = 0.0;

        // for cc in 0..<setting_var.num_chunks_per_rank do {
        field_summary(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].volume, 
        chunk_var[0].density, chunk_var[0].energy0, chunk_var[0].u, vol, mass, ie, temp);
        // }

        if(setting_var.check_result && is_solve_finished){ //  if settings->rank == MASTER && ...
            var checking_value : real = 1.0;
            get_checking_value(setting_var, checking_value);

            writeln("Expected: \n", checking_value);
            writeln("Actual: \n", temp);

            var qa_diff: real = abs(100.0*(temp/checking_value)-100.0);

            if qa_diff < 0.001 then writeln("pass with qa_diff of :", qa_diff);//print pass
            else writeln("failed with qa_diff of :", qa_diff);
        } 
    }

    // Fetches the checking value from the test problems file
    proc get_checking_value (ref setting_var : settings.setting, inout checking_value : real){
        var counter : int;
        try {
            var tea_prob = open (setting_var.test_problem_filename, iomode.r);
            var tea_prob_reader = tea_prob.reader();
            
            var x : int;
            var y : int;
            var num_steps: int;
            var line : string;

            for line in tea_prob.lines(){
                tea_prob_reader.read(x, y, num_steps, checking_value);
                counter += 1;

                if ( x == setting_var.grid_x_cells && y == setting_var.grid_y_cells && num_steps == setting_var.end_step) {
                    // Found the problem in the file
                    // writeln("checking values : ", x, " , " , y, " , " , num_steps, " , " ,checking_value);
                    tea_prob.close();
                    return;
                }
                // writeln("checking values : ", x, " , " , y, " , " , num_steps, " , " ,checking_value, " value not found in problem.");
            }
            tea_prob.close();
        }
        catch {
            writeln("Error parsing at line: ", counter);
        }
    }
}   

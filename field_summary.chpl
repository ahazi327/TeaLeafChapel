

module field_summary {
    use settings;
    use chunks;
    use IO;
    use profile;

   /*
    * 		FIELD SUMMARY KERNEL
    * 		Calculates aggregates of values in field.
    */	
    // The field summary kernel
    proc field_summary (in x: int, in y: int, in halo_depth: int, const ref volume: [Domain] real,
    const ref density: [Domain] real, const ref energy0: [Domain] real, const ref u: [Domain] real, ref vol: real,
    ref mass: real, ref ie: real, ref temp: real, const in Domain : domain(2)){

        profiler.startTimer("field_summary");

        var inner = Domain[halo_depth..<y-halo_depth, halo_depth..<x-halo_depth];

        for j in {halo_depth..<y-halo_depth} do { // TODO maybe make this into a forall loop
            for i in {halo_depth..<x-halo_depth} do {
        // foreach (j, i) in inner do{ 
                var cellVol : real;
                cellVol = volume[j, i];

                var cellMass: real;
                cellMass = cellVol * density[j, i];

                vol += cellVol;
                mass += cellMass;
                ie += cellMass * energy0[j, i];
                temp += cellMass * u[j, i];
            }
        }
        profiler.stopTimer("field_summary");
    }

/*
 * 		FIELD SUMMARY DRIVER
 */	

    // Invokes the set chunk data kernel
    proc field_summary_driver(ref chunk_var : [0..<setting_var.num_chunks] chunks.Chunk, ref setting_var : settings.setting,
        const in is_solve_finished: bool){
        
        var vol, ie, temp, mass : real = 0.0;

        // for cc in 0..<setting_var.num_chunks_per_rank do {
        field_summary(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].volume, 
        chunk_var[0].density, chunk_var[0].energy0, chunk_var[0].u, vol, mass, ie, temp, {0..<chunk_var[0].y, 0..<chunk_var[0].x});
        // }

        if(setting_var.check_result && is_solve_finished){ //  if settings->rank == MASTER && ...
            var checking_value : real = 1.0;
            get_checking_value(setting_var, checking_value);

            writeln("Expected: \n", checking_value);
            writeln("Actual: \n", temp);

            var qa_diff: real = abs(100.0*(temp/checking_value)-100.0);

            if qa_diff < 0.001 then writeln("Passed with qa_diff of ", qa_diff);
            else writeln("Failed with qa_diff of ", qa_diff);
        } 
    }

    // Fetches the checking value from the test problems file
    proc get_checking_value (const ref setting_var : settings.setting, ref checking_value : real){
        var counter : int;
        try {
            var tea_prob = open (setting_var.test_problem_filename, ioMode.r);
            var tea_prob_reader = tea_prob.reader();
            
            var x : int;
            var y : int;
            var num_steps: int;
            var line : string;
            tea_prob_reader.read(x, y, num_steps, checking_value);

            for line in tea_prob_reader.lines(){
                counter += 1;
                if ( x == setting_var.grid_x_cells && y == setting_var.grid_y_cells && num_steps == setting_var.end_step) {
                    // Found the problem in the file
                    tea_prob.close();
                    return;
                }
                tea_prob_reader.read(x, y, num_steps, checking_value);
            }
            tea_prob.close();
        }
        catch {
            writeln("Error parsing at line: ", counter);
        }
    }
}   

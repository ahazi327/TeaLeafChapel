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
    proc field_summary (const ref halo_depth: int, const ref volume: [?Domain] real,
                        const ref density: [Domain] real, const ref energy0: [Domain] real, 
                        const ref u: [Domain] real, ref vol: real, ref mass: real, 
                        ref ie: real, ref temp: real){
        profiler.startTimer("field_summary");

        // Declare arrays to store the results from each locale
        var localVols: [{0..<Locales.size}] real;
        var localMasses: [{0..<Locales.size}] real;
        var localIes: [{0..<Locales.size}] real;
        var localTemps: [{0..<Locales.size}] real;

        // coforall loop across all locales
        coforall loc in Locales do on loc {
            var localVol = 0.0,
                localMass = 0.0,
                localIe = 0.0,
                localTemp = 0.0;

            for i in Domain.expand(-halo_depth) {
                localVol += volume[i];
                localMass += volume[i] * density[i];
                localIe += volume[i] * density[i] * energy0[i];
                localTemp += volume[i] * density[i] * u[i];
            }

            // Write the local results back to the arrays on locale 0
            localVols[loc.id] = localVol;
            localMasses[loc.id] = localMass;
            localIes[loc.id] = localIe;
            localTemps[loc.id] = localTemp;
        }

        // Sum up the results from all locales
        vol = + reduce localVols;
        mass = + reduce localMasses;
        ie = + reduce localIes;
        temp = + reduce localTemps;

        profiler.stopTimer("field_summary");
    }

/*
 * 		FIELD SUMMARY DRIVER
 */	

    // Invokes the set chunk data kernel
    proc field_summary_driver(ref chunk_var :chunks.Chunk, ref setting_var : settings.setting,
        const in is_solve_finished: bool){
        
        var vol, ie, temp, mass : real;

        field_summary(setting_var.halo_depth, chunk_var.volume, 
        chunk_var.density, chunk_var.energy0, chunk_var.u, vol, mass, ie, temp);

        if(setting_var.check_result && is_solve_finished){ 
            var checking_value : real;
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
                if (x == setting_var.grid_x_cells && y == setting_var.grid_y_cells && 
                    num_steps == setting_var.end_step) {
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

/*
 * 		FIELD SUMMARY KERNEL
 * 		Calculates aggregates of values in field.
 */	

module field_summary {
    use settings;
    use chunks;

    // The field summary kernel
    proc field_summary (in x: int, in y: int, in halo_depth: int, inout volume: [?Domain] real,
    ref density: [Domain] real, ref energy0: [Domain] real, ref u: [Domain] real, ref vol: real,
    inout mass: real, inout ie: real, inout temp: real){

        // var vol : real;
        // var ie : real;
        // var temp : real;
        // var mass : real; // should be 0.0 already
        
        var inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];

        forall (i, j) in inner with (+ reduce vol, +reduce mass, + reduce ie, + reduce temp) do {
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

/*
 * 		FIELD SUMMARY DRIVER
 */	

    // Invokes the set chunk data kernel
    proc field_summary_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting,
        in is_solve_finished: bool){
        
        var vol, ie, temp, mass : real = 0.0;

        field_summary(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].volume, 
        chunk_var[0].density, chunk_var[0].energy0, chunk_var[0].u, vol, mass, ie, temp);

        if(setting_var.check_result && is_solve_finished){ //  if settings->rank == MASTER && ...
            var checking_value : real = 1.0;
            get_checking_value(setting_var, checking_value);

            // print_and_log(settings, "Expected %.15e\n", checking_value);
            // print_and_log(settings, "Actual   %.15e\n", temp);

            var qa_diff: real = abs(100.0*(temp/checking_value)-100.0);

            // if qa_diff < 0.001 then //print pass
            // else print failed
        } 
    }

    // Fetches the checking value from the test problems file
    proc get_checking_value (ref setting_var : settings.setting, in checking_value : real){

        // FILE* test_problem_file = fopen(settings->test_problem_filename, "r");  // TODO input file

        // if(!test_problem_file)
        // {
        //     print_and_log(settings,
        //         "\nWARNING: Could not open the test problem file.\n");
        // }

        // size_t len = 0;
        // char* line = NULL;

        // // Get the number of states present in the config file
        // while(getline(&line, &len, test_problem_file) != EOF)
        // {
        //     int x;
        //     int y;
        //     int num_steps;

        //     sscanf(line, "%d %d %d %lf", &x, &y, &num_steps, checking_value);

        //     // Found the problem in the file
        //     if(x == settings->grid_x_cells && y == settings->grid_y_cells &&
        //         num_steps == settings->end_step)
        //     {
        //     fclose(test_problem_file);
        //     return;
        //     }
        // }

        // *checking_value = 1.0;
        // print_and_log(settings, 
        //     "\nWARNING: Problem was not found in the test problems file.\n");
        // fclose(test_problem_file);

    }
}   

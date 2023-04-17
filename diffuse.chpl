module diffuse{
    use Time;
    use chunks;
    use settings;
    use solve_finish_driver;
    use local_halos;
    use field_summary;
    use ppcg_driver;
    use cg_driver;
    use jacobi_driver;
    use cheby_driver;

    // The main timestep loop
    proc diffuse(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting){
        
        var wallclock_prev : real = 0.0;
        const end_step = setting_var.end_step : int;
        for tt in 0..<end_step do{
            
            solve(chunk_var, setting_var, tt, wallclock_prev);
        } 

        field_summary_driver(chunk_var, setting_var, true);
    }

    // Performs a solve for a single timestep
    proc solve(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in tt : int,
        ref wallclock_prev : real){
        
        //print and log function
        //profiler start timer

        // Calculate minimum timestep information
        var dt : real = setting_var.dt_init;
        // calc_min_timestep(chunk_var, dt, setting_var.num_chunks_per_rank);

        // Pick the smallest timestep across all ranks
        // TODO min_over_ranks

        var rx : real = dt / (setting_var.dx * setting_var.dx);
        var ry : real = dt / (setting_var.dy * setting_var.dy);
       
        // Prepare halo regions for solve
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_ENERGY1] = true;
        setting_var.fields_to_exchange[FIELD_DENSITY] = true;
        halo_update_driver(chunk_var, setting_var, 2);

        var error : real = 1e+10;

        // Perform the solve with one of the integrated solvers
        select (setting_var.solver){
            when Solver.JACOBI_SOLVER{
                jacobi_driver(chunk_var, setting_var, rx, ry, error);
                writeln("Using the Jacobi Solver...");
            }
            when Solver.CG_SOLVER{
                cg_driver(chunk_var, setting_var, rx, ry);
                writeln("Using the CG Solver...");
            }
            when Solver.CHEBY_SOLVER{
                cheby_driver(chunk_var, setting_var, rx, ry);
                writeln("Using the Cheby Solver...");
            }
            when Solver.PPCG_SOLVER{
                ppcg_driver(chunk_var, setting_var, rx, ry);
                writeln("Using the PPCG Solver...");
            }
        }
        // Perform solve finalisation tasks
        solve_finished_driver(chunk_var, setting_var);
        
        if(tt % setting_var.summary_frequency == 0){
            field_summary_driver(chunk_var, setting_var, false);
        }

        //profiler_end_timer(settings->wallclock_profile, "Wallclock");
        // var wallclock = setting_var.wallclock_profile.profiler_entries[0].time;
        // print_and_log(settings, "Wallclock: \t\t%.3lfs\n", wallclock);
        // print_and_log(settings, "Avg. time per cell: \t%.6e\n", 
        //     (wallclock-*wallclock_prev) /
        //     (settings->grid_x_cells *
        //     settings->grid_y_cells));
        // print_and_log(settings, "Error: \t\t\t%.6e\n", error);
    }

    proc calc_min_timestep (ref chunk_var : [?chunk_domain] chunks.Chunk, ref dt: real, const in chunks_per_task : int){
       for cc in 0..<chunks_per_task do {

            // Calculates a value for dt
            // Currently defaults to config provided value
            var dtlp : real = chunk_var[cc].dt_init;
            if(dtlp < dt) then dt = dtlp;
       } 
    }


}
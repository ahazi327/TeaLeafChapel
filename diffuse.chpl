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
    use profile;
    use main;
    use parse_config;

    // The main timestep loop
    proc diffuse(ref chunk_var : chunks.Chunk, ref setting_var : settings.setting){
        const end_step = setting_var.end_step : int;
        writeln("Using the ", setting_var.solver : string, "\n");
        
        // Make sure all array's fluff cells are up to date before starting solve method
        if useStencilDist {
            select (setting_var.solver){
                when Solver.JACOBI_SOLVER{
                    profiler.startTimer("comms");
                    chunk_var.density.updateFluff();
                    chunk_var.volume.updateFluff();
                    profiler.stopTimer("comms");
                }
                when Solver.CG_SOLVER{
                    profiler.startTimer("comms");
                    chunk_var.density.updateFluff();
                    chunk_var.volume.updateFluff();
                    chunk_var.sd.updateFluff();
                    profiler.stopTimer("comms");
                }
                // when Solver.CHEBY_SOLVER{
                    
                // }
                when Solver.PPCG_SOLVER{
                    profiler.startTimer("comms");
                    chunk_var.density.updateFluff();
                    chunk_var.volume.updateFluff();
                    profiler.stopTimer("comms");
                }
            }
        }

        for tt in 0..<end_step do{
            writeln("Timestep ", tt + 1);
            solve(chunk_var, setting_var, tt);
        } 
        field_summary_driver(chunk_var, setting_var, true);
    }

    // Performs a solve for a single timestep
    proc solve(ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const ref tt : int){
        
        //start timer
        var wallclock = new stopwatch();
        wallclock.start();

        // Calculate minimum timestep information
        const dt : real = setting_var.dt_init;

        // Pick the smallest timestep across all ranks
        var rx : real = dt / (setting_var.dx * setting_var.dx);
        var ry : real = dt / (setting_var.dy * setting_var.dy);
       
        // Prepare halo regions for solve
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_ENERGY1] = true;
        setting_var.fields_to_exchange[FIELD_DENSITY] = true;
        halo_update_driver(chunk_var, setting_var, 2);

        if useStencilDist {
            profiler.startTimer("comms");
            chunk_var.density.updateFluff();
            chunk_var.energy.updateFluff();
            profiler.stopTimer("comms");
        }

        var error : real = 0;
        var iterations_count : int = 0;
        var iterations_prime : int = 0;
        var inner_steps : int = 0;

        // Perform the solve with one of the integrated solvers
        select (setting_var.solver){
            when Solver.JACOBI_SOLVER{
                jacobi_driver(chunk_var, setting_var, rx, ry, error, iterations_count);
            }
            when Solver.CG_SOLVER{
                cg_driver(chunk_var, setting_var, rx, ry, error, iterations_count);
            }
            when Solver.CHEBY_SOLVER{
                cheby_driver(chunk_var, setting_var, rx, ry, error, iterations_count, 
                            iterations_prime, inner_steps);
            }
            when Solver.PPCG_SOLVER{
                ppcg_driver(chunk_var, setting_var, rx, ry, error, iterations_count,
                            iterations_prime, inner_steps);
            }
        }
        writeln("Conduction error : ", error);
        // Perform solve finalisation tasks
        solve_finished_driver(chunk_var, setting_var);
        
        if(tt % setting_var.summary_frequency == 0){
            field_summary_driver(chunk_var, setting_var, false);
        }

        wallclock.stop();
        writeln("Time elapsed for current timestep: ", wallclock.elapsed(), " seconds");
        const average : real = wallclock.elapsed()/ (setting_var.grid_x_cells * setting_var.grid_y_cells);
        writeln("Avg. time per cell for current timestep: ",  average, " seconds \n");

        // parse_config.write_timestep(setting_var.tea_out_filename, chunk_var, iterations_count, iterations_prime, 
        //                 inner_steps, setting_var.solver, tt + 1, error, wallclock.elapsed(), average);
    }
}
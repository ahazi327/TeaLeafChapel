module main {
    use Time;
    use settings;
    use chunks;
    use diffuse;
    use parse_config;
    use initialise;
    use profile;
    

    proc main (args: [] string){
        //MPI stuff

        // Time full program elapsed time
        var wallclock = new stopwatch();
        wallclock.start();

        // Create the settings wrapper
        var setting_var: setting;
        setting_var = new setting();
        
        set_default_settings(setting_var);

        // initialise states
        find_num_states(setting_var); 
        var states_domain = {0..<setting_var.num_states};
        var states: [states_domain] settings.state;
        states = new settings.state();

        // Perform initialisation steps
        setting_var.num_chunks = setting_var.num_ranks * setting_var.num_chunks_per_rank;
        
        // Create array of records of chunks and initialise temporarily
        var num_chunks : domain(1) = {0..<setting_var.num_chunks};
        var chunk_var: [num_chunks] chunks.Chunk = new Chunk (0, 0, 0, 0);
        
        initialise_application(chunk_var, setting_var, states);

        // Perform the solve using default or overloaded diffuse    
        diffuse(chunk_var, setting_var);

        wallclock.stop();
        writeln("\nTotal time elapsed: ", wallclock.elapsed(), " seconds");

        // Print the profile summary
        profiler.report();
    }

    // after parsing input files, use it to set settings file //TODO maybe remove this
    proc settings_overload(ref setting_var : setting, in argc : int, ref argv: [?D] string){
        
        for aa in 1..<argc do {
            // Overload the solver
            if !argv[aa].find("-solver")==-1 & !argv[aa].find("--solver")==-1 & !argv[aa].find("-s")==-1 {
                if aa+1 == argc then break;
                if argv[aa +  1].find("cg") then setting_var.solver = settings.Solver.CG_SOLVER;
                if argv[aa +  1].find("cheby") then setting_var.solver = settings.Solver.CHEBY_SOLVER;
                if argv[aa +  1].find("ppcg") then setting_var.solver = settings.Solver.PPCG_SOLVER;
                if argv[aa +  1].find("jacobi") then setting_var.solver = settings.Solver.JACOBI_SOLVER;
            }
            else if !argv[aa].find("-x")==-1 {
                if aa+1 == argc then break;
                setting_var.grid_x_cells = argv[aa].toInt();

            }
            else if !argv[aa].find("-y")==-1 {
                if aa+1 == argc then break;
                setting_var.grid_y_cells = argv[aa].toInt(); 
            }
            else if !argv[aa].find("-help")== -1 & !argv[aa].find("--help")== -1 & !argv[aa].find("-h")== -1 {

                //print and log 
                //exit
                break;
            }
        }

    }
}
module main {
    use settings;
    use chunks;
    use diffuse;

    proc main_function (in argc : int, ref argv : string){
        // test
        writeln("Hellow world");

        //MPI stuff

        // Create the settings wrapper
        var setting_var: setting;
        setting_var = new setting();
        set_default_settings(setting_var);

        // Fill in rank information - for now only using 1 rank
        //   initialise_ranks(settings);

        // Perform initialisation steps
        setting_var.num_chunks = setting_var.num_ranks * setting_var.num_chunks_per_rank;
        var chunk_var = fill(nil: chunks.Chunk, setting_var.num_chunks - 1);

        initialise_application(chunk_var, setting_var);

        settings_overload(setting_var, argc, argv);

        // Perform the solve using default or overloaded diffuse
        diffuse(chunk_var, setting_var);

        // Print the kernel-level profiling results
        // if(settings->rank == MASTER)
        // {
        // PRINT_PROFILING_RESULTS(settings->kernel_profile);
        // }

        // Finalise each individual chunk and application
        //TODO free memory if needed in chapel using array = nil

        return 0; // Exit success
    }

    proc settings_overload(ref setting_var : setting, in argc : int, ref argv: string){
        
        for aa in 1..<argc do {
            // Overload the solver
        }

    }
}
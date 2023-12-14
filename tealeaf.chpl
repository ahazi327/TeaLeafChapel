module main {
    use Time;
    use settings;
    use chunks;
    use diffuse;
    use parse_config;
    use initialise;
    use profile;
    use GpuDiagnostics;
    
    /* 
        This repository is a translation in to Chapel from C 
        of the TeaLeaf mini-app from the University of Bristol
        https://github.com/UoB-HPC/TeaLeaf 
    */

    config param verbose = false;

    proc main (args: [] string){
        // Time full program elapsed time
        var wallclock = new stopwatch();
        wallclock.start();

        if useGPU {
            on here.gpus[0] {
                // Create the settings wrapper
                var setting_var: setting;
                setting_var = new setting();
                
                set_default_settings(setting_var);

                // Initialise states
                find_num_states(setting_var); 
                const states_domain = {0..<setting_var.num_states};
                var states: [states_domain] settings.state;
                states = new settings.state();

                // Read input files for state and setting information
                read_config(setting_var, states);
                
                // Create array of records of chunks and initialise
                set_var(setting_var);
                var chunk_var: chunks.Chunk = new Chunk ();

                initialise_application(chunk_var, setting_var, states);    //TODO WORK ON THIS TO FIX SEGMENTATION FAULTS

                diffuse(chunk_var, setting_var);

                // Print the verbose profile summary
                // if verbose then profiler.report();

            }
        }
        
        wallclock.stop();
        writeln("\nTotal time elapsed: ", wallclock.elapsed(), " seconds");   
    }
}
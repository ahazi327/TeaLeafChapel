module initialise {
    use settings;
    use chunks;
    use set_chunk_data;
    use set_chunk_state;
    use local_halos;
    use store_energy;
    use parse_config;
    use profile;
    use MemDiagnostics; // for physicalMemory()
    param MY_MAX_REAL = 1e308;
    config param printLocaleInfo = false;

    // Initialise settings from input file
    proc initialise_application (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, 
                                ref states : [0..<setting_var.num_states] state){ 
        // profiler.startTimer("initialise_application");
        
        if printLocaleInfo then
            for loc in Locales do
                on loc {
                writeln("locale #", here.id, "...");
                writeln("  ...is named: ", here.name);
                writeln("  ...has hostname: ", here.hostname);
                writeln("  ...has ", here.numPUs(), " processor cores");
                writeln("  ...has ", here.physicalMemory(unit=MemUnits.GB, retType=real),
                        " GB of memory");
                writeln("  ...has ", here.maxTaskPar, " maximum parallelism");
                }
            
        writeln();
        

        set_chunk_data_driver(chunk_var, setting_var);
        set_chunk_state_driver(chunk_var, setting_var, states);
        
        // Prime the initial halo data
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_DENSITY]=true;
        setting_var.fields_to_exchange[FIELD_ENERGY0]=true;
        setting_var.fields_to_exchange[FIELD_ENERGY1]=true;
        halo_update_driver (chunk_var, setting_var, 2);

        store_energy(chunk_var.energy0, chunk_var.energy);

        // profiler.stopTimer("initialise_application");
    }
}
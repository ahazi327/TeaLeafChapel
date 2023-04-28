module initialise {
    use settings;
    use chunks;
    use set_chunk_data;
    use set_chunk_state;
    use local_halos;
    use store_energy;
    use parse_config;
    param MY_MAX_REAL = 1e308;


    // Initialise settings from input file
    proc initialise_application (ref chunk_var :[?Domain] chunks.Chunk, ref setting_var : settings.setting, ref states : [0..<setting_var.num_states]  state){ //TODO sort out how states works
        // read input files for state and setting information
        read_config(setting_var, states);
        
        decompose_field(chunk_var, setting_var);
        set_chunk_data_driver(chunk_var, setting_var);
        set_chunk_state_driver(chunk_var, setting_var, states);
        
        // Prime the initial halo data
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_DENSITY]=true;
        setting_var.fields_to_exchange[FIELD_ENERGY0]=true;
        setting_var.fields_to_exchange[FIELD_ENERGY1]=true;
        halo_update_driver (chunk_var, setting_var, 2);

        store_energy_driver(chunk_var);

        
    }

    // Decomposes the field into multiple chunks
    proc decompose_field (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting){
        
        // Calculates the num chunks field is to be decomposed into
        const number_of_chunks : int = setting_var.num_chunks;

        var best_metric : real =  MY_MAX_REAL;
        var x_cells = setting_var.grid_x_cells;
        var y_cells = setting_var.grid_y_cells;

        var x_chunks = 0;
        var y_chunks = 0;

        // Decompose by minimal area to perimeter
        for xx in 1..number_of_chunks do{

            if number_of_chunks % xx then continue;

            // Calculate number of chunks grouped by x split
            var yy: int = number_of_chunks / xx;
            if number_of_chunks % yy then continue;

            var perimeter: real = ((x_cells/xx)*(x_cells/xx) + (y_cells/yy)*(y_cells/yy)) * 2;

            var area: real = (x_cells/xx)*(y_cells/yy);

            var current_metric : real = perimeter / area;

            // Save improved decompositions
            if(current_metric < best_metric){
                x_chunks = xx;
                y_chunks = yy;
                best_metric = current_metric;
            }
        }

        // Check that the decomposition didn't fail
        // if(!x_chunks || !y_chunks)
        // {
        //     die(__LINE__, __FILE__, 
        //         "Failed to decompose the field with given parameters.\n");
        // }

        var dy: int = setting_var.grid_y_cells / y_chunks;
        var dx: int = setting_var.grid_x_cells / x_chunks;
        
        var mod_x = setting_var.grid_x_cells % x_chunks;
        var mod_y = setting_var.grid_y_cells % y_chunks;
        var add_x_prev : int = 0;
        var add_y_prev : int = 0;

        // Compute the full decomposition on all ranks
        for yy in 0..<y_chunks do{
            var add_y : int = (yy < mod_y);

            for xx in 0..<x_chunks do{
            var add_x : int = (xx < mod_x);

                for cc in 0..<setting_var.num_chunks_per_rank do{
                    var rank : int = cc + (setting_var.rank * setting_var.num_chunks_per_rank); // TODO come back alter to fix this when implementing locales
                    

                        // Store the values for all chunks local to rank
                    if rank == 0 { // either using tuple or scalar , TODO update set to a scaler, for now keep as one due to only having 1 rank
                        init_chunk(chunk_var, cc, setting_var, dx+add_x, dy+add_y);

                        // Set up the mesh ranges - important for locales later
                        chunk_var[cc].left = xx*dx +add_x_prev;
                        chunk_var[cc].right = chunk_var[cc].left + dx+ add_x;
                        chunk_var[cc].bottom = yy*dy +add_y_prev;
                        chunk_var[cc].top = chunk_var[cc].bottom + dy + add_y;

                        // Set up the chunk connectivity
                        if xx == 0 then 
                            chunk_var[cc].neighbours[CHUNK_LEFT] = EXTERNAL_FACE;
                        else chunk_var[cc].neighbours[CHUNK_LEFT] = (xx - 1, yy); // TODO possibly needs fixing to 2d using tuples
                        // writeln("chunk_var[",cc,"].neighbours[CHUNK_LEFT] : ", chunk_var[cc].neighbours[CHUNK_LEFT]);

                        if xx == x_chunks-1 then 
                            chunk_var[cc].neighbours[CHUNK_RIGHT] = EXTERNAL_FACE;
                        else chunk_var[cc].neighbours[CHUNK_RIGHT] = (xx + 1, yy);
                        // writeln("chunk_var[",cc,"].neighbours[CHUNK_RIGHT] : ", chunk_var[cc].neighbours[CHUNK_RIGHT]);
                        
                        if yy == 0 then 
                            chunk_var[cc].neighbours[CHUNK_TOP] = EXTERNAL_FACE;
                        else chunk_var[cc].neighbours[CHUNK_TOP] = (xx, yy - 1);
                        // writeln("chunk_var[",cc,"].neighbours[CHUNK_TOP] : ", chunk_var[cc].neighbours[CHUNK_TOP]);

                        if yy == y_chunks-1 then 
                            chunk_var[cc].neighbours[CHUNK_BOTTOM] = EXTERNAL_FACE;
                        else chunk_var[cc].neighbours[CHUNK_BOTTOM] = (xx, yy + 1);
                        // writeln("chunk_var[",cc,"].neighbours[CHUNK_BOTTOM] : ", chunk_var[cc].neighbours[CHUNK_BOTTOM]);

                    }  
                }
                // If chunks rounded up, maintain relative location
                add_x_prev += add_x;
            }
            add_x_prev = 0;
            add_y_prev += add_y; 
        }
    }
}
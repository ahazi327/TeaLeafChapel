module remote_halo_driver{
    use settings;
    use chunks;
    use pack_halos;

    proc remote_halo_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in depth :int){
        // currently set for single locale

        // Unpack lr buffers
        // if chunk_var.neighbours[CHUNK_LEFT] != EXTERNAL_FACE {
        //     invoke_pack_or_unpack(chunk_var, setting_var, CHUNK_LEFT, depth, false)
        // }

    }

    // Attempts to pack buffers
    proc invoke_pack_or_unpack (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, ref face : int, in depth :int,
    ref pack : bool, ref buffer : [?D] real) {

        for ii in 0..<NUM_FIELDS do {
            if !setting_var.fields_to_exchange[ii] then continue;

            var field: [chunk_var.Domain] real;

            select (ii){
                when FIELD_DENSITY{
                    field = chunk_var.density;
                    // break;
                }
                when FIELD_ENERGY0{
                    field = chunk_var.energy0;
                    // break;
                }
                when FIELD_ENERGY1{
                    field = chunk_var.energy;
                    // break;
                }
                when FIELD_U{
                    field = chunk_var.u;
                    // break;
                }
                when FIELD_P{
                    field = chunk_var.p;
                    // break;
                }
                when FIELD_SD{
                    field = chunk_var.sd;
                    // break;
                }
            }

            // likely no need for offset buffer with chapel
            pack_or_unpack (chunk_var.x, chunk_var.y, depth, setting_var.halo_depth, face, pack, field, buffer);
        }
    }

}
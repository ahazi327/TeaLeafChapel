module local_halos {
    use chunks;
    use settings;
    use profile;

    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const in depth: int){
        profiler.startTimer("halo_update_driver");

        if is_fields_to_exchange(setting_var) {
            local_halos (chunk_var.x, chunk_var.y, depth, setting_var.halo_depth, setting_var.fields_to_exchange,
            chunk_var.density, chunk_var.energy0, chunk_var.energy, chunk_var.u, chunk_var.p, chunk_var.sd);
        }
        profiler.stopTimer("halo_update_driver");
    }

    // The kernel for updating halos locally
    proc local_halos(const in x: int, const in y: int, const in depth: int, const in halo_depth: int,
    const ref fields_to_exchange: [0..<NUM_FIELDS] bool, ref density: [?D] real, ref energy0: [D] real,
    ref energy: [D] real, ref u: [D] real, ref p: [D] real, ref sd: [D] real){
        
        if fields_to_exchange[FIELD_DENSITY] then update_face(x, y, halo_depth, depth, density);

        if fields_to_exchange[FIELD_P] then update_face(x, y, halo_depth, depth, p);

        if fields_to_exchange[FIELD_ENERGY0] then update_face(x, y, halo_depth, depth, energy0);

        if fields_to_exchange[FIELD_ENERGY1] then update_face(x, y, halo_depth, depth, energy);

        if fields_to_exchange[FIELD_U] then update_face(x, y, halo_depth, depth, u);

        if fields_to_exchange[FIELD_SD] then update_face(x, y, halo_depth, depth, sd);
    }

    // Updates faces in turn.
    proc update_face (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [?Do] real){
        const x_domain = {0..<depth, halo_depth..<x-halo_depth};
        const y_domain = {halo_depth..<y-halo_depth, 0..<depth};

        coforall loc in Locales do on loc {
            forall (i, j) in Do.localSlice(x_domain) {
                // writeln("here  ", here.id);
                buffer[j, halo_depth-i-1] = buffer[j, i + halo_depth];
                buffer[j, x-halo_depth + i] = buffer[j, x-halo_depth-(i + 1)];
            }
            forall (i, j) in Do.localSlice(y_domain){
                buffer[y - halo_depth + j, i] = buffer[y - halo_depth - (j + 1), i];
                buffer[halo_depth - j - 1, i] = buffer[halo_depth + j, i];
            }
        }
    }
}


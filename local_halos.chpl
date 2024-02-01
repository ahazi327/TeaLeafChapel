module local_halos {
    use chunks;
    use settings;
    use profile;

    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const in depth: int){
        // profiler.startTimer("halo_update_driver");
        if is_fields_to_exchange(setting_var) {
            local_halos (chunk_var.x, chunk_var.y, depth, setting_var.halo_depth, setting_var.fields_to_exchange,
            chunk_var.density, chunk_var.energy0, chunk_var.energy, chunk_var.u, chunk_var.p, chunk_var.sd);
        }
        // profiler.stopTimer("halo_update_driver");

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
    proc update_face (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [?D] real){
        if useGPU{
            const west_domain = D[halo_depth..<y-halo_depth, 0..<depth]; // west side of global halo
            forall (i, j) in west_domain { 
                buffer[i, halo_depth-j-1] = buffer[i, j + halo_depth];
            }

            const east_domain = D[halo_depth..<y-halo_depth, x..<x+depth]; // east side of global halo
            forall (i, j) in east_domain { 
                buffer[i, x-halo_depth + j] = buffer[i, x-halo_depth-(j + 1)];
            }
            
            const south_domain = D[y..<y+depth, halo_depth..<x-halo_depth]; // south side of global halo
            forall (i, j) in south_domain { 
                buffer[y - halo_depth + i, j] = buffer[y - halo_depth - (i + 1), j];
            }

            const north_domain = D[0..<depth, halo_depth..<x-halo_depth];  //  north side of global halo
            forall (i, j) in north_domain {
                buffer[halo_depth - i - 1, j] = buffer[halo_depth + i, j];
            }
        } 
        else{
            const west_domain = D[halo_depth..<y-halo_depth, 0..<depth]; // west side of global halo
            forall (i, j) in west_domain { 
                buffer[i, halo_depth-j-1] = buffer[i, j + halo_depth];
            }

            const east_domain = D[halo_depth..<y-halo_depth, x..<x+depth]; // east side of global halo
            forall (i, j) in east_domain { 
                buffer[i, x-halo_depth + j] = buffer[i, x-halo_depth-(j + 1)];
            }
            
            const south_domain = D[y..<y+depth, halo_depth..<x-halo_depth]; // south side of global halo
            forall (i, j) in south_domain { 
                buffer[y - halo_depth + i, j] = buffer[y - halo_depth - (i + 1), j];
            }

            const north_domain = D[0..<depth, halo_depth..<x-halo_depth];  //  north side of global halo
            forall (i, j) in north_domain {
                buffer[halo_depth - i - 1, j] = buffer[halo_depth + i, j];
            }
        }
        
    }
}


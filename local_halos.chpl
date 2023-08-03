module local_halos {
    use chunks;
    use settings;
    use profile;

    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const in depth: int){
        profiler.startTimer("halo_update_driver");

        if is_fields_to_exchange(setting_var) {
            local_halos (chunk_var.x, chunk_var.y, depth, setting_var.halo_depth, chunk_var.neighbours, setting_var.fields_to_exchange,
            chunk_var.density, chunk_var.energy0, chunk_var.energy, chunk_var.u, chunk_var.p, chunk_var.sd, chunk_var.D);
        }
        profiler.stopTimer("halo_update_driver");
    }

    // The kernel for updating halos locally
    proc local_halos(const in x: int, const in y: int, const in depth: int, const in halo_depth: int, const ref chunk_neighbours : [-1..<NUM_FACES, -1..<NUM_FACES] (int, int),
    const ref fields_to_exchange: [0..<NUM_FIELDS] bool, ref density: [0..<y, 0..<x] real, ref energy0: [0..<y, 0..<x] real,
    ref energy: [0..<y, 0..<x] real, ref u: [0..<y, 0..<x] real, ref p: [0..<y, 0..<x] real, ref sd: [0..<y, 0..<x] real, ref D: [0..<y, 0..<x] int){
        
        if fields_to_exchange[FIELD_DENSITY] then update_face(x, y, halo_depth, chunk_neighbours, depth, density, D);

        if fields_to_exchange[FIELD_P] then update_face(x, y, halo_depth, chunk_neighbours, depth, p, D);

        if fields_to_exchange[FIELD_ENERGY0] then update_face(x, y, halo_depth, chunk_neighbours, depth, energy0, D);

        if fields_to_exchange[FIELD_ENERGY1] then update_face(x, y, halo_depth, chunk_neighbours, depth, energy, D);

        if fields_to_exchange[FIELD_U] then update_face(x, y, halo_depth, chunk_neighbours, depth, u, D);

        if fields_to_exchange[FIELD_SD] then update_face(x, y, halo_depth, chunk_neighbours, depth, sd, D);
    }

    // Updates faces in turn.
    proc update_face (const in x: int, const in y: int, const in halo_depth: int, const ref chunk_neighbours : [-1..<NUM_FACES, -1..<NUM_FACES] (int, int), const in depth: int, ref buffer: [0..<y, 0..<x] real, ref D: [0..<y, 0..<x] int){

        // update_left(x,y, halo_depth, depth, buffer, D);

        // update_right(x,y, halo_depth, depth, buffer, D);

        // update_bottom(x,y, halo_depth, depth, buffer, D);

        // update_top(x,y, halo_depth, depth, buffer, D);
        // coforall loc in Locales {
        //     on loc {
        // const localIndices = D.localSubdomain();
        forall (i, j) in {0..<depth, halo_depth..<x-halo_depth} {
        // Apply local indices to restrict operations to local subdomain
            buffer[j, halo_depth-i-1] = buffer[j, i + halo_depth];
            buffer[j, x-halo_depth + i] = buffer[j, x-halo_depth-(i + 1)];
        }
        forall (i, j) in {halo_depth..<y-halo_depth, 0..<depth} {
            buffer[y - halo_depth + j, i] = buffer[y - halo_depth - (j + 1), i];
            buffer[halo_depth - j - 1, i] = buffer[halo_depth + j, i];
        }
        // }
    // }

        // coforall 1..1 {  // Single iteration coforall loop to create a new task
        //     begin update_left(x, y, halo_depth, depth, buffer);
        //     begin update_right(x, y, halo_depth, depth, buffer);
        //     begin update_bottom(x, y, halo_depth, depth, buffer);
        //     begin update_top(x, y, halo_depth, depth, buffer);
        // }

    }

    // Updating halos in a direction
    // Update left halo.
    // proc update_left (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real, ref D: [?DOm] int) {  // TODO possibly update far left halo using right side column
    //    coforall loc in Locales {
    //         on loc {
    //             const localIndices = D.localSubdomain();
    //             forall (i, j) in localIndices[0..<depth, halo_depth..<x-halo_depth] {
    //             // Apply local indices to restrict operations to local subdomain
    //                 buffer[j, halo_depth-i-1] = buffer[j, i + halo_depth];
    //                 buffer[j, x-halo_depth + i] = buffer[j, x-halo_depth-(i + 1)];
    //             }
    //             forall (i, j) in localIndices[halo_depth..<y-halo_depth, 0..<depth] {
    //                 buffer[y - halo_depth + j, i] = buffer[y - halo_depth - (j + 1), i];
    //                 buffer[halo_depth - j - 1, i] = buffer[halo_depth + j, i];
    //             }
    //         }
    //     }
    //        //0.067s
    // }

    // // Update right halo.
    // proc update_right (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real, ref D: [?DOm] int)  {
    //     coforall loc in Locales {
    //         on loc {
    //             const localIndices = D.localSubdomain();
    //             forall (i, j) in localIndices[0..<depth, halo_depth..<x-halo_depth] {
                
    //             }
    //         }
    //     }
    // }

    // // Update bottom halo.
    // proc update_bottom (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real, ref D: [?DOm] int)  {
    //     coforall loc in Locales {
    //         on loc {
    //             const localIndices = D.localSubdomain();
                
    //         }
    //     }
    // }

    // // Update top halo.
    // proc update_top (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real, ref D: [?DOm] int)  {
    //     coforall loc in Locales {
    //         on loc {
    //             const localIndices = D.localSubdomain();
    //             forall (i, j) in localIndices[halo_depth..<y-halo_depth, 0..<depth] {
                
    //             }
    //         }
    //     }
    // }
}


module local_halos {
    use chunks;
    use settings;
    use profile;

    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const in depth: int){
        profiler.startTimer("halo_update_driver");

        if is_fields_to_exchange(setting_var) {
            local_halos (chunk_var.x, chunk_var.y, depth, setting_var.halo_depth, chunk_var.neighbours, setting_var.fields_to_exchange,
            chunk_var.density, chunk_var.energy0, chunk_var.energy, chunk_var.u, chunk_var.p, chunk_var.sd);
        }
        profiler.stopTimer("halo_update_driver");
    }

    // The kernel for updating halos locally
    proc local_halos(const in x: int, const in y: int, const in depth: int, const in halo_depth: int, const ref chunk_neighbours : [-1..<NUM_FACES, -1..<NUM_FACES] (int, int),
    const ref fields_to_exchange: [0..<NUM_FIELDS] bool, ref density: [0..<y, 0..<x] real, ref energy0: [0..<y, 0..<x] real,
    ref energy: [0..<y, 0..<x] real, ref u: [0..<y, 0..<x] real, ref p: [0..<y, 0..<x] real, ref sd: [0..<y, 0..<x] real){
        
        if fields_to_exchange[FIELD_DENSITY] then update_face(x, y, halo_depth, chunk_neighbours, depth, density);

        if fields_to_exchange[FIELD_P] then update_face(x, y, halo_depth, chunk_neighbours, depth, p);

        if fields_to_exchange[FIELD_ENERGY0] then update_face(x, y, halo_depth, chunk_neighbours, depth, energy0);

        if fields_to_exchange[FIELD_ENERGY1] then update_face(x, y, halo_depth, chunk_neighbours, depth, energy);

        if fields_to_exchange[FIELD_U] then update_face(x, y, halo_depth, chunk_neighbours, depth, u);

        if fields_to_exchange[FIELD_SD] then update_face(x, y, halo_depth, chunk_neighbours, depth, sd);
    }

    // Updates faces in turn.
    proc update_face (const in x: int, const in y: int, const in halo_depth: int, const ref chunk_neighbours : [-1..<NUM_FACES, -1..<NUM_FACES] (int, int), const in depth: int, ref buffer: [0..<y, 0..<x] real){

        update_left(x,y, halo_depth, depth, buffer);

        update_right(x,y, halo_depth, depth, buffer);

        update_bottom(x,y, halo_depth, depth, buffer);

        update_top(x,y, halo_depth, depth, buffer);
        // coforall 1..1 {  // Single iteration coforall loop to create a new task
        //     begin update_left(x, y, halo_depth, depth, buffer);
        //     begin update_right(x, y, halo_depth, depth, buffer);
        //     begin update_bottom(x, y, halo_depth, depth, buffer);
        //     begin update_top(x, y, halo_depth, depth, buffer);
        // }

    }

    // Updating halos in a direction
    // Update left halo.
    proc update_left (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real) {  // TODO possibly update far left halo using right side column
        [i in 0..<depth] buffer[halo_depth-i-1, halo_depth..<x-halo_depth] = buffer[i + halo_depth, halo_depth..<x-halo_depth];   //0.067s
    }

    // Update right halo.
    proc update_right (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real)  {
        [i in 0..<depth] buffer[x-halo_depth + i, halo_depth..<x-halo_depth] = buffer[x-halo_depth-(i + 1), halo_depth..<x-halo_depth];
    }

    // Update bottom halo.
    proc update_bottom (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real)  {
        [i in 0..<depth] buffer[halo_depth..<y-halo_depth, y - halo_depth + i] = buffer[halo_depth..<y-halo_depth, y - halo_depth - (i + 1)];
    }

    // Update top halo.
    proc update_top (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real)  {
        [i in 0..<depth] buffer[halo_depth..<y-halo_depth, halo_depth - i - 1] = buffer[halo_depth..<y-halo_depth, halo_depth + i];
    }
}


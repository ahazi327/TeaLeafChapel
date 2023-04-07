module local_halos {
    use chunks;
    use settings;


    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in depth: int){
    // Check that we actually have exchanges to perform
        if is_fields_to_exchange(setting_var) {
            forall cc in {0..<setting_var.num_chunks_per_rank} do {
                local_halos (chunk_var[cc].x, chunk_var[cc].y, depth, depth, chunk_var[cc].neighbours, setting_var.fields_to_exchange,
                chunk_var[cc].density, chunk_var[cc].energy0, chunk_var[cc].energy, chunk_var[cc].u, chunk_var[cc].p, chunk_var[cc].sd);
            }
        }
    }
    
    // local_halos(chunk_var.x, chunk_var.y, depth, setting_var.halo_depth, chunk_var.neighbours, setting_var.fields_to_exchange,
    //  chunk_var.density, chunk_var.energy0, chunk_var.energy, chunk_var.u, chunk_var.p, chunk_var.sd); // maybe not needed later

    // The kernel for updating halos locally
    proc local_halos(const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout chunk_neighbours : [0..<NUM_FACES] int,
    const ref fields_to_exchange: [0..<NUM_FIELDS] bool, inout density: [?D] real, inout energy0: [D] real,
    inout energy: [D] real, inout u: [D] real, inout p: [D] real, inout sd: [D] real){

        if fields_to_exchange[FIELD_DENSITY] then update_face(x, y, halo_depth, chunk_neighbours, depth, density);

        if fields_to_exchange[FIELD_P] then update_face(x, y, halo_depth, chunk_neighbours, depth, p);

        if fields_to_exchange[FIELD_ENERGY0] then update_face(x, y, halo_depth, chunk_neighbours, depth, energy0);

        if fields_to_exchange[FIELD_ENERGY1] then update_face(x, y, halo_depth, chunk_neighbours, depth, energy);

        if fields_to_exchange[FIELD_U] then update_face(x, y, halo_depth, chunk_neighbours, depth, u);

        if fields_to_exchange[FIELD_SD] then update_face(x, y, halo_depth, chunk_neighbours, depth, sd);
    }

    // Updates faces in turn.
    proc update_face (const in x: int, const in y: int, const in halo_depth: int, inout chunk_neighbours : [0..<NUM_FACES] int, const in depth: int, inout buffer: [?D] real){
        if (chunk_neighbours[CHUNK_LEFT] == EXTERNAL_FACE) then update_left(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_RIGHT] == EXTERNAL_FACE) then update_right(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_TOP] == EXTERNAL_FACE) then update_top(x,y, halo_depth, depth, buffer);
        
        if (chunk_neighbours[CHUNK_BOTTOM] == EXTERNAL_FACE) then update_bottom(x,y, halo_depth, depth, buffer);
    }

    // Updating halos in a direction
    // Update left halo.
    proc update_left (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real) {  //possibly just use out
        forall (kk, jj) in {0..<halo_depth, halo_depth..<y-halo_depth} do{
        //forall jj in halo_depth..<y-halo_depth do { // only using one forall loop
            //for kk in 0..<depth do{
                //var base: int = jj*x;
            // buffer[jj*x + (halo_depth-kk-1)] = buffer[jj*x+(halo_depth+kk)];  // this method of indexing seems to have a bunch of garbage results whenever kk >= halo_depth, 
            // only requires results where 0 <=kk < halo_depth
            buffer[halo_depth-kk-1, jj] = buffer[kk + halo_depth, jj];            
        }

    }

    // Update right halo.
    proc update_right (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real)  {
        // forall jj in halo_depth..<y-halo_depth do {
        //     for kk in 0..<depth do{ // using halo depth should be better
        forall (kk, jj) in {0..<halo_depth, halo_depth..<y-halo_depth} do{
            buffer[(x-halo_depth+kk), jj] = buffer[(x-halo_depth-1-kk), jj];
            // }
        }

    }

    // Update top halo. // TODO this seems like its the update bottom halo and vise versa
    proc update_top (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real)  {
        forall (jj , kk) in {0..<depth ,halo_depth..<x-halo_depth} do{ 
            buffer[kk, ((y)-halo_depth+jj)] = buffer[kk, ((y)-halo_depth-1-jj)];
            // buffer[kk, jj] = buffer[kk, jj];
        }

    }

    // Update bottom halo.
    proc update_bottom (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real)  {
        forall (jj, kk) in {0..<depth ,halo_depth..<x-halo_depth} do{ 
            buffer[kk, (halo_depth-jj-1)] = buffer[kk, (halo_depth+jj)];
        }
    }

}


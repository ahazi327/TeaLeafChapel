module local_halos {
    use chunks;
    use settings;


    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in depth: int){
    // Check that we actually have exchanges to perform
        if is_fields_to_exchange(setting_var) {

            // do remote halo driver first

            // for cc in {0..<setting_var.num_chunks_per_rank} do {
            local_halos (chunk_var[0].x, chunk_var[0].y, depth, setting_var.halo_depth, chunk_var[0].neighbours, setting_var.fields_to_exchange,
            chunk_var[0].density, chunk_var[0].energy0, chunk_var[0].energy, chunk_var[0].u, chunk_var[0].p, chunk_var[0].sd);
            // }
        }
    }

    // The kernel for updating halos locally
    proc local_halos(const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref chunk_neighbours : [-1..<NUM_FACES, -1..<NUM_FACES] (int, int),
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
    proc update_face (const in x: int, const in y: int, const in halo_depth: int, ref chunk_neighbours : [-1..<NUM_FACES, -1..<NUM_FACES] (int, int), const in depth: int, inout buffer: [?D] real){
        if (chunk_neighbours[CHUNK_LEFT] == EXTERNAL_FACE) then update_left(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_RIGHT] == EXTERNAL_FACE) then update_right(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_TOP] == EXTERNAL_FACE) then update_top(x,y, halo_depth, depth, buffer);
        
        if (chunk_neighbours[CHUNK_BOTTOM] == EXTERNAL_FACE) then update_bottom(x,y, halo_depth, depth, buffer);

        
        
        
    }

    // Updating halos in a direction
    // Update left halo.
    // TODO seems like only updating the left halo actually makes a difference
    proc update_left (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real) {  // TODO possibly update far left halo using right side column
        forall jj in halo_depth..<y-halo_depth do{
            for kk in 0..<depth do {
                buffer[halo_depth-kk-1, jj] = buffer[kk + halo_depth, jj]; 
            }  
        }
    }

    // Update right halo.
    proc update_right (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real)  {
        forall jj in halo_depth..<y-halo_depth do{
            for kk in 0..<depth do {
                buffer [(x-halo_depth + kk), jj] = buffer [((x-halo_depth)-(kk + 1)), jj];
            }
        }
    }

    // Update bottom halo.
     // TODO this seems like its the update bottom halo and vise versa
     // TODO last 0.13 error seems to be coming from the top and bottom halos not doing anything, even if theyre removed it outputs the same
    proc update_bottom (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real)  {
        for jj in {0..<depth} do{ 
            forall kk in {halo_depth..<x-halo_depth} do {
                buffer[kk, ((y - halo_depth) + jj)] = buffer[kk, ((y - halo_depth) - (jj + 1))];
            }
        }
    }

    // Update top halo.
    proc update_top (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, inout buffer: [?D] real)  {
        for jj in {0..<depth} do{ 
            forall kk in {halo_depth..<x-halo_depth} do {
                buffer[kk, (halo_depth - jj - 1)] = buffer[kk, (halo_depth+jj)];
            }
        }
    }
}


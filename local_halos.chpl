module local_halos {
    use chunks;
    use settings;
    use profile;

    param c : real = 0.000005;
    // Invoke the halo update kernels using driver
    proc halo_update_driver (ref chunk_var : [0..<setting_var.num_chunks] chunks.Chunk, ref setting_var : settings.setting, const in depth: int){
        profiler.startTimer("halo_update_driver");
        if is_fields_to_exchange(setting_var) {

            // do remote halo driver first

            // for cc in {0..<setting_var.num_chunks_per_rank} do {
            local_halos (chunk_var[0].x, chunk_var[0].y, depth, setting_var.halo_depth, chunk_var[0].neighbours, setting_var.fields_to_exchange,
            chunk_var[0].density, chunk_var[0].energy0, chunk_var[0].energy, chunk_var[0].u, chunk_var[0].p, chunk_var[0].sd);
            // }
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

        // cobegin{ //seems to be worth using cobegin when grid size is 1000 x 1000 or bigger

        if (chunk_neighbours[CHUNK_LEFT] == EXTERNAL_FACE) then update_left(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_RIGHT] == EXTERNAL_FACE) then update_right(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_BOTTOM] == EXTERNAL_FACE) then update_bottom(x,y, halo_depth, depth, buffer);

        if (chunk_neighbours[CHUNK_TOP] == EXTERNAL_FACE) then update_top(x,y, halo_depth, depth, buffer);
        // }
    }

    // Updating halos in a direction
    // Update left halo.
    proc update_left (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real) {  // TODO possibly update far left halo using right side column
        // foreach (jj, kk) in {halo_depth..<y-halo_depth, 0..<depth} do{        //speed: 0.05s    tested with 512x512 grid 20 timesteps cheby solver
        //     buffer[halo_depth-kk-1, jj] = buffer[kk + halo_depth, jj]; 
        // }
        
        // forall (kk, jj) in {0..<depth, halo_depth..<y-halo_depth} do{       //speed: 0.8s  // do more tests on this
        //   buffer[halo_depth-kk-1, jj] = buffer[kk + halo_depth, jj]; 
        // }


        // ref buffer_local = buffer[buffer.localSubdomain()];                     //speed: 0.07s
        // foreach i in 0..<depth do {
        //     buffer[halo_depth-i-1, halo_depth..<x-halo_depth] = buffer[i + halo_depth, halo_depth..<x-halo_depth]; 
        // }
        [i in 0..<depth] buffer[halo_depth-i-1, halo_depth..<x-halo_depth] = buffer[i + halo_depth, halo_depth..<x-halo_depth];   //0.067s

        // forall i in 0..<depth do {
        //     buffer[halo_depth-depth-1, halo_depth..<x-halo_depth] = buffer[i + halo_depth, halo_depth..<x-halo_depth]; 
        // }


    }

    // Update right halo.
    proc update_right (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real)  {

        // foreach (jj, kk) in {halo_depth..<y-halo_depth, 0..<depth} do{
        //     buffer [(x-halo_depth + kk), jj] = buffer [((x-halo_depth)-(kk + 1)), jj];
        // }

        // foreach i in 0..<depth do {
        //     buffer [x-halo_depth + i, halo_depth..<x-halo_depth] = buffer[x-halo_depth-(i + 1), halo_depth..<x-halo_depth];
        // }

        // forall (kk, jj) in {0..<depth, halo_depth..<y-halo_depth} do{    
        //     buffer [(x-halo_depth + kk), jj] = buffer [((x-halo_depth)-(kk + 1)), jj];
        // }

        // ref buffer_local = buffer[buffer.localSubdomain()];
        // [i in 0..<depth] buffer [x-halo_depth + i, halo_depth..<x-halo_depth] = buffer[x-halo_depth-(i + 1), halo_depth..<x-halo_depth];

        [i in 0..<depth] buffer[x-halo_depth + i, halo_depth..<x-halo_depth] = buffer[x-halo_depth-(i + 1), halo_depth..<x-halo_depth];

        // // forall i in 0..<depth do {
        //     buffer [x-halo_depth + depth, halo_depth..<x-halo_depth] = c;
        // // }
    }

    // Update bottom halo.
    proc update_bottom (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real)  {
        // foreach (kk, jj) in  {halo_depth..<x-halo_depth, 0..<depth} do{
        //         buffer[kk, ((y - halo_depth) + jj)] = buffer[kk, ((y - halo_depth) - (jj + 1))];
        // }    

        // forall (jj, kk) in  {0..<depth, halo_depth..<x-halo_depth} do{
        //         buffer[kk, ((y - halo_depth) + jj)] = buffer[kk, ((y - halo_depth) - (jj + 1))];
        // }   

        // ref buffer_local = buffer[buffer.localSubdomain()];
        // foreach i in 0..<depth do {
        //     buffer[halo_depth..<y-halo_depth, y - halo_depth + i] = buffer[halo_depth..<y-halo_depth, y - halo_depth - (i + 1)];
        // }
        [i in 0..<depth] buffer[halo_depth..<y-halo_depth, y - halo_depth + i] = buffer[halo_depth..<y-halo_depth, y - halo_depth - (i + 1)];

        // // forall i in 0..<depth do {
        //     buffer[halo_depth..<y-halo_depth, y - halo_depth + depth] = c;
        // // }
    }

    // Update top halo.
    proc update_top (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real)  {
        // foreach (kk, jj) in  {halo_depth..<x-halo_depth, 0..<depth} do{
        //         buffer[kk, (halo_depth - jj - 1)] = buffer[kk, (halo_depth+jj)];
        // }

        // forall (jj, kk) in  {0..<depth, halo_depth..<x-halo_depth} do{
        //         buffer[kk, (halo_depth - jj - 1)] = buffer[kk, (halo_depth+jj)];
        // }

        // ref buffer_local = buffer[buffer.localSubdomain()];
        // foreach i in 0..<depth do {
        //     buffer[halo_depth..<y-halo_depth, halo_depth - i - 1] = buffer[halo_depth..<y-halo_depth, halo_depth + i];
        // }
        [i in 0..<depth] buffer[halo_depth..<y-halo_depth, halo_depth - i - 1] = buffer[halo_depth..<y-halo_depth, halo_depth + i];
        // };

        // // forall i in 0..<depth do {
        //     buffer[halo_depth..<y-halo_depth, halo_depth - depth - 1] = c;
        // // }
        
        // // new way of doing array slices in verse but need to find a more efficient way of doing all array slices at once without making too many threads for a short period 
    }
}


/*
 *      SET CHUNK STATE KERNEL
 *		Sets up the chunk geometry.
 */

// Entry point for set chunk state kernel
module set_chunk_state{
    import chunks;
    import settings;
    proc set_chunk_state(in states : settings.state, inout chunk_var : chunks.Chunk, in setting_var : settings.setting){
        // Set the initial state
        forall (i, j) in {0..<setting_var.x, 0..<setting_var.y} do {
            chunk_var.energy0[(i, j)] = states[0, 0].energy;
            chunk_var.density[(i, j)] = states[0, 0].density;
        }


        // Apply all of the states in turn
//        forall ss in 1..<setting_var.num_states do {
        // use a 3d domain for this one
        forall (kk, jj, ss) in {0..<chunk_var.x, 0..<chunk_var.y, 1..<setting_var.num_states } do {
            var apply_state: bool;

            if states[ss].geometry == settings.Geometry.RECTANGULAR {
                apply_state = (
                    chunk_var.vertex_x[kk+1] >= states[ss].x_min & 
                    chunk_var.vertex_x[kk] < states[ss].x_max    &
                    chunk_var.vertex_y[jj+1] >= states[ss].y_min &
                    chunk_var.vertex_y[jj] < states[ss].y_max);
            }
            
            else if states[ss].geometry == settings.Geometry.CIRCULAR {
                var radius: real;
                radius = sqrt((cell_x[kk]-states[ss].x_min)*
                    (chunk_var.cell_x[kk]-states[ss].x_min)+
                    (chunk_var.cell_y[jj]-states[ss].y_min)*
                    (chunk_var.cell_y[jj]-states[ss].y_min));

                apply_state = (radius <= states[ss].radius);
            }
            else if states[ss].geometry == settings.Geometry.POINT{
                apply_state = (
                        chunk_var.vertex_x[kk] == states[ss].x_min &&
                        chunk_var.vertex_y[jj] == states[ss].y_min);
            }
            if apply_state
            {
                var iii : int = kk + jj*chunk_var.x;
                chunk_var.energy0[iii] = states[ss].energy;
                chunk_var.density[iii] = states[ss].density;
            }
        }
//        }
        // Set an initial state for u
        var Domain = {1..<chunk_var.y, 1..<chunk_var.x};
        
        forall (i, j) in Domain do{
            chunk_var.u[(i, j)] = chunk_var.energy0[(i, j)]*chunk_var.density[(i, j)];
        }

    }

}

/*
 *      SET CHUNK STATE KERNEL
 *		Sets up the chunk geometry.
 */

// Entry point for set chunk state kernel
module set_chunk_state{
    import chunks;
    import settings;
    proc set_chunk_state(ref states : [0..<setting_var.num_states]settings.state, ref chunk_var : chunks.Chunk, ref setting_var : settings.setting){  //come back later and change args
        // Set the initial state
        chunk_var.energy0= states[0].energy;
        chunk_var.density = states[0].density;

        // Apply all of the states in turn
        for ss in 1..<setting_var.num_states do { // TODO try turning back into a single loop  // use a 3d domain for this one
            for jj in 0..<chunk_var.y do {
                for kk in 0..<chunk_var.x do {

                    var apply_state: bool = false;

                    if states[ss].geometry == settings.Geometry.RECTANGULAR {
                        if (chunk_var.vertex_x[kk+1] >= states[ss].x_min) && 
                            (chunk_var.vertex_x[kk] < states[ss].x_max)    &&
                            (chunk_var.vertex_y[jj+1] >= states[ss].y_min) &&
                            (chunk_var.vertex_y[jj] < states[ss].y_max) then apply_state = true;
                    }
                    
                    else if states[ss].geometry == settings.Geometry.CIRCULAR {
                        var radius: real;
                        
                        radius = sqrt((chunk_var.cell_x[kk]-states[ss].x_min)*
                            (chunk_var.cell_x[kk]-states[ss].x_min)+
                            (chunk_var.cell_y[jj]-states[ss].y_min)*
                            (chunk_var.cell_y[jj]-states[ss].y_min));

                        if radius <= states[ss].radius then apply_state = true;
                    }
                    else if states[ss].geometry == settings.Geometry.POINT{
                        if chunk_var.vertex_x[kk] == states[ss].x_min && chunk_var.vertex_y[jj] == states[ss].y_min then 
                            apply_state = true;
                    }
                    if apply_state 
                    {
                        chunk_var.energy0[kk, jj] = states[ss].energy;
                        chunk_var.density[kk, jj] = states[ss].density;
                    }
                }
            }
        }
            var Domain = {1..<chunk_var.x-1, 1..<chunk_var.y-1};
            chunk_var.u[Domain] = chunk_var.energy0[Domain] *chunk_var.density[Domain];
    }
/*
 *      SET CHUNK STATE DRIVER
 */
    // Invokes the set chunk state kernel
    proc set_chunk_state_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, ref states : [0..<setting_var.num_states] settings.state){
        // Issue kernel to all local chunks
        set_chunk_state(states, chunk_var[0], setting_var);
    }


}

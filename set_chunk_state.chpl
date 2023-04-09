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
        // use a 3d domain for this one
        forall (kk, jj, ss) in {0..<chunk_var.x, 0..<chunk_var.y, 1..<setting_var.num_states } with (ref chunk_var) do {
            var apply_state: bool;

            if states[ss].geometry == settings.Geometry.RECTANGULAR {
                
                apply_state = (
                    (chunk_var.vertex_x[kk+1] >= states[ss].x_min) & 
                    (chunk_var.vertex_x[kk] < states[ss].x_max)    &
                    (chunk_var.vertex_y[jj+1] >= states[ss].y_min) &
                    (chunk_var.vertex_y[jj] < states[ss].y_max));
            }
            
            else if states[ss].geometry == settings.Geometry.CIRCULAR {
                var radius: real;
                radius = sqrt((chunk_var.cell_x[kk]-states[ss].x_min)*
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
                chunk_var.energy0[kk, jj] = states[ss].energy;
                chunk_var.density[kk, jj] = states[ss].density;
            }
        }
            chunk_var.u = chunk_var.energy0 *chunk_var.density;
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

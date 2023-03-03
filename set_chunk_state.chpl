/*
 *      SET CHUNK STATE KERNEL
 *		Sets up the chunk geometry.
 */

// Entry point for set chunk state kernel
module set_chunk_state{
    use Math;
    import chunks;
    import settings;
    proc set_chunk_state(in states : settings.state, in chunk_var : chunks.Chunk, in setting_var : settings.setting){
        // Set the initial state
        forall ii in 0..<setting_var.x*setting_var.y do {
            chunk_var.energy0[ii] = states[0].energy;
            chunk_var.density[ii] = states[0].density;
        }


        // Apply all of the states in turn
        forall ss in 1..<setting_var.num_states do {
            forall jj in 0..<chunk_var.y do {
                forall kk in 0..<chunk_var.x do {
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
                    }
                    else if states[ss].geometry == settings.Geometry.POINT{
                        apply_state = (
                                chunk_var.vertex_x[kk] == states[ss].x_min &&
                                chunk_var.vertex_y[jj] == states[ss].y_min);
                    }
                    if apply_state
                    {
                        var iii : int = kk + jj*chunk_var.x;
                        energy0[iii] = states[ss].energy;
                        density[iii] = states[ss].density;
                    }
                }
            }
        }
        // Set an initial state for u
        var Domain = {1..<chunk_var.y, 1..<chunk_var.x};
        
        forall ii in Domain do{
            chunk_var.u[ii] = chunk_var.energy0[ii]*chunk_var.density[ii];
        }

    }

}
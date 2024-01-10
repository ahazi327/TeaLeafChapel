/*
 *      SET CHUNK STATE KERNEL
 *		Sets up the chunk geometry.
 */

// Entry point for set chunk state kernel
module set_chunk_state{
    import chunks;
    import settings;
    use profile;

    proc set_chunk_state(ref states : [0..<setting_var.num_states]settings.state, ref chunk_var : chunks.Chunk, 
                        const ref setting_var : settings.setting){ 
        // profiler.startTimer("set_chunk_state");
        
        // Set the initial state
        forall ij in chunk_var.energy0.domain with (ref chunk_var){
            chunk_var.energy0[ij] = states[0].energy;
            chunk_var.density[ij] = states[0].density;
        }
        // Apply all of the states in turn
        for ss in 1..<setting_var.num_states do {

            // If a state boundary falls exactly on a cell boundary
            // then round off can cause the state to be put one cell
            // further than expected. This is compiler/system dependent.
            // To avoid this, a state boundary is reduced/increased by a
            // 100th of a cell width so it lies well within the intended
            // cell. Because a cell is either full or empty of a specified
            // state, this small modification to the state extents does
            // not change the answer.
            states[ss].x_min += (setting_var.dx/100.0);
            states[ss].y_min += (setting_var.dy/100.0);
            states[ss].x_max -= (setting_var.dx/100.0);
            states[ss].y_max -= (setting_var.dy/100.0);

            for (kk, jj) in {0..<chunk_var.y, 0..<chunk_var.x} do {

                var apply_state: bool = false;

                if states[ss].geometry == settings.Geometry.RECTANGULAR {
                    if (chunk_var.vertex_x[jj+1] >= states[ss].x_min) && 
                    (chunk_var.vertex_x[jj] < states[ss].x_max) && 
                    (chunk_var.vertex_y[kk+1] >= states[ss].y_min) && 
                    (chunk_var.vertex_y[kk] < states[ss].y_max){
                        apply_state = true;
                    }
                }
                else if states[ss].geometry == settings.Geometry.CIRCULAR {
                    var radius: real;
                    
                    radius = sqrt(
                        ((chunk_var.cell_x[jj]-states[ss].x_min)*
                        (chunk_var.cell_x[jj]-states[ss].x_min))+
                        ((chunk_var.cell_y[kk]-states[ss].y_min)*
                        (chunk_var.cell_y[kk]-states[ss].y_min)));

                    if radius <= states[ss].radius then apply_state = true;
                }
                else if states[ss].geometry == settings.Geometry.POINT{
                    if chunk_var.vertex_x[jj] == states[ss].x_min && 
                    chunk_var.vertex_y[kk] == states[ss].y_min {
                        apply_state = true;
                    }
                }
                if apply_state 
                {
                    // Note: reversed kk and jj to match output from reference code
                    chunk_var.energy0[kk, jj] = states[ss].energy;  
                    chunk_var.density[kk, jj] = states[ss].density;
                }
            }
        }
        for ij in chunk_var.u.domain do chunk_var.u[ij] = chunk_var.energy0[ij] * chunk_var.density[ij];
        
        // profiler.stopTimer("set_chunk_state");
    }
/*
 *      SET CHUNK STATE DRIVER
 */
    // Invokes the set chunk state kernel
    proc set_chunk_state_driver (ref chunk_var : chunks.Chunk, const ref setting_var : settings.setting, 
                                ref states : [0..<setting_var.num_states] settings.state){
        // Issue kernel to all local chunks
        set_chunk_state(states, chunk_var, setting_var);
    }


}

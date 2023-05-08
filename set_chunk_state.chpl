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
            // writeln(" xmins are : ", states[ss].x_min);

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

            // writeln(" xmin and xmax values: " ,states[ss].x_min, "  ", states[ss].x_max);
            
            for (jj, kk) in {0..<chunk_var.x, 0..<chunk_var.y} do {

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
                    chunk_var.energy0[jj, kk] = states[ss].energy;  // Note: reversed kk and jj to match output from reference code
                    chunk_var.density[jj, kk] = states[ss].density;
                    // writeln(" when y and x are : ", jj, " ", kk);
                }
            }
        }
            // writeln("current  density array : \n",  chunk_var.density);

            var Domain = {1..<chunk_var.x-1, 1..<chunk_var.y-1};
            chunk_var.u[Domain] = chunk_var.energy0[Domain] *chunk_var.density[Domain];
            // writeln("current  u array : \n",  chunk_var.u);
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

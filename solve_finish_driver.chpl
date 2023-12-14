module solve_finish_driver {
    use settings;
    use chunks;
    use solver_methods;
    use local_halos;
    use profile;

    proc solve_finished_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting){
        // Calls all kernels that wrap up a solve regardless of solver
        var exact_error: real = 0.0;

        if setting_var.check_result {
            calculate_residual(setting_var.halo_depth, chunk_var.u, chunk_var.u0, chunk_var.r, 
                                chunk_var.kx, chunk_var.ky);

            calculate_2norm(setting_var.halo_depth, chunk_var.r, exact_error);
            
        }

        finalise(chunk_var.x, chunk_var.y, setting_var.halo_depth, chunk_var.energy, chunk_var.density, 
                chunk_var.u);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_ENERGY1] = true;
        halo_update_driver(chunk_var, setting_var, 1);
    }

}
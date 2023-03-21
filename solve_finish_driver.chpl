module solve_finish_driver {
    use settings;
    use chunks;
    use solver_methods;
    use local_halos;

    proc solve_finished_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting){
        // Calls all kernels that wrap up a solve regardless of solver
        var exact_error: real = 0.0;

        if setting_var.check_result {
            calculate_residual(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, chunk_var[0].u0, chunk_var[0].r,
                chunk_var[0].kx, chunk_var[0].ky);

            calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].r, exact_error);
            
        }

        finalise(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].energy, chunk_var[0].density, chunk_var[0].u);

        setting_var.fields_to_exchange[FIELD_ENERGY1] = true;
        halo_update_driver(chunk_var, setting_var, 1);
    }

}
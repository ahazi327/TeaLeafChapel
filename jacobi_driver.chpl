module jacobi_driver {
    use chunks;
    use settings;
    use local_halos;
    use solver_methods;
    use jacobi;

    // Performs a full solve with the Jacobi solver kernels
    proc jacobi_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, out error: real){

        jacobi_init_driver(chunk_var, setting_var, rx, ry);

        // Iterate till convergence
        var tt: int;

        for tt in 0..<setting_var.max_iters do {
            jacobi_main_step_driver(chunk_var, setting_var, tt, error);

            halo_update_driver(chunk_var, setting_var, 1);

            if(abs(error) < setting_var.eps) then break;
        }
        // print_and_log(settings, "Jacobi: \t\t%d iterations\n", tt);

    }

    // Invokes the CG initialisation kernels
    proc jacobi_init_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real){

        jacobi_init(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].coefficient, chunk_var[0].rx, chunk_var[0].ry,
            chunk_var[0].u, chunk_var[0].u0, chunk_var[0].energy, chunk_var[0].density, chunk_var[0].kx, chunk_var[0].ky);

        copy_u(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, chunk_var[0].u0);

        // Need to update for the matvec
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
    }

    // Invokes the main Jacobi solve kernels
    proc jacobi_main_step_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in tt: int,
    inout error: real){

        jacobi_iterate(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, chunk_var[0].u0, 
            chunk_var[0].r, error, chunk_var[0].kx, chunk_var[0].ky);

        if tt % 50 == 0 {
            halo_update_driver(chunk_var, setting_var, 1);

            calculate_residual(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, chunk_var[0].u0, chunk_var[0].r,
                chunk_var[0].kx, chunk_var[0].ky);
            
            calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].r, error);
        }
    }

}
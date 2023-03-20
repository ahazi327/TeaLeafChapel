module cheby_driver{
    use eigenvalue_driver;
    use chunks;
    use settings;
    use local_halos;

    proc cheby_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, out error: real){

        var tt, est_iterations, num_cheby_iters: int;
        var rro: real;

        // Perform CG initialisation
        cg_init_driver

        // Iterate till convergence
        //TODO continue this
    }

    proc cg_init_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in num_cg_iters: int,
    out bb: real){

        var bb: real = 0.0;
        eigenvalue_driver_initialise(chunks, settings, num_cg_iters);
        // cheby_coef_driver(chunks, settings, settings->max_iters-num_cg_iters);   //TODO un comment this later

        // chunks per rank loop
        calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, bb);

        cheby_init(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].theta, chunk_var[0].u, chunk_var[0].u0,
        chunk_var[0].p, chunk_var[0].r, chunk_var[0].w, chunk_var[0].kx, chunk_var[0].ky);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
        halo_update_driver(chunks, settings, 1);

        //sum over ranks
    }

    // Performs the main iteration step
    proc cheby_main_step_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in num_cg_iters: int,
    inout is_calc_2norm: bool, out error: real){
        // chunks per rank loop
        cheby_iterate(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].cheby_alphas[num_cheby_iters],
        chunk_var[0].cheby_betas[num_cheby_iters], chunk_var[0].u, chunk_var[0].u0,
        chunk_var[0].p, chunk_var[0].r, chunk_var[0].w, chunk_var[0].kx, chunk_var[0].ky);

        if is_calc_2norm then
        {
            var error: real = 0.0;

            calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].r, error);
        }


    }


}
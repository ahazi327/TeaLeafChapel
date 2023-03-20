module cg_driver {
    use cg;
    use settings;
    use chunks;
    use local_halos;
    use solver_methods;
    //TODO ADD PROFILING

    // Performs a full solve with the CG solver kernels
    proc cg_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, out error: real){
        //var tt: int;
        var rro : real;

        // Perform CG initialisation
        cg_init(chunk_var, setting_var, rx, ry, rro);

        // Iterate till convergence
        for tt in 0..< setting_var.max_iters do {  // using serial execution for correctness.
            cg_main_step_driver(chunk_var, setting_var, tt, rro, error);

            halo_update_driver (chunk_var, setting_var, 1);

            if (sqrt(abs(error)) < setting_var.eps) then break;
        }

        // print log
    }

    // Invokes the CG initialisation kernels
    proc cg_init (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, inout rro: real) {
        rro = 0.0;
        forall cc in {0.. <setting_var.num_chunks_per_rank} do {
            run_cg_init(chunk_var[cc].x, chunk_var[cc].y, setting_var.halo_depth, chunk_var[cc].coefficient, rx, ry, rro,
            chunk_var[cc].density, chunk_var[cc].energy, chunk_var[cc].u, chunk_var[cc].p, chunk_var[cc].r, chunk_var[cc].w,
            chunk_var[cc].kx, chunk_var[cc].ky);
        }

        // Need to update for the matvec
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
        setting_var.fields_to_exchange[FIELD_P] = true;
        //remote halo driver here TODO if needed, currently seems like an MPI specific function
        halo_update_driver(chunk_var, setting_var, 1);

        //sum over ranks TODO This seems to be an MPI things, so ignore for now

        forall cc in {0.. <setting_var.num_chunks_per_rank} do {
            copy_u(chunk_var[cc].x, chunk_var[cc].y, setting_var.halo_depth, chunk_var[cc].u, chunk_var[cc].u0);
        }

    }

    // Invokes the main CG solve kernels
    proc cg_main_step_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in tt : int,
    out rro: real, inout error: real){
        var pw: real;

        forall cc in {0.. <setting_var.num_chunks_per_rank} do {
            cg_calc_w (chunk_var[cc].x, chunk_var[cc].y, setting_var.halo_depth, pw, chunk_var[cc].p, chunk_var[cc].w, chunk_var[cc].kx,
            chunk_var[cc].ky);
        }
        //MPI sum over ranks function

        var alpha :real = rro / pw;
        var rrn: real;
    

        forall cc in {0.. <setting_var.num_chunks_per_rank} do {
            chunk_var[cc].cg_alphas[tt] = alpha;

            cg_calc_ur(chunk_var[cc].x, chunk_var[cc].y, setting_var.halo_depth, alpha, rrn, chunk_var[cc].u, chunk_var[cc].p,
            chunk_var[cc].r, chunk_var[cc].w);
        }

        var beta : real = rrn / rro;
        forall cc in {0.. <setting_var.num_chunks_per_rank} do {
            chunk_var[cc].cg_beta[tt] = alpha;
            cg_calc_p (chunk_var[cc].x, chunk_var[cc].y, setting_var.halo_depth, beta, chunk_var[cc].p,
            chunk_var[cc].r);


        }

        error = rrn;
        rro = rrn;
    }

}
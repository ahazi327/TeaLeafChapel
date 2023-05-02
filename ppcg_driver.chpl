module ppcg_driver{
    use chunks;
    use settings;
    use cg_driver;
    use cg;
    use local_halos;
    use eigenvalue_driver;
    use solver_methods;
    use ppcg;

    // Performs a full solve with the PPCG solver
    proc ppcg_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, ref error: real){
        var tt_prime, num_ppcg_iters: int;
        var rro: real;
        var is_switch_to_ppcg : int;

        // Perform CG initialisation  // is this supposed to be ppcg???
        cg_init_driver(chunk_var, setting_var, rx, ry, rro);

        // Iterate till convergence
        for tt in 0..<setting_var.max_iters do {
            
            // If we have already ran PPCG inner iterations, continue
            // If we are error switching, check the error
            // If not error switching, perform preset iterations
            // Perform enough iterations to converge eigenvalues
            
            if (num_ppcg_iters:bool) || setting_var.error_switch then
                is_switch_to_ppcg = (error < setting_var.eps_lim) & (tt > CG_ITERS_FOR_EIGENVALUES);    
            else
                is_switch_to_ppcg = (tt > setting_var.presteps) & (error < ERROR_SWITCH_MAX);

            // writeln ("what is is_switch_to_ppcg : ", is_switch_to_ppcg, "\n");
            if is_switch_to_ppcg == 0 then
                // Perform a CG iteration
                cg_main_step_driver(chunk_var, setting_var, tt, rro, error);
            else num_ppcg_iters += 1;

            // If first step perform initialisation
            if num_ppcg_iters == 1{
                // Initialise the eigenvalues and Chebyshev coefficients
                eigenvalue_driver_initialise(chunk_var, setting_var, tt);
                cheby_coef_driver(chunk_var, setting_var, setting_var.ppcg_inner_steps);

                ppcg_init_driver(chunk_var, setting_var, rro);

                // Perform the main step
                ppcg_main_step_driver(chunk_var, setting_var, rro, error);
            }
        
            halo_update_driver(chunk_var, setting_var, 1);
            if(abs(error) < setting_var.eps) then break;
            tt_prime += 1;
        }

        writeln("CG iterations:   ",  tt_prime-num_ppcg_iters+1, " ");
        writeln("PPCG iterations: ",  num_ppcg_iters, " (", setting_var.ppcg_inner_steps," inner iterations per)");
    }

    // Invokes the PPCG initialisation kernels
    proc ppcg_init_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rro: real){
        
        calculate_residual(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, chunk_var[0].u0, chunk_var[0].r,
        chunk_var[0].kx, chunk_var[0].ky);
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_P] = true;
        halo_update_driver(chunk_var, setting_var, 1);

    }

    // Invokes the main PPCG solver kernels
    proc ppcg_main_step_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rro: real, inout error: real) {
        var pw: real;

        cg_calc_w(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, pw, chunk_var[0].p, chunk_var[0].w, chunk_var[0].kx, chunk_var[0].ky);

        var alpha : real = rro / pw;
        var rrn : real = 0.0;

        cg_calc_ur (chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, alpha, rrn, chunk_var[0].u, chunk_var[0].p,
            chunk_var[0].r, chunk_var[0].w);

        // Perform the inner iterations
        ppcg_inner_iterations(chunk_var, setting_var);

        rrn = 0.0;

        calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].r, error);

        var beta : real = rrn / rro;

        cg_calc_p(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, beta, chunk_var[0].p, chunk_var[0].r);

        error = rrn;
        rro = rrn;
    }

    // Performs the inner iterations of the PPCG solver
    proc ppcg_inner_iterations(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting){
        ppcg_init (chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].theta, chunk_var[0].r, chunk_var[0].sd);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_SD] = true;

        for pp in 0..<setting_var.ppcg_inner_steps do {
            halo_update_driver(chunk_var, setting_var, 1);

            ppcg_inner_iteration(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].cheby_alphas[pp], 
            chunk_var[0].cheby_betas[pp], chunk_var[0].u, chunk_var[0].r, chunk_var[0].sd, chunk_var[0].kx, chunk_var[0].ky);
        }

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_P] = true;

    }
}
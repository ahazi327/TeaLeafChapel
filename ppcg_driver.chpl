module ppcg_driver{
    use profile;
    use chunks;
    use settings;
    use cg_driver;
    use cg;
    use local_halos;
    use eigenvalue_driver;
    use solver_methods;
    use ppcg;
    
    // Performs a full solve with the PPCG solver
    proc ppcg_driver(ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rx: real,
                        ref ry: real, ref error: real, ref interation_count : int, 
                        ref interation_count_prime : int, ref inner_steps : int){
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

            if is_switch_to_ppcg == 0 then
                // Perform a CG iteration
                cg_main_step_driver(chunk_var, setting_var, tt, rro, error);
            else {
            
                num_ppcg_iters += 1;

                // If first step perform initialisation
                if num_ppcg_iters == 1{
                    // Initialise the eigenvalues and Chebyshev coefficients
                    eigenvalue_driver_initialise(chunk_var, setting_var, tt);
                    cheby_coef_driver(chunk_var, setting_var.ppcg_inner_steps);

                    ppcg_init_driver(chunk_var, setting_var, rro);

                }
                // Perform the main step
                ppcg_main_step_driver(chunk_var, setting_var, rro, error);
                }
        
            halo_update_driver(chunk_var, setting_var, 1);
            if(abs(error) < setting_var.eps) then break;
            tt_prime += 1;
        }
        interation_count = tt_prime-num_ppcg_iters+1;
        interation_count_prime = num_ppcg_iters;
        inner_steps = setting_var.ppcg_inner_steps;
        writeln("CG iterations:   ",  tt_prime-num_ppcg_iters+1, " ");
        writeln("PPCG iterations: ",  num_ppcg_iters, " (", setting_var.ppcg_inner_steps," inner iterations per)");
    }

    // Invokes the PPCG initialisation kernels
    proc ppcg_init_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rro: real){
        
        calculate_residual(setting_var.halo_depth, chunk_var.u, chunk_var.u0, chunk_var.r, chunk_var.kx, 
                            chunk_var.ky);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_P] = true;
        halo_update_driver(chunk_var, setting_var, 1);

    }

    // Invokes the main PPCG solver kernels
    proc ppcg_main_step_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rro: real, 
                                ref error: real){

        var pw: real;
        cg_calc_w(setting_var.halo_depth, pw, chunk_var.p, chunk_var.w, chunk_var.kx, 
                  chunk_var.ky, chunk_var.temp);

        const alpha : real = rro / pw;
        var rrn : real = 0.0;

        cg_calc_ur (setting_var.halo_depth, alpha, rrn, chunk_var.u, chunk_var.p, chunk_var.r, 
                    chunk_var.w, chunk_var.temp);

        // Perform the inner iterations
        ppcg_inner_iterations(chunk_var, setting_var);

        rrn = 0.0;

        calculate_2norm(setting_var.halo_depth, chunk_var.r, rrn);

        const beta : real = rrn / rro;

        cg_calc_p(setting_var.halo_depth, beta, chunk_var.p, chunk_var.r);

        error = rrn;
        rro = rrn;
    }

    // Performs the inner iterations of the PPCG solver
    proc ppcg_inner_iterations(ref chunk_var : chunks.Chunk, ref setting_var : settings.setting){
        
        ppcg_init(setting_var.halo_depth, chunk_var.theta, chunk_var.r, chunk_var.sd);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_SD] = true;

        for pp in 0..<setting_var.ppcg_inner_steps do {

            halo_update_driver(chunk_var, setting_var, 1);

            ppcg_inner_iteration(setting_var.halo_depth, chunk_var.cheby_alphas[pp], chunk_var.cheby_betas[pp], 
                                chunk_var.u, chunk_var.r, chunk_var.sd, chunk_var.kx, chunk_var.ky);
        }

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_P] = true;

    }
}
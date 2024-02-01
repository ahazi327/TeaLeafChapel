module cheby_driver{
    use eigenvalue_driver;
    use chunks;
    use profile;
    use settings;
    use local_halos;
    use cg_driver;
    use solver_methods;
    use cheby;
    use Math;
    param epsilon = 1e-16; // some really small positive number

    proc cheby_driver(ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rx: real,
                        ref ry: real, ref error: real, ref interation_count : int, 
                        ref interation_count_prime : int, ref inner_steps : int){

        var est_iterations, is_switch_to_cheby, num_cheby_iters: int;
        var rro: real;

        // Perform CG initialisation
        cg_init_driver(chunk_var, setting_var, rx, ry, rro);
        
        var tt_prime, tt_eig : int;
        var half1, half2 : bool;
        // Iterate till convergence
        for tt in 0..<setting_var.max_iters do {
            // If we have already ran cheby iterations, continue
            // If we are error switching, check the error
            // If not error switching, perform preset iterations
            // Perform enough iterations to converge eigenvalues
            
            if (num_cheby_iters > 0) {
                half2 = true;
            }else half2 = false;
            
            if (setting_var.error_switch) {
                half1 = (error < setting_var.eps_lim) && (tt > CG_ITERS_FOR_EIGENVALUES);
            } else {
                half1 = (tt > setting_var.presteps) && (error < ERROR_SWITCH_MAX);
            }
            is_switch_to_cheby = half1 || half2;

            // Perform a CG iteration
            if(!is_switch_to_cheby) then cg_main_step_driver(chunk_var, setting_var, tt, rro, error); 
            else {
                num_cheby_iters += 1;
                // Check if first step
                if num_cheby_iters == 1{
                    // Initialise the solver
                    var bb: real;
                    cheby_init_driver(chunk_var, setting_var, tt, bb);
                    
                    // Perform the main step
                    cheby_main_step_driver(chunk_var, setting_var, num_cheby_iters, true, error);

                    // Estimate the number of Chebyshev iterations
                    cheby_calc_est_iterations(chunk_var, error, bb, est_iterations);
                }
                else {
                    var is_calc_2norm: bool = (num_cheby_iters >= est_iterations) && ((tt + 1) % 10 == 0);

                    // Perform main step
                    cheby_main_step_driver(chunk_var, setting_var, num_cheby_iters, is_calc_2norm, error);
                    
                }
            }
            
            halo_update_driver(chunk_var, setting_var, 1);
            if(abs(error) < setting_var.eps) then break;
            tt_prime += 1;
        }
        interation_count = tt_prime-num_cheby_iters+1;
        interation_count_prime = num_cheby_iters;
        inner_steps = est_iterations;
        writeln("CG iterations : ", tt_prime-num_cheby_iters+1);
        writeln("Cheby iterations : ", num_cheby_iters, " (", est_iterations, " estimated)");
    }

    proc cheby_init_driver(ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, 
                            const in num_cg_iters: int, ref bb: real){

        eigenvalue_driver_initialise(chunk_var, setting_var, num_cg_iters);
        cheby_coef_driver(chunk_var, setting_var.max_iters - num_cg_iters);

        // chunks per rank loop
        calculate_2norm(setting_var.halo_depth, chunk_var.u, bb);

        cheby_init(setting_var.halo_depth, chunk_var.theta, chunk_var.u, chunk_var.u0,
                    chunk_var.p, chunk_var.r, chunk_var.w, chunk_var.kx, chunk_var.ky);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
        halo_update_driver(chunk_var, setting_var, 1);

    }

    // Performs the main iteration step
    proc cheby_main_step_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, 
                                const in num_cheby_iters: int, const in is_calc_2norm: bool, ref error: real){
        // chunks per rank loop
        cheby_iterate (setting_var.halo_depth, chunk_var.cheby_alphas[num_cheby_iters],
                       chunk_var.cheby_betas[num_cheby_iters], chunk_var.u, chunk_var.u0,
                       chunk_var.p, chunk_var.r, chunk_var.w, chunk_var.kx, chunk_var.ky);

        if is_calc_2norm then
        {
            error = 0.0;
            calculate_2norm(setting_var.halo_depth, chunk_var.r, error);
        }

    }

    // Calculates the estimated iterations for Chebyshev solver
    proc cheby_calc_est_iterations (const ref chunk_var : chunks.Chunk, const in error: real, const in bb: real, 
                                    ref est_iterations: int){ 

         // Condition number is identical in all chunks/ranks
        const condition_number: real = chunk_var.eigmax / chunk_var.eigmin;

        // Calculate estimated iteration count
        const it_alpha : real = epsilon*bb / (4.0*error);

        const gamm : real = 
            (sqrt(condition_number) - 1.0) / 
            (sqrt(condition_number) + 1.0);

        est_iterations = round(log(it_alpha) / (2.0*log(gamm))) : int;
        
    }

    // Calculates the Chebyshev coefficients for the chunk
    proc cheby_coef_driver (ref chunk_var : chunks.Chunk, const in max_iters: int){
        chunk_var.theta = (chunk_var.eigmax + chunk_var.eigmin) / 2.0;
        const delta : real = (chunk_var.eigmax - chunk_var.eigmin) / 2.0;
        const sigma : real = chunk_var.theta / delta;
        var rho_old : real = 1.0 / sigma;

        for ii in 0..<max_iters do{
            const rho_new : real = 1.0 / (2.0*sigma - rho_old);
            const cur_alpha : real = rho_new*rho_old;
            const cur_beta : real = 2.0*rho_new / delta;
            chunk_var.cheby_alphas[ii] = cur_alpha;
            chunk_var.cheby_betas[ii] = cur_beta;
            rho_old = rho_new;
        }
    }

}
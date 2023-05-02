module cheby_driver{
    use eigenvalue_driver;
    use chunks;
    use settings;
    use local_halos;
    use cg_driver;
    use solver_methods;
    import cheby;
    param epsilon = 0.00001; // some really small positive number

    proc cheby_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, ref error: real){

        var tt, est_iterations, num_cheby_iters: int;
        var rro: real;
        var is_switch_to_cheby : int;

        // Perform CG initialisation
        cg_init_driver(chunk_var, setting_var, rx, ry, rro);
        
        var tt_prime : int;
        // Iterate till convergence
        for tt in 0..<setting_var.max_iters do {
            
            // If we have already ran cheby iterations, continue
            // If we are error switching, check the error
            // If not error switching, perform preset iterations
            // Perform enough iterations to converge eigenvalues
            if error < setting_var.eps_lim && tt > CG_ITERS_FOR_EIGENVALUES then 
                is_switch_to_cheby = num_cheby_iters;
            else if tt > setting_var.presteps && error < ERROR_SWITCH_MAX then
                is_switch_to_cheby = setting_var.error_switch;
            
            if(!is_switch_to_cheby) then
                // Perform a CG iteration
                cg_main_step_driver(chunk_var, setting_var, tt, rro, error);
            else num_cheby_iters += 1;

            // Check if first step
            if num_cheby_iters == 1{
                // Initialise the solver
                var bb: real = 0.0;
                cheby_init_driver(chunk_var, setting_var, tt, bb);

                // Perform the main step
                cheby_main_step_driver(chunk_var, setting_var, num_cheby_iters, true, error);

                // Estimate the number of Chebyshev iterations
                cheby_calc_est_iterations(chunk_var, error, bb, est_iterations);
            }
            else {
                var is_calc_2norm: bool = (num_cheby_iters >= est_iterations) && ((tt+1) % 10 == 0);

                // Perform main step
                cheby_main_step_driver(chunk_var, setting_var, num_cheby_iters, is_calc_2norm, error);
            }
            
            halo_update_driver(chunk_var, setting_var, 1);
            if(abs(error) < setting_var.eps) then break;
            tt_prime += 1;
        }
        // print_and_log(settings, "CG: \t\t\t%d iterations\n", tt-num_cheby_iters+1);
        // print_and_log(settings, 
        //     "Cheby: \t\t\t%d iterations (%d estimated)\n", 
        //     num_cheby_iters, est_iterations);
        writeln("CG iterations : ", tt_prime-num_cheby_iters+1);
        writeln("Cheby iterations : ", tt_prime, " (", est_iterations, " estimated)\n");
    }

    proc cheby_init_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in num_cg_iters: int,
    out bb: real){

        var bb: real = 0.0;
        eigenvalue_driver_initialise(chunk_var, setting_var, num_cg_iters);
        // cheby_coef_driver(chunks, settings, settings->max_iters-num_cg_iters);   //TODO un comment this later

        // chunks per rank loop
        calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].u, bb);

        cheby.cheby_init(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].theta, chunk_var[0].u, chunk_var[0].u0,
        chunk_var[0].p, chunk_var[0].r, chunk_var[0].w, chunk_var[0].kx, chunk_var[0].ky);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
        halo_update_driver(chunk_var, setting_var, 1);

        //sum over ranks
    }

    // Performs the main iteration step
    proc cheby_main_step_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in num_cheby_iters: int,
    in is_calc_2norm: bool, out error: real){
        // chunks per rank loop
        cheby.cheby_iterate (chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].cheby_alphas[num_cheby_iters],
        chunk_var[0].cheby_betas[num_cheby_iters], chunk_var[0].u, chunk_var[0].u0,
        chunk_var[0].p, chunk_var[0].r, chunk_var[0].w, chunk_var[0].kx, chunk_var[0].ky);

        if is_calc_2norm then
        {
            var error: real = 0.0;

            calculate_2norm(chunk_var[0].x, chunk_var[0].y, setting_var.halo_depth, chunk_var[0].r, error);
        }
    }

    // Calculates the estimated iterations for Chebyshev solver
    proc cheby_calc_est_iterations (ref chunk_var : [?chunk_domain] chunks.Chunk, in error: real, in bb: real, ref est_iterations: int){ 

         // Condition number is identical in all chunks/ranks
        var condition_number: real = chunk_var[0].eigmax / chunk_var[0].eigmin;

        // Calculate estimated iteration count
        var it_alpha : real = epsilon*bb / (4.0*error);

        var gamm : real = 
            (sqrt(condition_number) - 1.0) / 
            (sqrt(condition_number) + 1.0);

        est_iterations = round(log(it_alpha) / (2.0*log(gamm))) : int;
    }

    // Calculates the Chebyshev coefficients for the chunk
    proc cheby_coef_driver (ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in max_iters: int){
        chunk_var[0].theta = (chunk_var[0].eigmax + chunk_var[0].eigmin) / 2.0;
        var delta : real = (chunk_var[0].eigmax - chunk_var[0].eigmin) / 2.0;
        var sigma : real = chunk_var[0].theta / delta;
        var rho_old : real = 1.0 / sigma;

        for ii in 0..<max_iters do{
            var rho_new : real = 1.0 / (2.0*sigma - rho_old);
            var cur_alpha : real = rho_new*rho_old;
            var cur_beta : real = 2.0*rho_new / delta;
            chunk_var[0].cheby_alphas[ii] = cur_alpha;
            chunk_var[0].cheby_betas[ii] = cur_beta;
            rho_old = rho_new;
        }
    }

}
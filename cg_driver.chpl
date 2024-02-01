module cg_driver {
    use cg;
    use settings;
    use chunks;
    use local_halos;
    use solver_methods;
    use profile;

    // Performs a full solve with the CG solver kernels
    proc cg_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rx: real,
                    ref ry: real, ref error: real, ref interation_count : int){
        //var tt: int;
        var rro : real;
        var t : int;

        // Perform CG initialisation
        cg_init_driver(chunk_var, setting_var, rx, ry, rro);

        var tt_prime : int;
        // Iterate till convergence
        for tt in 0..<setting_var.max_iters do {
            
            cg_main_step_driver(chunk_var, setting_var, tt, rro, error);

            halo_update_driver (chunk_var, setting_var, 1);

            if (sqrt(abs(error)) < setting_var.eps) then break;

            tt_prime += 1;
        }
        interation_count = tt_prime;
        writeln("CG iterations : ", tt_prime);
    }

    // Invokes the CG initialisation kernels
    proc cg_init_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rx: real,
                        ref ry: real, ref rro: real) {
        rro = 0.0;

        cg_init(chunk_var.x, chunk_var.y, setting_var.halo_depth, setting_var.coefficient, rx, ry, rro, chunk_var.density, 
                chunk_var.energy, chunk_var.u, chunk_var.p, chunk_var.r, chunk_var.w, chunk_var.kx, chunk_var.ky, chunk_var.temp);

        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
        setting_var.fields_to_exchange[FIELD_P] = true;
        halo_update_driver(chunk_var, setting_var, 1);

        copy_u(setting_var.halo_depth, chunk_var.u, chunk_var.u0);
    }

    // Invokes the main CG solve kernels
    proc cg_main_step_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, in tt : int,
                                ref rro: real, ref error: real){
        var pw: real;
        
        cg_calc_w (setting_var.halo_depth, pw, chunk_var.p, chunk_var.w, chunk_var.kx, chunk_var.ky, chunk_var.temp);

        var alpha : real = rro / pw;
        
        var rrn: real;
    
        chunk_var.cg_alphas[tt] = alpha;

        cg_calc_ur(setting_var.halo_depth, alpha, rrn, chunk_var.u, chunk_var.p, chunk_var.r, chunk_var.w, chunk_var.temp);

        var beta : real = rrn / rro;
        
        chunk_var.cg_betas[tt] = beta;
        cg_calc_p (setting_var.halo_depth, beta, chunk_var.p, chunk_var.r);
        error = rrn;
        rro = rrn;
        
    }

}
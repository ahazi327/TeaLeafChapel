module jacobi_driver {
    use chunks;
    use settings;
    use local_halos;
    use solver_methods;
    use jacobi;
    use profile;

    // Performs a full solve with the Jacobi solver kernels
    proc jacobi_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, ref rx: real,
    ref ry: real, ref err: real){

        var Domain : domain(2) = {0..<chunk_var.y, 0..<chunk_var.x};
        jacobi_init_driver(chunk_var, setting_var, rx, ry);
        // Iterate until convergence
        var tt_prime : int;
        
        for tt in 0..<setting_var.max_iters do {
            jacobi_main_step_driver(chunk_var, setting_var, tt, err);

            halo_update_driver(chunk_var, setting_var, 1);
            if(abs(err) < setting_var.eps) then break;
            tt_prime += 1;
        }
        writeln("Jacobi iterations : ", tt_prime);
    }

    // Invokes the CG initialisation kernels
    proc jacobi_init_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const in rx: real,
    const in ry: real){

        jacobi_init(chunk_var.x, chunk_var.y, setting_var.halo_depth, setting_var.coefficient, rx, ry,
            chunk_var.u, chunk_var.u0, chunk_var.energy, chunk_var.density, chunk_var.kx, chunk_var.ky);
        
        if useStencilDist {
            profiler.startTimer("comms");
            chunk_var.u.updateFluff();
            chunk_var.u0.updateFluff();
            chunk_var.kx.updateFluff();
            chunk_var.ky.updateFluff();
            profiler.stopTimer("comms");
        }

        copy_u(chunk_var.x, chunk_var.y, setting_var.halo_depth, chunk_var.u, chunk_var.u0);
        if useStencilDist {
            profiler.startTimer("comms");
            chunk_var.u0.updateFluff();
            profiler.stopTimer("comms");
        } 

        // Need to update for the matvec
        reset_fields_to_exchange(setting_var);
        setting_var.fields_to_exchange[FIELD_U] = true;
    }

    // Invokes the main Jacobi solve kernels
    proc jacobi_main_step_driver (ref chunk_var : chunks.Chunk, ref setting_var : settings.setting, const in tt: int,
    ref err: real){
        jacobi_iterate(chunk_var.x, chunk_var.y, setting_var.halo_depth, chunk_var.u, chunk_var.u0, 
            chunk_var.r, err, chunk_var.kx, chunk_var.ky);

        if useStencilDist {
            profiler.startTimer("comms");
            chunk_var.u.updateFluff();
            profiler.stopTimer("comms");
        } 

        if tt % 50 == 0 {
            halo_update_driver(chunk_var, setting_var, 1);

            calculate_residual(chunk_var.x, chunk_var.y, setting_var.halo_depth, chunk_var.u, chunk_var.u0, chunk_var.r,
                chunk_var.kx, chunk_var.ky);
            if useStencilDist {
                profiler.startTimer("comms");
                chunk_var.r.updateFluff();
                profiler.stopTimer("comms");
            } 
            calculate_2norm(chunk_var.x, chunk_var.y, setting_var.halo_depth, chunk_var.r, err);
        }
    }

}
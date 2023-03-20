module cheby_driver{
    use eigenvalue_driver;
    use chunks;
    use settings;
    
    proc cheby_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, inout rx: real,
    inout ry: real, out error: real){

        var tt, est_iterations, num_cheby_iters: int;
        var rro: real;

        // Perform CG initialisation
        cg_init_driver
    }

    proc cg_init_driver(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in num_cg_iters: int,
    out bb: real){

    }


}
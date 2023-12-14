/*
 *		CONJUGATE GRADIENT SOLVER KERNEL
 */
module cg {
    use settings;
    use Math;
    use profile;
    use chunks;
    proc cg_init(const ref x: int, const ref y : int, const ref halo_depth: int, const in coefficient: int, in rx: real, 
                in ry: real, ref rro: real,  ref density: [?Domain] real,  ref energy: [Domain] real,
                ref u: [Domain] real,  ref p: [Domain] real,  ref r: [Domain] real,  ref w: [Domain] real,  
                ref kx: [Domain] real, ref ky: [Domain] real){

        profiler.startTimer("cg_init");
        if coefficient != CONDUCTIVITY && coefficient != RECIP_CONDUCTIVITY
        {
            writeln("Coefficient ", coefficient, " is not valid.\n");
            profiler.stopTimer("cg_init");
            exit(-1);
        }

        forall ij in Domain {
            p[ij] = 0;
            r[ij] = 0;
            u[ij] = energy[ij] *density[ij];
        }
        
        forall (i, j) in Domain.expand(-1)  do {
            if (coefficient == CONDUCTIVITY) then
                w[i,j] = density[i,j];
            else  
                w[i,j] = 1.0/density[i,j];
            
        }

        if useStencilDist {
            profiler.startTimer("comms");
            w.updateFluff();
            profiler.stopTimer("comms");
        }

        const inner_1 = Domain[halo_depth..<y-1, halo_depth..<x-1];
        if useStencilDist {
            forall (i, j) in inner_1 do {
                kx[i, j] = rx*(w[i-1, j]+w[i, j]) / (2.0*w[i-1, j]*w[i, j]);
                ky[i, j] = ry*(w[i, j-1]+w[i, j]) / (2.0*w[i, j-1]*w[i, j]);
            }
        } else {
            forall (i, j) in inner_1 do {
                kx[i, j] = rx*(w[i-1, j]+w[i, j]) / (2.0*w[i-1, j]*w[i, j]);
                ky[i, j] = ry*(w[i, j-1]+w[i, j]) / (2.0*w[i, j-1]*w[i, j]);
            }   
        }
        

        if useStencilDist {
            profiler.startTimer("comms");
            kx.updateFluff();
            ky.updateFluff();
            u.updateFluff();
            profiler.stopTimer("comms");
        }
        
        var rro_temp : real; 
        if useStencilDist {
            forall (i, j) in Domain.expand(-halo_depth)  with (+ reduce rro_temp) do {
                const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                    + (ky[i, j+1]+ky[i, j]))*u[i, j]
                    - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                    - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
                w[i, j] = smvp;
                r[i,j] = u[i,j] - smvp;
                p[i,j] = r[i,j];
                rro_temp += p[i,j]**2;   
            }
        } else {
            forall (i, j) in Domain.expand(-halo_depth)  with (+ reduce rro_temp) do {
                const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                    + (ky[i, j+1]+ky[i, j]))*u[i, j]
                    - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                    - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
                w[i, j] = smvp;
                r[i,j] = u[i,j] - smvp;
                p[i,j] = r[i,j];
                rro_temp += p[i,j]**2;   
            }   
        }
        
        
        rro += rro_temp;
        profiler.stopTimer("cg_init");
    }

    // Calculates w
    proc cg_calc_w (const in halo_depth: int, ref pw: real, const ref p: [?Domain] real, 
                    ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real){

        profiler.startTimer("cg_calc_w");
        var pw_temp : real;
        if useStencilDist {
            forall (i, j) in Domain.expand(-halo_depth)  with (+ reduce pw_temp) do{
                const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                    + (ky[i, j+1]+ky[i, j]))*p[i, j]
                    - (kx[i+1, j]*p[i+1, j]+kx[i, j]*p[i-1, j])
                    - (ky[i, j+1]*p[i, j+1]+ky[i, j]*p[i, j-1]);
                w[i,j] = smvp;
                pw_temp += smvp * p[i, j]; 
             }
        } else {
            forall (i, j) in Domain.expand(-halo_depth)  with (+ reduce pw_temp) do{
                const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                    + (ky[i, j+1]+ky[i, j]))*p[i, j]
                    - (kx[i+1, j]*p[i+1, j]+kx[i, j]*p[i-1, j])
                    - (ky[i, j+1]*p[i, j+1]+ky[i, j]*p[i, j-1]);
                w[i,j] = smvp;
                pw_temp += smvp * p[i, j]; 
             }   
        }
        
        pw += pw_temp;
        profiler.stopTimer("cg_calc_w");
    }
    
    // Calculates u and r
    proc cg_calc_ur(const in halo_depth: int, const in alpha: real, ref rrn: real, 
                    ref u: [?Domain] real, const ref p: [Domain] real, 
                    ref r: [Domain] real, const ref w: [Domain] real){
        profiler.startTimer("cg_calc_ur");

        var rrn_temp : real;
        forall (i, j) in Domain.expand(-halo_depth)  with (+ reduce rrn_temp) do{
            u[i, j] += alpha * p[i, j];
            r[i, j] -= alpha * w[i, j];
            
            const temp: real = r[i, j];
            rrn_temp += temp ** 2;
        }
        rrn += rrn_temp;
        profiler.stopTimer("cg_calc_ur");
    }

    // Calculates p
    proc cg_calc_p (const ref halo_depth: int, const in beta: real, ref p: [?Domain] real, 
                    const ref r: [Domain] real) {
        profiler.startTimer("cg_calc_p");
        
        [ij in Domain.expand(-halo_depth)] p[ij] = beta * p[ij] + r[ij];

        profiler.stopTimer("cg_calc_p");
    }

}
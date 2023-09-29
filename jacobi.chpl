/*
 *		JACOBI SOLVER KERNEL
 */
module jacobi{
    use settings;
    use chunks;
    use Math;
    use profile;

    // Initialises the Jacobi solver
    proc jacobi_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: real, 
                    const in rx: real, const in ry: real, ref u: [?Domain] real, ref u0: [Domain] real, 
                    const ref energy: [Domain] real, const ref density: [Domain] real, ref kx: [Domain] real, 
                    ref ky: [Domain] real){
        
        profiler.startTimer("jacobi_init");

        const inner_Domain = {1..<y-1, 1..<x-1};
        const Inner = {halo_depth..<y - 1, halo_depth..<x - 1};

        if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY
        {
            writeln("Coefficient ", coefficient, " is not valid.\n");
            profiler.stopTimer("jacobi_init");
            exit(-1);
        }

        forall (i, j) in Inner do{ 
            const temp : real = energy[i, j] * density[i, j];
            u[i, j] = temp;

            var densityCentre: real;
            var densityLeft: real;
            var densityDown: real;

            if coefficient == CONDUCTIVITY {  
                densityCentre = density[i, j];
                densityLeft = density[i, j-1];
                densityDown = density[i-1, j ];
            }
            else {
                densityCentre = 1.0/density[i, j];
                densityLeft =  1.0/density[i, j - 1];
                densityDown = 1.0/density[i - 1, j];
            }

            kx[i, j] = rx*(densityLeft+densityCentre)/(2.0*densityLeft*densityCentre);
            ky[i, j] = ry*(densityDown+densityCentre)/(2.0*densityDown*densityCentre);
        }


        profiler.stopTimer("jacobi_init");
    }

    // The main Jacobi solve step
    proc jacobi_iterate(const in halo_depth: int, ref u: [?Domain] real, const ref u0: [Domain] real, 
                        ref r: [Domain] real, ref error: real, const ref kx: [Domain] real, 
                        const ref ky: [Domain] real){
        profiler.startTimer("jacobi_iterate");

        forall j in Domain.dim(1){
            for i in Domain.dim(0){
                r[i, j] = u[i, j];
            }
        }

        if useStencilDist {
            profiler.startTimer("comms");
            r.updateFluff();
            profiler.stopTimer("comms");
        } 
        
        var err: real = 0.0;
        forall j in Domain.expand(-halo_depth).dim(1) with (+ reduce err) {
            for i in Domain.expand(-halo_depth).dim(0) {
                u[i, j] = (u0[i,j] 
                        + kx[i, j + 1] * r[i, j + 1] 
                        + kx[i, j] * r[i, j - 1]
                        + ky[i + 1, j] * r[i + 1, j ] 
                        + ky[i, j] * r[i - 1, j])
                    / (1.0 + kx[i, j] + kx[i, j+1] 
                        + ky[i, j] + ky[i + 1, j]);
                err += abs(u[i, j] - r[i, j]);
            }
        }
        error = err;
        profiler.stopTimer("jacobi_iterate");
    }

    
}


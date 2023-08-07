/*
 *		JACOBI SOLVER KERNEL
 */
module jacobi{
    use settings;
    use chunks;
    use Math;
    use profile;

    // Initialises the Jacobi solver
    proc jacobi_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: real, const in rx: real, const in ry: real, 
    ref u: [?DDomain] real, ref u0: [?Domain] real, const ref energy: [Domain] real, const ref density: [Domain] real,
    ref kx: [Domain] real, ref ky: [Domain] real){
        
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
            u0[i, j] = temp;
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
    proc jacobi_iterate(const in x: int, const in y: int, const in halo_depth: int, 
    ref u: [?DDomain] real, const ref u0: [?Domain] real, ref r: [Domain] real, ref error: real,
    const ref kx: [Domain] real, const ref ky: [Domain] real){
        profiler.startTimer("jacobi_iterate");
        
        forall ij in r.domain{
            r[ij] = u[ij];
        }
        
        
        
        // u0.updateFluff();
        // r.updateFluff();
        if useStencilDist then r.updateFluff();
        // r.updateFluff();
        // kx.updateFluff();
        // ky.updateFluff();
        // writeln("r before: \n", r);
        
        const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1);
        // TODO find out why ghost cells give nan results
        var err: real = 0.0;
        forall ij in {halo_depth..<y-halo_depth-1, halo_depth..<(x - halo_depth-1)} with (+ reduce err) {
            const temp : real = (u0[ij] + ((kx[ij + east]*r[ij + east] + (kx[ij]*r[ij + west])))
                + ((ky[ij + north]*r[ij + north] + ky[ij]*r[ij + south])))
            / (1.0 + ((kx[ij]+kx[ij + east]))
                    + ((ky[ij]+ky[ij + north])));

            u[ij] = temp;
            // u.updateFluff();
            // writeln("error calc u, r, err =", u[ij], " , ", r[ij]," , " ,err, " at coordinates :", ij);
            err += abs(temp - r[ij]);
        }
        // writeln("r after : \n", r);
        // writeln("u fluff, ", u[-1,1]);

        // u0.updateFluff();
        // r.updateFluff();
        // u.updateFluff();
        // kx.updateFluff();
        // ky.updateFluff();
        
        error = err;
        
        profiler.stopTimer("jacobi_iterate");
    }

    
}


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
    ref u: [?Domain] real, ref u0: [Domain] real, ref energy: [Domain] real, ref density: [Domain] real,
    ref kx: [Domain] real, ref ky: [Domain] real){
        
        const inner_Domain = Domain[1..<y-1, 1..<x-1];
        const Inner = Domain[halo_depth..<y - 1, halo_depth..<x - 1];

        profiler.startTimer("jacobi_init");

        if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY
        {
            writeln("Coefficient ", coefficient, " is not valid.\n");
            profiler.stopTimer("jacobi_init");
            exit(-1);
        }

        
        // u0[inner_Domain] = energy[inner_Domain] * density[inner_Domain];
        // u[inner_Domain] = u0[inner_Domain];

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
    ref u: [Domain] real, ref u0: [Domain] real, ref r: [Domain] real, ref error: real,
    ref kx: [Domain] real, ref ky: [Domain] real, const in Domain : domain(2) ){
        // TODO check which orientation i should keep the arrays for cache improvements 
        profiler.startTimer("jacobi_iterate");
        const outer_Domain = Domain[0..<y, 0..<x];
        const Inner = Domain[halo_depth..<(y - halo_depth), halo_depth..<(x - halo_depth)];
        
        const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1);

        r[outer_Domain] = u[outer_Domain];
        // writeln("here");
        var err: real;

        forall ij in Inner with (+ reduce err) {

            const temp : real = (u0[ij] + ((kx[ij + east]*r[ij + east] + (kx[ij]*r[ij + west])))
                + ((ky[ij + north]*r[ij + north] + ky[ij]*r[ij + south])))
            / (1.0 + ((kx[ij]+kx[ij + east]))
                    + ((ky[ij]+ky[ij + north])));

            u[ij] = temp;
            err += abs(r[ij]-temp);
        }

        error = err;
        profiler.stopTimer("jacobi_iterate");
    }

    
}


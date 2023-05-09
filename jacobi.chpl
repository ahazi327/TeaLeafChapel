/*
 *		JACOBI SOLVER KERNEL
 */
module jacobi{
    use settings;
    use chunks;
    use Math;

    // Initialises the Jacobi solver
    proc jacobi_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: real, ref rx: real, ref ry: real, 
    ref u: [?Domain] real, ref u0: [Domain] real, ref energy: [Domain] real, ref density: [Domain] real,
    ref kx: [Domain] real, ref ky: [Domain] real){
        
        const inner_Domain = Domain[1..<y-1, 1..<x-1];
        const Inner = Domain[halo_depth..<y - 1, halo_depth..<x - 1];

        if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY
        {
            writeln("Coefficient ", coefficient, " is not valid.\n");
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
    }

    // The main Jacobi solve step
    proc jacobi_iterate(const in x: int, const in y: int, const in halo_depth: int, 
    ref u: [?Domain] real, ref u0: [Domain] real, ref r: [Domain] real, ref error: real,
    ref kx: [Domain] real, ref ky: [Domain] real, ref rx: real, ref ry: real){
        // TODO check which orientation i should keep the arrays for cache improvements 

        const outer_Domain = Domain[0..<y, 0..<x];
        const Inner = Domain[halo_depth..<(y - halo_depth), halo_depth..<(x - halo_depth)];
        
        const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1);

        r[outer_Domain] = u[outer_Domain];
        // writeln("here");
        var err: real;

        forall ij in Inner with (+ reduce err) {
        // for  ij in Inner/10 {
            
            // r[ij] = u[ij];


            u[ij] = (u0[ij] + ((kx[ij + east]*r[ij + east] + (kx[ij]*r[ij + west])))
                + ((ky[ij + north]*r[ij + north] + ky[ij]*r[ij + south])))
            / (1.0 + ((kx[ij]+kx[ij + east]))
                    + ((ky[ij]+ky[ij + north])));
            // u[i, j] = (u0[i, j] + ((kx[i, j+1]*r[i, j+1] + (kx[i, j]*r[i, j-1])))
            //     + ((ky[i+1, j]*r[i+1, j] + ky[i, j]*r[i-1, j])))
            //     / (1.0 + ((kx[i, j]+kx[i, j+1]))
            //     + ((ky[i, j]+ky[i+1, j])));

            // err += abs(r[ij]-u[ij]);
        }

        // u[Inner] = (u0[Inner] + ((kx[Inner_j_plus]*r[Inner_j_plus] + (kx[Inner]*r[Inner_j_minus])))
        //     + ((ky[Inner_i_plus]*r[Inner_i_plus] + ky[Inner]*r[Inner_i_minus])))
        // / (1.0 + ((kx[Inner]+kx[Inner_j_plus]))
        //         + ((ky[Inner]+ky[Inner_i_plus])));

        // forall (i, j) in Inner  with (+ reduce err) do {
        //     err += abs(r[i, j]-u[i, j]);
        // }
        err += + reduce abs(r[Inner]-u[Inner]);
        error = err;
    }
}


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

        var temp : real;
        for i in inner_Domain do {
            temp = energy[i] * density[i];
            u0[i] = temp;
            u[i] = temp;
        }

        forall (i, j) in Inner do{ 
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
    ref kx: [Domain] real, ref ky: [Domain] real, ref rx: real, ref ry: real, ref chunk_var: chunks.Chunk){

        const outer_Domain = Domain[0..<y, 0..<x];
        const Inner = Domain[halo_depth..<(y - halo_depth), halo_depth..<(x - halo_depth)];

        // r[outer_Domain] = u[outer_Domain];

        for i in outer_Domain do {
            r[i] = u[i];
        }

        var err: real;

        forall (i, j) in Inner  with (+ reduce err) do {    
            u[i, j] = (u0[i, j] + ((kx[i, j+1]*r[i, j+1] + (kx[i, j]*r[i, j-1])))
                + ((ky[i+1, j]*r[i+1, j] + ky[i, j]*r[i-1, j])))
            / (1.0 + ((kx[i, j]+kx[i, j+1]))
                    + ((ky[i, j]+ky[i+1, j])));

            err += abs(r[i, j]-u[i, j]);
        }
        error = err;
    }
}


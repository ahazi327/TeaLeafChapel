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
        
        u0[inner_Domain] = energy[inner_Domain] * density[inner_Domain];
        u[inner_Domain] = u0[inner_Domain];

        // var temp : real;
        // for i in inner_Domain do {
        //     temp = energy[i] * density[i];
        //     u0[i] = temp;
        //     u[i] = temp;
        // }

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
    ref kx: [Domain] real, ref ky: [Domain] real, ref rx: real, ref ry: real){

        const outer_Domain = Domain[0..<y, 0..<x];
        const Inner = Domain[halo_depth..<(y - halo_depth), halo_depth..<(x - halo_depth)];

        const Inner_i_minus = Inner[halo_depth-1..<(y - halo_depth)-1, halo_depth..<(x - halo_depth)];
        const Inner_i_plus = Inner[halo_depth+1..<(y - halo_depth)+1, halo_depth..<(x - halo_depth)];
        const Inner_j_plus = Inner[halo_depth..<(y - halo_depth), halo_depth+1..<(x - halo_depth)+1];
        const Inner_j_minus = Inner[halo_depth..<(y - halo_depth), halo_depth-1..<(x - halo_depth)-1];

        // TODO check which orientation i should keep the arrays for cache improvements 
        r[outer_Domain] = u[outer_Domain];

        // for i in outer_Domain do {
        //     r[i] = u[i] + 1;
        //     r[i] -= 1;
        // }

        var err: real;

        // forall (i, j) in Inner  with (+ reduce err) do {    
        u[Inner] = (u0[Inner] + ((kx[Inner_j_plus]*r[Inner_j_plus] + (kx[Inner]*r[Inner_j_minus])))
            + ((ky[Inner_i_plus]*r[Inner_i_plus] + ky[Inner]*r[Inner_i_minus])))
        / (1.0 + ((kx[Inner]+kx[Inner_j_plus]))
                + ((ky[Inner]+ky[Inner_i_plus])));

        forall (i, j) in Inner  with (+ reduce err) do {
            err += abs(r[i, j]-u[i, j]);
        // const err = max reduce abs(r[Inner]-u[Inner]);
        }
        error = err;
    }
}


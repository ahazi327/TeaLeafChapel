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

        if(coefficient < CONDUCTIVITY && coefficient < RECIP_CONDUCTIVITY)
        {
            // die(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient);
            return;
        }
        
        const inner_Domain = Domain[1..<y-1, 1..<x-1];
        const Inner = Domain[halo_depth..<y - 1, halo_depth..<x - 1];

        // if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY do //TODO reference CONDUCTIVITY
        
        //     // die(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient); // die is an int but from where?
        //     writeln(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient)
        
        u0[inner_Domain] = energy[inner_Domain] * density[inner_Domain];
        u[inner_Domain] = u0[inner_Domain];

        // writeln("u innit array: \n", u0);


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
        // writeln ("kx : \n", kx[Inner]);
    }

    // The main Jacobi solve step
    proc jacobi_iterate(const in x: int, const in y: int, const in halo_depth: int, 
    ref u: [?Domain] real, ref u0: [Domain] real, ref r: [Domain] real, ref error: real,
    ref kx: [Domain] real, ref ky: [Domain] real, ref rx: real, ref ry: real, ref chunk_var: chunks.Chunk){

        const outer_Domain = Domain[0..<y, 0..<x];
        const Inner = Domain[halo_depth..<(y - halo_depth), halo_depth..<(x - halo_depth)];

        r[outer_Domain] = u[outer_Domain];
        // r = u;

        var err: real = 0.00000000;

        forall (i, j) in Inner  with (+ reduce err) do {    
            u[i, j] = (u0[i, j] + ((kx[i, j+1]*r[i, j+1] + (kx[i, j]*r[i, j-1])))
                + ((ky[i+1, j]*r[i+1, j] + ky[i, j]*r[i-1, j])))
            / (1.0 + ((kx[i, j]+kx[i, j+1]))
                    + ((ky[i, j]+ky[i+1, j])));

            err += abs(r[i, j]-u[i, j]);
            // err = abs(err - 1.0e-15)/ 1.0e-15;
            // err = err/1000;
            
            

        }
        // err= err/(512*512);
        // var inner = Domain[halo_depth..<y-halo_depth, halo_depth..<x-halo_depth];

        // var vol, ie, temp, mass : real = 0.0;

        // for j in {halo_depth..<x-halo_depth} do { // TODO maybe make this into a forall loop
        //     for i in {halo_depth..<y-halo_depth} do {
        //         var cellVol : real;
        //         cellVol = chunk_var.volume[i, j];

        //         var cellMass: real;
        //         cellMass = cellVol * chunk_var.density[i, j];

        //         vol += cellVol;
        //         mass += cellMass;
        //         ie += cellMass * chunk_var.energy0[i, j];
        //         temp += cellMass * u[i, j];
                                
        //     }
        // }
        

        // temp = abs(temp - 1.034697091898282e02)/ 1.034697091898282e02;

        // writeln("Checking Value : ", temp);

        // if temp < 1e-15 then err = 0;
        
        // writeln(" jacobi iteration error : ", err);
        error = err;
    }
}


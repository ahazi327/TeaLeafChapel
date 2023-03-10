/*
 *		JACOBI SOLVER KERNEL
 */
module jacobi{
    use settings;
    use chunks;

    // Initialises the Jacobi solver
    proc jacobi_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: real, inout rx: real, inout ry: real, 
    ref u: [?u_domain] real, ref u0: [?u0_domain] real, ref energy: [?energy_domain] real, ref density: [?density_domain] real,
    ref kx: [?kx_domain] real, ref ky: [?ky_domain] real){
        
        const Domain = {1..<x-1, 1..<y-1};
        const Inner = {halo_depth..<x - 1, halo_depth..<y - 1};

        // if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY do //TODO reference CONDUCTIVITY
        
        //     // die(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient); // die is an int but from where?
        //     writeln(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient)
        

        forall (i, j) in Domain do{
            u0[i, j] = energy[i, j]*density[i, j];
            u[i, j] = energy[i, j]*density[i, j];
        }   


        forall (i, j) in Inner do{ 
            var densityCentre: real;
            var densityLeft: real;
            var densityDown: real;

            if coefficient == settings.CONDUCTIVITY {  
                densityCentre = density[i, j];  // come back later when chunk data structure is sorted out
                densityLeft = density[i - 1, j];
                densityDown = density[i, j - 1];
            }
            else {
                densityCentre = 1.0/density[i, j];
                densityLeft =  1.0/density[i - 1, j];
                densityDown = 1.0/density[i, j - 1];
            }

            kx[i] = rx*(densityLeft+densityCentre)/(2.0*densityLeft*densityCentre);
            ky[i] = ry*(densityDown+densityCentre)/(2.0*densityDown*densityCentre);
        }
    }

    // The main Jacobi solve step
    proc jacobi_iterate(const in x: int, const in y: int, const in halo_depth: int, 
    ref u: [?u_domain] real, ref u0: [?u0_domain] real, ref r: [?r_domain] real, ref error: [?error_domain] real,
    ref kx: [?kx_domain] real, ref ky: [?ky_domain] real){

        const Domain = {0..<x, 0..<y};
        const Inner = {halo_depth..<x - halo_depth, halo_depth..<y + halo_depth};

        forall (i, j) in Domain do 
            r[i, j] = u[i. j];

        var err: real = 0.0;

        forall (i, j) in Inner (+ reduce err) do {    
            u[i, j] = (u0[i, j] 
                + (kx[i+1, j]*r[i+1, j] + kx[i, j]*r[i-1, j])
                + (ky[i, j+1]*r[i, j+1] + ky[i, j]*r[i, j-1]))
            / (1.0 + (kx[i, j]+kx[i+1, j])
                    + (ky[i, j]+ky[i, j+1]));

            err += abs(u[i, j]-r[i, j]);


            // error = err //TODO figure out pointers, maybe 'c_ptr(error) = err'
        }
        

    }
}


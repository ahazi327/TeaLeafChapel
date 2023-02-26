/*
 *		JACOBI SOLVER KERNEL
 */


module jacobi{
    var densityCentre: real(64);
    var densityLeft: real(64);
    var densityDown: real(64);
    use settings;
    use chunks;

    // Initialises the Jacobi solver
    proc jacobi_init(){
        
        const Domain = {1..y-1, 1..x-1};
        const Inner = {halo_depth..y - (1 + halo_depth), halo_depth..x - (1 + halo_depth)};

        // if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY do //TODO reference CONDUCTIVITY
        
        //     // die(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient); // die is an int but from where?
        //     writeln(__LINE__, __FILE__, "Coefficient %d is not valid.\n", coefficient)
        

        forall i in Domain do{
            u0[i] = energy[i]*density[i]; // possibly need temp var
            u[i] = energy[i]*density[i];
        }   


        forall i in Inner do{  //might need to make nested loops here
            if coefficient == settings.CONDUCTIVITY do  
                densityCentre = density[i];
                densityLeft = density[i-1];
                densityDown = density[i-x];
            
            else 
                densityCentre = 1.0/density[i];
                densityLeft =  1.0/density[i-1];
                densityDown = 1.0/density[i-x];
            
            
            kx[index] = rx*(densityLeft+densityCentre)/(2.0*densityLeft*densityCentre);
            ky[index] = ry*(densityDown+densityCentre)/(2.0*densityDown*densityCentre);
        }
    }

    // The main Jacobi solve step
    proc main(){

        const Domain = {0..y-1, 0..x-1};
        const Inner = {halo_depth..y - (1 + halo_depth), halo_depth..x - (1 + halo_depth)};

        forall i in Domain do 
            r[i] = u[i];

        var err: real = 0.0;

        forall i in Inner do {    
            u[i] = (u0[i] 
                + (kx[i+1]*r[i+1] + kx[i]*r[i-1])
                + (ky[i+x]*r[i+x] + ky[i]*r[i-x]))
            / (1.0 + (kx[i]+kx[i+1])
                    + (ky[i]+ky[i+x]));
            err += abs(u[i]-r[i]);
            // error = err //TODO figure out pointers, maybe 'c_ptr(error) = err'
        }
        

    }
}


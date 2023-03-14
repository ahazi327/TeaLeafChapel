/*
 *		SHARED SOLVER METHODS
 */
module solver_methods {

    // Copies the current u into u0
    proc copy_u (const in x: int, const in y: int, const in halo_depth: int, 
    ref u: [?u_domain] real, ref u0: [?u0_domain] real){
        
        u0 = u; // whole array assignment instead of individually assigning
    }

    // Calculates the current value of r
    proc calculate_residual(const in x: int, const in y: int, const in halo_depth: int, 
    ref u: [?u_domain] real, ref u0: [?u0_domain] real, ref r: [?r_domain] real, ref kx: [?kx_domain] real,
    ref ky: [?ky_domain] real){
        forall (i, j) in {halo_depth..< x - halo_depth, halo_depth..<y-halo_depth} do {
            const smvp: real = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            
            r[i, j] = u0[i, j] - smvp;
        }
    }

    // Calculates the 2 norm of a given buffer
    proc calculate_2norm (const in x: int, const in y: int, const in halo_depth: int, 
    ref buffer: [?buffer_domain] real, ref norm: [?norm_domain] real){
        
        var norm_temp: real = 0.0;

        forall (i, j) in {halo_depth..< x - halo_depth, halo_depth..<y-halo_depth} with (+ reduce norm_temp) do {
            norm_temp += buffer[i, j]*buffer[i, j];	
        }
        
        // *norm += norm_temp;
    }

    // Finalises the solution
    proc finalise (const in x: int, const in y: int, const in halo_depth: int, 
    ref energy: [?energy_domain] real, ref density: [?density_domain] real, ref u: [?u_domain] real) {

        forall (i, j) in {halo_depth..< x - halo_depth, halo_depth..<y-halo_depth} do {
            energy[i, j] = u[i, j]/density[i, j];
        }

    }
}
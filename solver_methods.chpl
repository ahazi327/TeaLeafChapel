/*
 *		SHARED SOLVER METHODS
 */
module solver_methods {
    use profile;
    
    // Copies the current u into u0
    proc copy_u (const in x: int, const in y: int, const in halo_depth: int, 
    const ref u: [?u_domain] real, ref u0: [u_domain] real){
        profiler.startTimer("copy_u");

        var halo_domain = u_domain[halo_depth..< y - halo_depth, halo_depth..<x-halo_depth];

        foreach ij in halo_domain do u0[ij] = u[ij];
        // u0[halo_domain] = u[halo_domain]; 

        profiler.stopTimer("copy_u");
    }

    // Calculates the current value of r
    proc calculate_residual(const in x: int, const in y: int, const in halo_depth: int, 
    const ref u: [?Domain] real, const ref u0: [Domain] real, ref r: [Domain] real, const ref kx: [Domain] real,
    const ref ky: [Domain] real){
        profiler.startTimer("calculate_residual");
        const inner = Domain[halo_depth..<y - halo_depth, halo_depth..<x - halo_depth];
        forall (i, j) in inner do {
            const smvp: real = (1.0 + ((kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j])))*u[i, j]
                - ((kx[i+1, j]*u[i+1, j])+(kx[i, j]*u[i-1, j]))
                - ((ky[i, j+1]*u[i, j+1])+(ky[i, j]*u[i, j-1]));
            
            r[i, j] = u0[i, j] - smvp;
        }
        profiler.stopTimer("calculate_residual");
    }

    // Calculates the 2 norm of a given buffer
    proc calculate_2norm (const in x: int, const in y: int, const in halo_depth: int, 
    const ref buffer: [?buffer_domain] real, ref norm: real){
        profiler.startTimer("calculate_2norm");
        var norm_temp: real;
        const inner = buffer_domain[halo_depth..<y - halo_depth, halo_depth..<x-halo_depth];

        // forall (i, j) in inner with (+ reduce norm) do {
        //     norm += buffer[i, j] ** 2;	
        // }
        norm_temp += + reduce (buffer[inner] ** 2);
        norm += norm_temp;

        profiler.stopTimer("calculate_2norm");
    }

    // Finalises the solution
    proc finalise (const in x: int, const in y: int, const in halo_depth: int, 
    ref energy: [?Domain] real, const ref density: [Domain] real, const ref u: [Domain] real) {

        profiler.startTimer("finalise");
        var halo_domain = Domain[halo_depth-1..< y - halo_depth, halo_depth-1..<x-halo_depth];

        foreach ij in halo_domain do energy[ij] = u[ij] / density[ij];

        // energy[halo_domain] = u[halo_domain] / density[halo_domain];

        profiler.stopTimer("finalise");
    }
}
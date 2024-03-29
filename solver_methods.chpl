/*
 *		SHARED SOLVER METHODS
 */
module solver_methods {
    use profile;
    use chunks;
    
    // Copies the current u into u0
    proc copy_u (const in halo_depth: int, const ref u: [?u_domain] real, ref u0: [u_domain] real){
        profiler.startTimer("copy_u");

        [ij in u_domain.expand(-halo_depth)] u0.localAccess[ij] = u.localAccess[ij];

        profiler.stopTimer("copy_u");
    }

    // Calculates the current value of r
    proc calculate_residual(const in halo_depth: int, const ref u: [?Domain] real, const ref u0: [Domain] real, 
                            ref r: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real){
        profiler.startTimer("calculate_residual");
        if useStencilDist {
            forall (i, j) in Domain.expand(-halo_depth)  do {
                const smvp: real = (1.0 + ((kx.localAccess[i+1, j]+kx.localAccess[i, j])
                    + (ky.localAccess[i, j+1]+ky.localAccess[i, j])))*u.localAccess[i, j]
                    - ((kx.localAccess[i+1, j]*u.localAccess[i+1, j])+(kx.localAccess[i, j]*u.localAccess[i-1, j]))
                    - ((ky.localAccess[i, j+1]*u.localAccess[i, j+1])+(ky.localAccess[i, j]*u.localAccess[i, j-1]));
                
                r.localAccess[i, j] = u0.localAccess[i, j] - smvp;
            }
        } else {
            forall (i, j) in Domain.expand(-halo_depth)  do {
                const smvp: real = (1.0 + ((kx[i+1, j]+kx.localAccess[i, j])
                    + (ky[i, j+1]+ky.localAccess[i, j])))*u.localAccess[i, j]
                    - ((kx[i+1, j]*u[i+1, j])+(kx.localAccess[i, j]*u[i-1, j]))
                    - ((ky[i, j+1]*u[i, j+1])+(ky.localAccess[i, j]*u[i, j-1]));
                
                r.localAccess[i, j] = u0.localAccess[i, j] - smvp;
            }
        }
        
        profiler.stopTimer("calculate_residual");
    }

    // Calculates the 2 norm of a given buffer
    proc calculate_2norm (const in halo_depth: int, const ref buffer: [?buffer_domain] real, ref norm: real){
        profiler.startTimer("calculate_2norm");

        var norm_temp: real = + reduce (buffer[buffer_domain.expand(-halo_depth) ] ** 2);
        norm += norm_temp;

        profiler.stopTimer("calculate_2norm");
    }

    // Finalises the solution
    proc finalise (const in x: int, const in y: int, const in halo_depth: int, ref energy: [?Domain] real, 
                    const ref density: [Domain] real, const ref u: [Domain] real) {
        profiler.startTimer("finalise");

        const halo_domain = Domain[halo_depth-1..< y - halo_depth, halo_depth-1..<x-halo_depth];
        [ij in halo_domain] energy.localAccess[ij] = u.localAccess[ij] / density.localAccess[ij];

        profiler.stopTimer("finalise");
    }
}
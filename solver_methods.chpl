/*
 *		SHARED SOLVER METHODS
 */
module solver_methods {
    use profile;
    use chunks;
    use GPU;
    
    // Copies the current u into u0
    proc copy_u (const in halo_depth: int, const ref u: [?u_domain] real, ref u0: [u_domain] real, const ref reduced_OneD : domain(1), 
        const ref reduced_local_domain : domain(2)){
            
        // profiler.startTimer("copy_u");

        forall oneDIdx in reduced_OneD {
            const ij = reduced_local_domain.orderToIndex(oneDIdx);
            u0[ij] = u[ij];
        } 

        // profiler.stopTimer("copy_u");
    }

    // Calculates the current value of r
    proc calculate_residual(const in halo_depth: int, const ref u: [?Domain] real, const ref u0: [Domain] real, 
        ref r: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real, const ref reduced_OneD : domain(1), 
        const ref reduced_local_domain : domain(2)){

        // profiler.startTimer("calculate_residual");
        forall oneDIdx in reduced_OneD {
            const (i, j) = reduced_local_domain.orderToIndex(oneDIdx);
            const smvp: real = (1.0 + ((kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j])))*u[i, j]
                - ((kx[i+1, j]*u[i+1, j])+(kx[i, j]*u[i-1, j]))
                - ((ky[i, j+1]*u[i, j+1])+(ky[i, j]*u[i, j-1]));
            
            r[i, j] = u0[i, j] - smvp;
        }
    
        // profiler.stopTimer("calculate_residual");
    }

    // Calculates the 2 norm of a given buffer
    proc calculate_2norm (const in halo_depth: int, ref buffer: [?buffer_domain] real, ref norm: real, 
        const ref reduced_OneD : domain(1), const ref reduced_local_domain : domain(2)){

        // profiler.startTimer("calculate_2norm");
        var norm_temp: real;

        if useGPU {
            forall oneDIdx in reduced_OneD {
                const ij = reduced_local_domain.orderToIndex(oneDIdx);
                buffer[ij] = buffer[ij] ** 2;
            } 
        
            norm_temp = gpuSumReduce(buffer); // This causes a lot of transfers between host and device
        
        } else {
            norm_temp = + reduce (buffer[buffer_domain.expand(-halo_depth) ] ** 2);
        }
        norm = norm_temp;

        // profiler.stopTimer("calculate_2norm");
    }

    // Finalises the solution
    proc finalise (const in x: int, const in y: int, const in halo_depth: int, ref energy: [?Domain] real, 
        const ref density: [Domain] real, const ref u: [Domain] real, const ref reduced_OneD : domain(1), 
        const ref reduced_local_domain : domain(2)) {
        // profiler.startTimer("finalise");

        // const halo_domain = Domain[halo_depth-1..< y - halo_depth, halo_depth-1..<x-halo_depth];
        forall oneDIdx in reduced_OneD {
            const ij = reduced_local_domain.orderToIndex(oneDIdx);
            energy[ij] = u[ij] / density[ij];
        }
        // profiler.stopTimer("finalise");
    }
}
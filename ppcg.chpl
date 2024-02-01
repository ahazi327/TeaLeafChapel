/*
 *		PPCG SOLVER KERNEL
 */
module ppcg{
    use profile;
    use chunks;
    use GPU;

    // Initialises the PPCG solver
    proc ppcg_init(const in halo_depth: int, const in theta: real, const ref r: [?Domain] real, 
                    ref sd: [Domain] real) {
        // profiler.startTimer("ppcg_init");
        
        forall ij in Domain.expand(-halo_depth) {
            sd[ij] = r[ij] / theta;
        }
        // profiler.stopTimer("ppcg_init");
    }

    // The PPCG inner iteration
    proc ppcg_inner_iteration (const in halo_depth: int, const in alpha: real, const in beta: real, ref u: [?Domain] real, 
                                ref r: [Domain] real, ref sd: [Domain] real, const ref kx: [Domain] real, 
                                const ref ky: [Domain] real){
        // profiler.startTimer("ppcg_inner_iteration");

            forall (i, j) in Domain.expand(-halo_depth)  do {
                const smvp : real = (1.0 + (kx[i+1, j]+kx[i, j])
                            + (ky[i, j+1]+ky[i, j]))*sd[i, j]
                            - (kx[i+1, j]*sd[i+1, j]+kx[i, j]*sd[i-1, j])
                            - (ky[i, j+1]*sd[i, j+1]+ky[i, j]*sd[i, j-1]);

                r[i, j] -= smvp;
                u[i, j] += sd[i, j];
            } 
        

        forall ij in Domain.expand(-halo_depth) {
            sd[ij] = alpha * sd[ij] + beta * r[ij]; // TODO check implicit version
        }
        // profiler.stopTimer("ppcg_inner_iteration");
    }

}
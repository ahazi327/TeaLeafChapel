/*
 *		PPCG SOLVER KERNEL
 */
module ppcg{
    use profile;
    use chunks;
    use GPU;

    // Initialises the PPCG solver
    proc ppcg_init(const in halo_depth: int, const in theta: real, const ref r: [?Domain] real, 
        ref sd: [Domain] real, const ref reduced_OneD : domain(1), const ref reduced_local_domain : domain(2)) {
        // profiler.startTimer("ppcg_init");
        
        forall oneDIdx in reduced_OneD {
            const ij = reduced_local_domain.orderToIndex(oneDIdx);
            sd[ij] = r[ij] / theta;
        }
        // profiler.stopTimer("ppcg_init");
    }

    // The PPCG inner iteration
    proc ppcg_inner_iteration (const in halo_depth: int, const in alpha: real, const in beta: real, ref u: [?Domain] real, 
        ref r: [Domain] real, ref sd: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real, 
        const ref reduced_OneD : domain(1), const ref reduced_local_domain : domain(2)){
        // profiler.startTimer("ppcg_inner_iteration");

            forall oneDIdx in reduced_OneD {
                const (i, j) = reduced_local_domain.orderToIndex(oneDIdx);
                const smvp : real = (1.0 + (kx[i+1, j]+kx[i, j])
                            + (ky[i, j+1]+ky[i, j]))*sd[i, j]
                            - (kx[i+1, j]*sd[i+1, j]+kx[i, j]*sd[i-1, j])
                            - (ky[i, j+1]*sd[i, j+1]+ky[i, j]*sd[i, j-1]);

                r[i, j] -= smvp;
                u[i, j] += sd[i, j];
            } 
        

        forall oneDIdx in reduced_OneD {
            const ij = reduced_local_domain.orderToIndex(oneDIdx);
            sd[ij] = alpha * sd[ij] + beta * r[ij]; // TODO check implicit version
        }
        // profiler.stopTimer("ppcg_inner_iteration");
    }

}
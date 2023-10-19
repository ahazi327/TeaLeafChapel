/*
 *		PPCG SOLVER KERNEL
 */
module ppcg{
    use profile;
    use chunks;

    // Initialises the PPCG solver
    proc ppcg_init(const in halo_depth: int, const in theta: real, const ref r: [?Domain] real, 
                    ref sd: [Domain] real) {
        profiler.startTimer("ppcg_init");
        
        [ij in Domain.expand(-halo_depth)] sd.localAccess[ij] = r.localAccess[ij] / theta;

        profiler.stopTimer("ppcg_init");
    }

    // The PPCG inner iteration
    proc ppcg_inner_iteration (const in halo_depth: int, const in alpha: real, const in beta: real, ref u: [?Domain] real, 
                                ref r: [Domain] real, ref sd: [Domain] real, const ref kx: [Domain] real, 
                                const ref ky: [Domain] real){
        profiler.startTimer("ppcg_inner_iteration");
        if useStencilDist {
            forall (i, j) in Domain.expand(-halo_depth)  do {
                const smvp : real = (1.0 + (kx.localAccess[i+1, j]+kx.localAccess[i, j])
                            + (ky.localAccess[i, j+1]+ky.localAccess[i, j]))*sd.localAccess[i, j]
                            - (kx.localAccess[i+1, j]*sd.localAccess[i+1, j]+kx.localAccess[i, j]*sd.localAccess[i-1, j])
                            - (ky.localAccess[i, j+1]*sd.localAccess[i, j+1]+ky.localAccess[i, j]*sd.localAccess[i, j-1]);

                r.localAccess[i, j] -= smvp;
                u.localAccess[i, j] += sd.localAccess[i, j];
            }
        } else {
            forall (i, j) in Domain.expand(-halo_depth)  do {
                const smvp : real = (1.0 + (kx[i+1, j]+kx.localAccess[i, j])
                            + (ky[i, j+1]+ky.localAccess[i, j]))*sd.localAccess[i, j]
                            - (kx[i+1, j]*sd[i+1, j]+kx.localAccess[i, j]*sd[i-1, j])
                            - (ky[i, j+1]*sd[i, j+1]+ky.localAccess[i, j]*sd[i, j-1]);

                r.localAccess[i, j] -= smvp;
                u.localAccess[i, j] += sd.localAccess[i, j];
            }
        }   
        

        [ij in Domain.expand(-halo_depth)] sd.localAccess[ij] = alpha * sd.localAccess[ij] + beta * r.localAccess[ij]; // TODO check implicit version

        profiler.stopTimer("ppcg_inner_iteration");
    }

}
/*
 *		PPCG SOLVER KERNEL
 */
module ppcg{
    use profile;

    // Initialises the PPCG solver
    proc ppcg_init(const in x: int, const in y: int, const in halo_depth: int, const in theta: real, const ref r: [Domain] real,
    ref sd: [Domain] real, const in Domain : domain(2)) {
        profiler.startTimer("ppcg_init");
        const inner = Domain[halo_depth..< x - halo_depth, halo_depth..<y-halo_depth];
        
        forall ij in inner do sd[ij] = r[ij] / theta;
        profiler.stopTimer("ppcg_init");
    }

    // The PPCG inner iteration
    proc ppcg_inner_iteration (const in x: int, const in y: int, const in halo_depth: int, const in alpha: real, const in beta: real,
    ref u: [Domain] real, ref r: [Domain] real, ref sd: [Domain] real,
    const ref kx: [Domain] real, const ref ky: [Domain] real, const in Domain : domain(2)){
        profiler.startTimer("ppcg_inner_iteration");
        
        const inner = Domain[halo_depth..< x - halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner do {
            const smvp : real = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*sd[i, j]
                - (kx[i+1, j]*sd[i+1, j]+kx[i, j]*sd[i-1, j])
                - (ky[i, j+1]*sd[i, j+1]+ky[i, j]*sd[i, j-1]);

            r[i, j] -= smvp;
            u[i, j] += sd[i, j];
        }

        foreach ij in inner do sd[ij] = alpha * sd[ij] + beta * r[ij]; // TODO check implicit version

        profiler.stopTimer("ppcg_inner_iteration");
    }

}
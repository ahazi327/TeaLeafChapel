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
        forall (i, j) in inner {
            // Prefetch kx and ky values
            const kx_next = kx[i+1, j];
            const kx_current = kx[i, j];
            const ky_next = ky[i, j+1];
            const ky_current = ky[i, j];

            // Use prefetched values
            const smvp : real = (1.0 + (kx_next + kx_current)
                    + (ky_next + ky_current))*sd[i, j]
                    - (kx_next*sd[i+1, j] + kx_current*sd[i-1, j])
                    - (ky_next*sd[i, j+1] + ky_current*sd[i, j-1]);

            r[i, j] -= smvp;
            u[i, j] += sd[i, j];
        }

        forall ij in inner do sd[ij] = (alpha * sd[ij]) + (beta * r[ij]);

        profiler.stopTimer("ppcg_inner_iteration");
    }

}
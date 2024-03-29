/*
 *		CHEBYSHEV SOLVER KERNEL
 */

// Calculates the new value for u.
module cheby {
    use profile;
    use chunks;

    proc cheby_calc_u(const ref halo_depth: int, ref u: [?Domain] real, const ref p: [Domain] real){
        profiler.startTimer("cheby_calc_u");
        
        [ij in Domain.expand(-halo_depth)] u.localAccess[ij] += p.localAccess[ij];

        profiler.stopTimer("cheby_calc_u");
    }

    // Initialises the Chebyshev solver
    proc cheby_init(const ref halo_depth: int, const ref theta: real, ref u: [?Domain] real, 
                    const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
                    ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real){
        profiler.startTimer("cheby_init");
        if useStencilDist{
            forall (i, j) in Domain.expand(-halo_depth) do{ 
                const smvp: real = (1.0 + (kx.localAccess[i+1, j]+kx.localAccess[i, j])
                                    + (ky.localAccess[i, j+1]+ky.localAccess[i, j]))*u.localAccess[i, j]
                                    - (kx.localAccess[i+1, j]*u.localAccess[i+1, j]+kx.localAccess[i, j]*u.localAccess[i-1, j])
                                    - (ky.localAccess[i, j+1]*u.localAccess[i, j+1]+ky.localAccess[i, j]*u.localAccess[i, j-1]);
                w.localAccess[i, j] = smvp;
                r.localAccess[i, j] = u0.localAccess[i, j] - smvp;
                p.localAccess[i, j] = r.localAccess[i, j] / theta;
            }
        } else {
            forall (i, j) in Domain.expand(-halo_depth) do{ 
                const smvp: real = (1.0 + (kx[i+1, j]+kx.localAccess[i, j])
                                    + (ky[i, j+1]+ky.localAccess[i, j]))*u.localAccess[i, j]
                                    - (kx[i+1, j]*u[i+1, j]+kx.localAccess[i, j]*u[i-1, j])
                                    - (ky[i, j+1]*u[i, j+1]+ky.localAccess[i, j]*u[i, j-1]);
                w.localAccess[i, j] = smvp;
                r.localAccess[i, j] = u0.localAccess[i, j] - smvp;
                p.localAccess[i, j] = r.localAccess[i, j] / theta;
            }
        }
        cheby_calc_u(halo_depth, u, p);

        profiler.stopTimer("cheby_init");
    }

    // The main chebyshev iteration
    proc cheby_iterate(const ref halo_depth: int, const ref alpha: real, const ref beta: real,
                       ref u: [?Domain] real, const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
                       ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real){
        profiler.startTimer("cheby_iterate");
        if useStencilDist{
            forall (i, j) in Domain.expand(-halo_depth) do{
                const smvp: real = (1.0 + (kx.localAccess[i+1, j]+kx.localAccess[i, j])
                                    + (ky.localAccess[i, j+1]+ky.localAccess[i, j]))*u.localAccess[i, j]
                                    - (kx.localAccess[i+1, j]*u.localAccess[i+1, j]+kx.localAccess[i, j]*u.localAccess[i-1, j])
                                    - (ky.localAccess[i, j+1]*u.localAccess[i, j+1]+ky.localAccess[i, j]*u.localAccess[i, j-1]);
                w.localAccess[i, j] = smvp;
                r.localAccess[i, j] = u0.localAccess[i, j] - smvp;
                p.localAccess[i, j] = alpha * p.localAccess[i, j] + beta * r.localAccess[i, j];
            }
        } else {
            forall (i, j) in Domain.expand(-halo_depth) do{
                const smvp: real = (1.0 + (kx[i+1, j]+kx.localAccess[i, j])
                                    + (ky[i, j+1]+ky.localAccess[i, j]))*u.localAccess[i, j]
                                    - (kx[i+1, j]*u[i+1, j]+kx.localAccess[i, j]*u[i-1, j])
                                    - (ky[i, j+1]*u[i, j+1]+ky.localAccess[i, j]*u[i, j-1]);
                w.localAccess[i, j] = smvp;
                r.localAccess[i, j] = u0.localAccess[i, j] - smvp;
                p.localAccess[i, j] = alpha * p.localAccess[i, j] + beta * r.localAccess[i, j];
            }
        }
        cheby_calc_u(halo_depth, u, p);

        profiler.stopTimer("cheby_iterate");
    }
}
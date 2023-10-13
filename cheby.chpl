/*
 *		CHEBYSHEV SOLVER KERNEL
 */

// Calculates the new value for u.
module cheby {
    use profile;

    proc cheby_calc_u(const ref halo_depth: int, ref u: [?Domain] real, const ref p: [Domain] real){
        profiler.startTimer("cheby_calc_u");
        
        [ij in Domain.expand(-halo_depth)] u[ij] += p[ij];

        profiler.stopTimer("cheby_calc_u");
    }

    // Initialises the Chebyshev solver
    proc cheby_init(const ref halo_depth: int, const ref theta: real, ref u: [?Domain] real, 
                    const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
                    ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real){
        profiler.startTimer("cheby_init");

        forall (i, j) in Domain.expand(-halo_depth) do{ 
            const smvp: real = (1.0 + (kx.localAccess[i+1, j]+kx.localAccess[i, j])
                                + (ky.localAccess[i, j+1]+ky.localAccess[i, j]))*u.localAccess[i, j]
                                - (kx.localAccess[i+1, j]*u.localAccess[i+1, j]+kx[i, j]*u.localAccess[i-1, j])
                                - (ky.localAccess[i, j+1]*u.localAccess[i, j+1]+ky[i, j]*u.localAccess[i, j-1]);
            w[i, j] = smvp;
            r[i, j] = u0[i, j] - smvp;
            p[i, j] = r[i, j] / theta;
        }
        cheby_calc_u(halo_depth, u, p);

        profiler.stopTimer("cheby_init");
    }

    // The main chebyshev iteration
    proc cheby_iterate(const ref halo_depth: int, const ref alpha: real, const ref beta: real,
                       ref u: [?Domain] real, const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
                       ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real){
        profiler.startTimer("cheby_iterate");

        forall (i, j) in Domain.expand(-halo_depth) do{
            const smvp: real = (1.0 + (kx.localAccess[i+1, j]+kx.localAccess[i, j])
                                + (ky.localAccess[i, j+1]+ky.localAccess[i, j]))*u.localAccess[i, j]
                                - (kx.localAccess[i+1, j]*u.localAccess[i+1, j]+kx.localAccess[i, j]*u.localAccess[i-1, j])
                                - (ky.localAccess[i, j+1]*u.localAccess[i, j+1]+ky.localAccess[i, j]*u.localAccess[i, j-1]);
            w[i, j] = smvp;
            r[i, j] = u0[i, j] - smvp;
            p[i, j] = alpha * p[i, j] + beta * r[i, j];
        }
        cheby_calc_u(halo_depth, u, p);

        profiler.stopTimer("cheby_iterate");
    }
}
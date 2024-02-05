/*
 *		CHEBYSHEV SOLVER KERNEL
 */

// Calculates the new value for u.
module cheby {
    use profile;
    use chunks;
    use GPU;

    proc cheby_calc_u(const ref halo_depth: int, ref u: [?Domain] real, const ref p: [Domain] real, 
        const ref reduced_OneD : domain(1), const ref reduced_local_domain : domain(2)){

        // profiler.startTimer("cheby_calc_u");
        forall oneDIdx in reduced_OneD {
            const ij = reduced_local_domain.orderToIndex(oneDIdx);
            u[ij] = u[ij] + p[ij];
        }
        // profiler.stopTimer("cheby_calc_u");
    }

    // Initialises the Chebyshev solver
    proc cheby_init(const ref halo_depth: int, const ref theta: real, ref u: [?Domain] real, 
        const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real, ref w: [Domain] real, 
        const ref kx: [Domain] real, const ref ky: [Domain] real, const ref reduced_OneD : domain(1), 
        const ref reduced_local_domain : domain(2)){
        // profiler.startTimer("cheby_init");
        forall oneDIdx in reduced_OneD {
            const (i, j) = reduced_local_domain.orderToIndex(oneDIdx);
            const smvp: real = (1.0 + (kx[i+1, j]+kx[i, j])
                                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            w[i, j] = smvp;
            r[i, j] = u0[i, j] - smvp;
            p[i, j] = r[i, j] / theta;
        }
        cheby_calc_u(halo_depth, u, p, reduced_OneD, reduced_local_domain);

        // profiler.stopTimer("cheby_init");
    }

    // The main chebyshev iteration
    proc cheby_iterate(const ref halo_depth: int, const ref alpha: real, const ref beta: real,
        ref u: [?Domain] real, const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
        ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real, 
        const ref reduced_OneD : domain(1), const ref reduced_local_domain : domain(2)){

        // profiler.startTimer("cheby_iterate");
        forall oneDIdx in reduced_OneD {
            const (i, j) = reduced_local_domain.orderToIndex(oneDIdx);
            const smvp: real = (1.0 + (kx[i+1, j]+kx[i, j])
                                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            w[i, j] = smvp;
            r[i, j] = u0[i, j] - smvp;
            p[i, j] = alpha * p[i, j] + beta * r[i, j];
        }
        cheby_calc_u(halo_depth, u, p, reduced_OneD, reduced_local_domain);

        // profiler.stopTimer("cheby_iterate");
    }
}
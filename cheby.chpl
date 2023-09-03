/*
 *		CHEBYSHEV SOLVER KERNEL
 */

// Calculates the new value for u.
module cheby {
    use profile;

    proc cheby_calc_u (const in x: int, const in y: int, const in halo_depth: int, ref u: [Domain] real,
                        const ref p: [Domain] real, const in Domain : domain(2)){
        profiler.startTimer("cheby_calc_u");
        const halo_dom = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall ij in halo_dom do{
            u[ij] += p[ij];
        }
        profiler.stopTimer("cheby_calc_u");
    }

    // Initialises the Chebyshev solver
    proc cheby_init (const in x: int, const in y: int, const in halo_depth: int, const in theta: real,
                    ref u: [Domain] real, const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
                    ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real, 
                    const in Domain : domain(2)){
        profiler.startTimer("cheby_init");

        const inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner do{  // with (+ reduce u)
            const smvp: real = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            w[i, j] = smvp;
            r[i, j] = u0[i, j] - smvp;
            p[i, j] = r[i, j] / theta;
        }
        cheby_calc_u(x, y, halo_depth, u, p, Domain);

        profiler.stopTimer("cheby_init");
    }

    // The main chebyshev iteration
    proc cheby_iterate (const in x: int, const in y: int, const in halo_depth: int, const ref alpha: real, const ref beta: real,
                        ref u: [Domain] real, const ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
                        ref w: [Domain] real, const ref kx: [Domain] real, const ref ky: [Domain] real, 
                        const in Domain : domain(2)){
        profiler.startTimer("cheby_iterate");

        const inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner do{
            const smvp: real = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            w[i, j] = smvp;
            r[i, j] = u0[i, j] - smvp;
            p[i, j] = alpha * p[i, j] + beta * r[i, j];
        }
        cheby_calc_u(x, y, halo_depth, u, p, Domain);
        profiler.stopTimer("cheby_iterate");
    }
}
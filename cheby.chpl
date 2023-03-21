/*
 *		CHEBYSHEV SOLVER KERNEL
 */

// Calculates the new value for u.
module cheby {
    proc cheby_calc_u (const in x: int, const in y: int, const in halo_depth: int, ref u: [?up_domain] real,
    ref p: [up_domain] real){
        const halo_dom = [halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        // forall (i, j) in halo_dom with (+ reduce u) do{
        u += p;
        // }

    }

    // Initialises the Chebyshev solver
    proc cheby_init (const in x: int, const in y: int, const in halo_depth: int, const in theta: real,
    ref u: [?Domain] real, ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
    ref w: [Domain] real, ref kx: [Domain] real, ref ky: [Domain] real){
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
        cheby_calc_u(x, y, halo_depth, u, p);
    }

    // The main chebyshev iteration
    proc cheby_iterate (const in y: int, const in halo_depth: int, inout alpha: real, inout beta: real,
    ref u: [?Domain] real, ref u0: [Domain] real, ref p: [Domain] real, ref r: [Domain] real,
    ref w: [Domain] real, ref kx: [Domain] real, ref ky: [Domain] real){
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
        cheby_calc_u(x, y, halo_depth, u, p);
    }
}
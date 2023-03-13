/*
 *		CHEBYSHEV SOLVER KERNEL
 */

// Calculates the new value for u.
module cheby {
    proc cheby_calc_u (const in x: int, const in y: int, const in halo_depth: int, ref u: [?u_domain] real,
    ref p: [?p_domain] real){
        
        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} with (+ reduce u) do{
            u[i, j] += p[i, j];
        }

    }

    // Initialises the Chebyshev solver
    proc cheby_init (const in x: int, const in y: int, const in halo_depth: int, const in theta: real,
    ref u: [?u_domain] real, ref u0: [?u0_domain] real, ref p: [?p_domain] real, ref r: [?r_domain] real,
    ref w: [?w_domain] real, ref kx: [?kx_domain] real, ref ky: [?ky_domain] real){
        
        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} with (+ reduce u) do{
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
    proc cheby_iterate (const in x: int, const in y: int, const in halo_depth: int, inout alpha: real, inout beta: real,
    ref u: [?u_domain] real, ref u0: [?u0_domain] real, ref p: [?p_domain] real, ref r: [?r_domain] real,
    ref w: [?w_domain] real, ref kx: [?kx_domain] real, ref ky: [?ky_domain] real){
        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} do{
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
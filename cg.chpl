/*
 *		CONJUGATE GRADIENT SOLVER KERNEL
 */
module cg {
    use settings;
    use Math;
    proc cg_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: int,
    inout rx: real, inout ry: real, out rro: real,  ref density: [?Domain] real,  ref energy: [Domain] real,
    ref u: [Domain] real,  ref p: [Domain] real,  ref r: [Domain] real,  ref w: [Domain] real,  ref kx: [Domain] real,
     ref ky: [Domain] real){
        //TODO implement die line here
        const halo_dom = {0..<x, 0..<y};
        // forall (i, j) in {0..<x, 0..<y} do {
        //     p[i,j] = 0.0;
        //     r[i,j] = 0.0;
        //     u[i,j] = energy[i,j] * density[i,j];
        // }
        p[halo_dom] = 0.0;
        r[halo_dom] = 0.0;
        u[halo_dom] = energy[halo_dom] * density[halo_dom];

        const inner = halo_dom[1..<x-1, 1..<y-1];

        forall (i, j) in inner do {
            if (coefficient == CONDUCTIVITY) then
                w_domain[i,j] = density[i,j];
            else  
                w_domain[i,j] = 1.0/density[i,j];
        }

        const inner_1 = halo_dom[halo_depth..<x-1, halo_depth..<y-1];
        forall (i, j) in inner_1 do {
            kx[i, j] = rx*(w[i-1, j]+w[i, j]) /
                (2.0*w[i-1, j]*w[i, j]);
            ky[i, j] = ry*(w[i, j-1]+w[i, j]) /
                (2.0*w[i, j-1]*w[i, j]);
        }

        var rro: real= 0.0;
        const inner_2 = halo_dom[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner_2 (+ reduce rro) do {  // with 
            w[i,j] =  (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            r[i,j] = u[i,j]-w[i,j];
            p[i,j] = r[i,j];
            rro += r[i,j]*p[i,j];
        }
    }

    // Calculates w
    proc cg_calc_w (const in x: int, const in y: int, const in halo_depth: int, out pw: real, ref p: [?Domain] real,
    ref w: [Domain] real, ref kx: [Domain] real, ref ky: [Domain] real){
        var pw: real = 0.0;
        
        const inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner with (+ reduce pw) do{
            const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*p[i, j]
                - (kx[i+1, j]*p[i+1, j]+kx[i, j]*p[i-1, j])
                - (ky[i, j+1]*p[i, j+1]+ky[i, j]*p[i, j-1]);
            w[i,j] = smvp;
            pw += smvp * p[i, j];
        }
    }

    // Calculates u and r
    proc cg_calc_ur(const in x: int, const in y: int, const in halo_depth: int, const in alpha: real, out rrn: real, 
    ref u: [?Domain] real, ref p: [Domain] real, ref r: [Domain] real, ref w: [Domain] real){
        var rrn: real= 0.0;
        const inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner (+ reduce rrn) do{ //with
            u[i, j] = alpha * p[i, j];
            r[i, j] = alpha * w[i, j];
            const temp: real = r[i, j];  // maybe make into var
            rrn += temp * temp;
        }
    }

    // Calculates p
    proc cg_calc_p (const in x: int, const in y: int, const in halo_depth: int, const in beta: real,
    ref p: [?Domain] real, ref r: [Domain] real) {
        // forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} {
            // p[i, j] = beta * p[i, j] + r[i, j];
        // }
        const halo_dom = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        p[halo_dom] = beta * p[halo_dom] + r[halo_dom];
    }

}
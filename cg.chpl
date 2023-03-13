/*
 *		CONJUGATE GRADIENT SOLVER KERNEL
 */
module cg {
    use settings;
    use Math;
    proc cg_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: int,
    inout rx: real, inout ry: real, ref rro: [?rr] real,  ref density: [?d] real,  ref energy: [?e] real,
    ref u: [?u_domain] real,  ref p: [?p_domain] real,  ref r: [?r_domain] real,  ref w: [?w_domain] real,  ref kx: [?kx_domain] real,
     ref ky: [?ky_domain] real){
        //TODO implement die line here

        forall (i, j) in {0..<x, 0..<y} do {
            p[i,j] = 0.0;
            r[i,j] = 0.0;
            u[i,j] = energy[i,j] * density[i,j];
        }

        forall (i, j) in {1..<x-1, 1..<y-1} do {
            if (coefficient == CONDUCTIVITY) then
                w_domain[i,j] = density[i,j];
            else  
                w_domain[i,j] = 1.0/density[i,j];
        }

        forall (i, j) in {halo_depth..<x-1, halo_depth..<y-1} do {
            kx[i, j] = rx*(w[i-1, j]+w[i, j]) /
                (2.0*w[i-1, j]*w[i, j]);
            ky[i, j] = ry*(w[i, j-1]+w[i, j]) /
                (2.0*w[i, j-1]*w[i, j]);
        }

        var rro_temp: real= 0.0;

        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} with (+ reduce rro_temp) do {
            w[i,j] =  (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
        }
        // Sum locally
        // *rro += rro_temp; //  ?
    }

    // Calculates w
    proc cg_calc_w (const in x: int, const in y: int, const in halo_depth: int, ref pw: [?pw_domain] real, ref p: [?p_domain] real,
    ref w: [?w_domain] real, ref kx: [?kx_domain] real, ref ky: [?ky_domain] real){
        var pw_temp: real = 0.0;
        

        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} with (+ reduce pw_temp) do{
            const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*p[i, j]
                - (kx[i+1, j]*p[i+1, j]+kx[i, j]*p[i-1, j])
                - (ky[i, j+1]*p[i, j+1]+ky[i, j]*p[i, j-1]);
            w[i,j] = smvp;
            pw_temp += smvp * p[i, j];
        }
        //*pw += pw_temp;
    }

    // Calculates u and r
    proc cg_calc_ur(const in x: int, const in y: int, const in halo_depth: int, const in alpha: real, ref rrn: [?rrn_domain] real, 
    ref u: [?u_domain] real, ref p: [?p_domain] real, ref r: [?r_domain] real, ref w: [?w_domain] real){
        var rrn_temp: real= 0.0;

        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} with (+ reduce rrn_temp) do{
            u[i, j] = alpha * p[i, j];
            r[i, j] = alpha * w[i, j];
            const temp: real = r[i, j];  // maybe make into var
            rrn_temp += temp * temp;
        }
    }

    // Calculates p
    proc cg_calc_p (const in x: int, const in y: int, const in halo_depth: int, const in beta: real,
    ref p: [?p_domain] real, ref r: [?r_domain] real) {
        forall (i, j) in {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth} {
            p[i, j] = beta * p[i, j] + r[i, j];
        }
    }

}
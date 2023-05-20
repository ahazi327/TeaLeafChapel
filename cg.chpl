/*
 *		CONJUGATE GRADIENT SOLVER KERNEL
 */
module cg {
    use settings;
    use Math;
    use profile;
    proc cg_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: int,
    in rx: real, in ry: real, ref rro: real,  ref density: [?Domain] real,  ref energy: [Domain] real,
    ref u: [Domain] real,  ref p: [Domain] real,  ref r: [Domain] real,  ref w: [Domain] real,  ref kx: [Domain] real,
     ref ky: [Domain] real){

        profiler.startTimer("cg");
        //TODO implement die line here
        const halo_dom = {0..<x, 0..<y};

        p[halo_dom] = 0.0;
        r[halo_dom] = 0.0;
        u[halo_dom] = energy[halo_dom] * density[halo_dom];
        
        const inner = halo_dom[1..<x-1, 1..<y-1];
        forall (i, j) in inner do {
            if (coefficient == CONDUCTIVITY) then
                w[i,j] = density[i,j];
            else  
                w[i,j] = 1.0/density[i,j];
            
        }

        const inner_1 = halo_dom[halo_depth..<x-1, halo_depth..<y-1];
        forall (i, j) in inner_1 do {
            kx[i, j] = rx*(w[i-1, j]+w[i, j]) / (2.0*w[i-1, j]*w[i, j]);
            ky[i, j] = ry*(w[i, j-1]+w[i, j]) / (2.0*w[i, j-1]*w[i, j]);
        }
        
        var rro_temp : real = 0.0; 
        const inner_2 = halo_dom[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner_2 with (+ reduce rro_temp) do {
            const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*u[i, j]
                - (kx[i+1, j]*u[i+1, j]+kx[i, j]*u[i-1, j])
                - (ky[i, j+1]*u[i, j+1]+ky[i, j]*u[i, j-1]);
            w[i, j] = smvp;
            r[i,j] = u[i,j] - smvp;
            p[i,j] = r[i,j];
            rro_temp += r[i,j]*p[i,j];   
        }
        rro += rro_temp;
        profiler.stopTimer("cg");
    }

    // Calculates w
    proc cg_calc_w (const in x: int, const in y: int, const in halo_depth: int, ref pw: real, ref p: [?Domain] real,
    ref w: [Domain] real, ref kx: [Domain] real, ref ky: [Domain] real){
        profiler.startTimer("cg_calc_w");
        var pw_temp : real;
        const inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner with (+ reduce pw_temp) do{
            const smvp = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*p[i, j]
                - (kx[i+1, j]*p[i+1, j]+kx[i, j]*p[i-1, j])
                - (ky[i, j+1]*p[i, j+1]+ky[i, j]*p[i, j-1]);
            w[i,j] = smvp;
            pw_temp += smvp * p[i, j];
            
        }
        pw += pw_temp;
        profiler.stopTimer("cg_calc_w");
    }
    
    // Calculates u and r
    proc cg_calc_ur(const in x: int, const in y: int, const in halo_depth: int, const in alpha: real, ref rrn: real, 
    ref u: [?Domain] real, ref p: [Domain] real, ref r: [Domain] real, ref w: [Domain] real){
        profiler.startTimer("cg_calc_ur");
        var rrn_temp : real;
        const inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        
        forall (i, j) in inner with (+ reduce rrn_temp) do{ //with
            u[i, j] += alpha * p[i, j];
            r[i, j] -= alpha * w[i, j];
            
            // const temp: real = r[i, j];  // maybe make into var
            rrn_temp += r[i, j] ** 2;
            
        }
        rrn += rrn_temp;
        profiler.stopTimer("cg_calc_ur");
    }

    // Calculates p
    proc cg_calc_p (const in x: int, const in y: int, const in halo_depth: int, const in beta: real,
    ref p: [?Domain] real, ref r: [Domain] real) {
        profiler.startTimer("cg_calc_p");
        const halo_dom = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];
        p[halo_dom] = beta * p[halo_dom] + r[halo_dom];
        profiler.stopTimer("cg_calc_p");
    }

}
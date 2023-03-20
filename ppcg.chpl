/*
 *		PPCG SOLVER KERNEL
 */
module ppcg{

    // Initialises the PPCG solver
    proc ppcg_init(const in x: int, const in y: int, const in halo_depth: int, inout theta: real, ref r: [?Domain] real,
    ref sd: [Domain] real) {

        // forall (i, j) in {halo_depth..< x-halo_depth, halo_depth..< y - halo_depth} do{
        //     sd[i, j] = r[i, j] / theta;
        // }
        sd = r / theta;
    }

    // The PPCG inner iteration
    proc ppcg_inner_iteration (const in x: int, const in y: int, const in halo_depth: int, inout alpha: real, inout beta: real,
    ref u: [?Domain] real, ref r: [Domain] real, ref sd: [Domain] real,
    ref kx: [Domain] real, ref ky: [Domain] real){
        
        const inner = Domain[halo_depth..< x - halo_depth, halo_depth..<y-halo_depth];
        forall (i, j) in inner do {
            const smvp : real = (1.0 + (kx[i+1, j]+kx[i, j])
                + (ky[i, j+1]+ky[i, j]))*sd[i, j]
                - (kx[i+1, j]*sd[i+1, j]+kx[i, j]*sd[i-1, j])
                - (ky[i, j+1]*sd[i, j+1]+ky[i, j]*sd[i, j-1]);

            r[i, j] -= smvp;
            u[i, j] += sd[i, j];
        }

        // forall (i, j) in inner do {

        //     sd[i, j] = alpha * sd[i, j] + beta * r[i, j];
        // }
        sd = alpha * sd + beta * r;


    }

}
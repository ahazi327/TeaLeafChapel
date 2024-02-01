/*
 *		JACOBI SOLVER KERNEL
 */
module jacobi{
    use settings;
    use chunks;
    use Math;
    use profile;
    use GPU;
    use GpuDiagnostics;

    // Initialises the Jacobi solver
    proc jacobi_init(const in x: int, const in y: int, const in halo_depth: int, const in coefficient: real, 
                    const in rx: real, const in ry: real, ref u: [?Domain] real, ref u0: [Domain] real, 
                    const ref energy: [Domain] real, const ref density: [Domain] real, ref kx: [Domain] real, 
                    ref ky: [Domain] real){
        
        // profiler.startTimer("jacobi_init");
        const Inner = Domain[halo_depth..<y - 1, halo_depth..<x - 1];

        // if coefficient < 1 && coefficient < RECIP_CONDUCTIVITY
        // {
        //     writeln("Coefficient ", coefficient, " is not valid.\n");
        //      // profiler.stopTimer("jacobi_init");
        //     exit(-1);
        // }
        
        // u = energy * density;
        forall ij in Domain {
            u[ij] = energy[ij] * density[ij];
        }
        forall (i, j) in Inner do{ 
            

            var densityCentre: real;
            var densityLeft: real;
            var densityDown: real;

            if coefficient == CONDUCTIVITY {  
                densityCentre = density[i, j];
                densityLeft = density[i, j-1];
                densityDown = density[i-1, j ];
            }
            else {
                densityCentre = 1.0/density[i, j];
                densityLeft =  1.0/density[i, j - 1];
                densityDown = 1.0/density[i - 1, j];
            }

            kx[i, j] = rx*(densityLeft+densityCentre)/(2.0*densityLeft*densityCentre);
            ky[i, j] = ry*(densityDown+densityCentre)/(2.0*densityDown*densityCentre);
        }

        // profiler.stopTimer("jacobi_init");
    }

    // The main Jacobi solve step
    proc jacobi_iterate(const in halo_depth: int, ref u: [?Domain] real, const ref u0: [Domain] real, 
                        ref r: [Domain] real, ref error: real, const ref kx: [Domain] real, 
                        const ref ky: [Domain] real, ref temp: [Domain] real, const ref reduced_OneD : domain(1), const ref reduced_local_domain : domain(2), const ref local_domain : domain(2), const ref OneD : domain(1)){

        forall (i, j) in Domain {
            r[i,j] = u[i,j];
        }

        const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1);
        
        if useGPU {
            forall ij in Domain.expand(-halo_depth) {
                const stencil : real = (u0[ij] 
                                            + kx[ij + east] * r[ij + east] 
                                            + kx[ij] * r[ij + west]
                                            + ky[ij + north] * r[ij + north] 
                                            + ky[ij] * r[ij + south])
                                        / (1.0 + kx[ij] + kx[ij + east] 
                                            + ky[ij] + ky[ij + north]);
                u[ij] = stencil;

                temp[ij] = abs(u[ij] - r[ij]);
            }
            
            error = gpuSumReduce(temp);
        } else {
            var err: real = 0.0;
            forall ij in Domain.expand(-halo_depth) with (+ reduce err) {
                const stencil : real = (u0[ij] 
                                            + kx[ij + east] * r[ij + east] 
                                            + kx[ij] * r[ij + west]
                                            + ky[ij + north] * r[ij + north] 
                                            + ky[ij] * r[ij + south])
                                        / (1.0 + kx[ij] + kx[ij + east] 
                                            + ky[ij] + ky[ij + north]);
                u[ij] = stencil;

                err += abs(stencil - r[ij]);
            }
            error = err;
        }
    }

    
}


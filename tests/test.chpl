use GpuDiagnostics;
use CTypes;
use GPU; // just to check the unstability warning
use Time;


on here.gpus[0]{
  startGpuDiagnostics();
  var TwoD  : domain(2) = {0..<512, 0..<512};
  // var OneD  : domain(1) = {0..<512*512};
  var u : [TwoD] real = noinit;
  var u0: [TwoD] real = noinit;
  var r: [TwoD] real = noinit;
  var kx: [TwoD] real = noinit;
  var ky: [TwoD] real = noinit;
  var temp: [TwoD] real = noinit;
  var x : int = 10;

  var error : real;

  var wallclock = new stopwatch();

  wallclock.start();  
  writeln("on GPU:");
  for 0..<5000 {
    // jacobi_iterate(u, u0, r, error, kx, ky, temp);
    simple_assignment(u, u0);
    // jacobi_iterate_fix (u, u0, r, error, kx, ky, temp, OneD, TwoD);
  }

  wallclock.stop();

  // writeln("on CPU:");
  // for 0..<5000 {
  //   jacobi(here);
  // }

  stopGpuDiagnostics();

  writeln("Time elapsed for current timestep: ", wallclock.elapsed(), " seconds");
}

proc simple_assignment(ref u: [?TwoD] real, const ref u0: [TwoD] real){
  foreach ij in TwoD {
    u[ij] = u0[ij];
  } 
}

// proc simple_assignment(ref u: [?TwoD] real, const ref u0: [TwoD] real){
//   foreach oneDIdx in OneD {
//     const (i,j) = TwoD.orderToIndex(oneDIdx);
    
//     u[i, j] = u0[i, j];

//   } 
// }

// proc jacobi_iterate(ref u: [?Domain] real, const ref u0: [Domain] real, 
//                     ref r: [Domain] real, ref error: real, const ref kx: [Domain] real, 
//                     const ref ky: [Domain] real, ref temp: [Domain] real){
    
//     // startGpuDiagnostics();
//     // startVerboseGpu();
//     forall ij in Domain {r[ij] = u[ij];}  // 0.5s costs

//     // const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1); // For 2D arrays
//     const north = (64), south = (-64), east = (1), west = (-1);  // For 1D arrays
//     var err: real = 0.0;

//     forall ij in Domain {
//         u[ij] = (u0[ij]   
//                                     + kx[ij + east] * r[ij + east] // TIME REDUCTIONS going from 10.5~ seconds down to 7.8s by simply removing  the north,east,south, west index changes
//                                                                     // likely due to caching? or from something funky with indexing
//                                     + kx[ij] * r[ij + west]
//                                     + ky[ij + north] * r[ij + north]  // removing these lines of the stencil improves the stencil performance by only a small amount
//                                     + ky[ij] * r[ij + south])
//                                 / (1.0 + kx[ij] + kx[ij + east] 
//                                     + ky[ij] + ky[ij + north]);  // Reduction of from 10.5 down to 8.9s from getting rid of denominator
//         // u[ij] = stencil; // Using stencil constant costs about 0.3s (from 10.5s)

//         temp[ij] = abs(u[ij] - r[ij]); // 2~2.5s Time cost
//     }

//     // Required changes as GPUs do not support forall reductions in Chapel

//     error = gpuSumReduce(temp); // 1.5~ time cost
// }

// proc jacobi_iterate_fix (ref u: [?Domain] real, const ref u0: [Domain] real, 
//                     ref r: [Domain] real, ref error: real, const ref kx: [Domain] real, 
//                     const ref ky: [Domain] real, ref temp: [Domain] real, const ref OneD : domain(1), const ref TwoD : domain(2)){
    
//   // startGpuDiagnostics();
//   // startVerboseGpu();
//   forall oneDIdx in OneD {
//       const (i,j) = TwoD.orderToIndex(oneDIdx);
//       r[i,j] = u[i,j];
//   }

//   const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1);
//   var err: real = 0.0;

//   forall oneDIdx in OneD {
//       const ij = TwoD.orderToIndex(oneDIdx);
//       const stencil : real = (u0[ij] 
//                                   + kx[ij + east] * r[ij + east] 
//                                   + kx[ij] * r[ij + west]
//                                   + ky[ij + north] * r[ij + north] 
//                                   + ky[ij] * r[ij + south])
//                               / (1.0 + kx[ij] + kx[ij + east] 
//                                   + ky[ij] + ky[ij + north]);
//       u[ij] = stencil;

//       temp[ij] = abs(u[ij] - r[ij]);
//     }

//     // Required changes as GPUs do not support forall reductions in Chapel

//     error = gpuSumReduce(temp); // 1.5~ time cost
// }
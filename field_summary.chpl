module field_summary {
    proc field_summary (in x: int, in y: int, in halo_depth: int, inout volume: [?Domain] real,
    inout density: [Domain] real , inout energy0: [Domain] real, inout u: [Domain] real, out vol: real,
    out mass: real, out ie: real, out temp: real){

        var vol : real;
        var ie : real;
        var temp : real;
        var mass : real; // should be 0.0 already
        
        var inner = Domain[halo_depth..<x-halo_depth, halo_depth..<y-halo_depth];

        forall (i, j) in inner (+ reduce vol, +reduce mass, + reduce ie, + reduce temp) do {
            var cellVol : real;
            cellVol = volume[i, j];

            var cellMass: real;
            cellMass = cellVol * density[i, j];

            vol += cellVol;
            mass += cellMass;
            ie += cellMass * energy0[i, j];
            temp += cellMass * u[i, j];

        }
    }
}

module field_summary {
    proc field_summary (in x: int, in y: int, in halo_depth: int, inout volume: [?V] real,
    inout density: [?D] real , inout energy0: [?E0] real, inout u: [?U] real, inout volOut: [?VO] real,
    inout massOut: [?m0] real, inout ieOut: [?iO] real, inout tempOut: [tO] real){

        var vol : real;
        var ie : real;
        var temp : real;
        var mass : real; // should be 0.0 already

        var Domain = {halo_depth..<x-halo_depth, halo_depth..<y-halo_depth};

        forall i, j in Domain do {
            var cellVol : real;
            cellVol = volume[i, j];

            var cellMass: real;
            cellMass = cellVol * density[i, j];

            vol = vol + cellVol;
            mass = mass + cellMass;
            ie = ie + cellMass * energy0[i, j];
            temp = temp + cellMass * u[i, j];

        }
        //*volOut += vol;
        // *ieOut += ie;
        // *tempOut += temp;
        // *massOut += mass;
    }


}

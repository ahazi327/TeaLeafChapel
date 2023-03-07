module store_energy {
    proc store_energy (in x: int, in y: int, in energy0: [?E0] real, inout energy: [?E1]){
        forall ii in 0..<x*y do{
            energy[ii] = energy0[ii];
        }
    }

}
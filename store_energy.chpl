module store_energy {
    proc store_energy (in x: int, in y: int, ref energy0: [?energy_domain] real, ref energy: [energy_domain] real){
        // forall (i, j) in energy_domain do{
        //     energy[i, j] = energy0[i, j];
        // }
        energy = energy0;
    }

}

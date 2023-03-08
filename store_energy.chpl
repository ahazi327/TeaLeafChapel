module store_energy {
    proc store_energy (in x: int, in y: int, in energy0: [?E0] real, inout energy: [?E1]){
        forall i, j in {0..<x, 0..<y} do{
            energy[i, j] = energy0[i, j];
        }
    }

}

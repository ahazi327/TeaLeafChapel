module store_energy {
    use chunks;

    // Store original energy state
    proc store_energy (in x: int, in y: int, ref energy0: [?energy_domain] real, ref energy: [energy_domain] real){
        
        energy = energy0;
    }

    // Invokes the store energy kernel
    proc store_energy_driver (ref chunk_var : [?chunk_domain] chunks.Chunk){
        store_energy(chunk_var[0].x, chunk_var[0].y, chunk_var[0].energy0, chunk_var[0].energy);
    }


}

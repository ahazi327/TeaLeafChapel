module store_energy {
    use chunks;
    use profile;
    
    // Store original energy state
    proc store_energy (const ref energy0: [?E_Dom] real, ref energy: [E_Dom] real){
        profiler.startTimer("store_energy");

        forall ij in energy.domain do energy[ij] = energy0[ij];

        profiler.stopTimer("store_energy");
    }

    // Invokes the store energy kernel
    proc store_energy_driver (ref chunk_var : chunks.Chunk){
        store_energy(chunk_var.energy0, chunk_var.energy);
        if useStencilDist {
            profiler.startTimer("comms");
            chunk_var.energy.updateFluff();
            profiler.stopTimer("comms");
        }
    }


}

module store_energy {
    use chunks;
    use profile;
    
    // Store original energy state
    proc store_energy (const ref energy0: [?E_Dom] real, ref energy: [E_Dom] real){
        // profiler.startTimer("store_energy");

        [ij in E_Dom] energy[ij] = energy0[ij];

        // profiler.stopTimer("store_energy");
    }
}

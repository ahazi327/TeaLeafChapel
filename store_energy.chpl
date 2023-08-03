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
    }


}

// OLD BUGGED CODE - causes wrong u array values on -nl 2, despite not explicitly affecting it and a gasnet error on -nl 4 (odd locale counts are finef)
// module store_energy {
//     use chunks;
//     use profile;
    
//     // Store original energy state
//     proc store_energy (const ref energy0: [energy_domain] real, ref energy: [energy_domain] real, const in energy_domain : domain(2)){
//         profiler.startTimer("store_energy");

//         forall ij in energy_domain do energy[ij] = energy0[ij];

//         profiler.stopTimer("store_energy");
//     }

//     // Invokes the store energy kernel
//     proc store_energy_driver (ref chunk_var : chunks.Chunk){
//         store_energy(chunk_var.energy0, chunk_var.energy, {0..<chunk_var.y, 0..<chunk_var.x});
//     }


// }

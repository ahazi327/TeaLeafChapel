module test{
    use profile_mini;
    use StencilDist;
    use BlockDist;
    param ITER_SHORT : int = 100;
    param ITER_MEDIUM : int = 1000;
    param ITER_LONG : int = 10000;
    var ITER : int = ITER_LONG;

    param runs: int = 15;

    param c : real = 0.05; // some number
    param c2 : real = 0.03;

    param GRID_SMALL : int = 512;
    param GRID_MEDIUM : int = 5120;
    var x : int = GRID_MEDIUM; // this will affect the number of assignments taking place in an iteration
    var y : int = GRID_MEDIUM;

    var buffer : [0..<y, 0..<x] real = c2;
    var buffer2 : [0..<y, 0..<x] real = c;
    
    proc simple_array_test (){
        var A : [1..512000, 1..512] real;
        profiler_mini.startTimer("test1");
        for i in 1..512000 by 2 do
            A[i, ..] = 1;
        profiler_mini.stopTimer("test1");

        var B : [1..512000, 1..512] real;
        profiler_mini.startTimer("test2");
        for i in 1..512000 by 2 {
            for j in 1..512 do
                B[i, j] = 1;
        }
        profiler_mini.stopTimer("test2");
        profiler_mini.report();
    }


    proc update_face (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        // buffer.updateFluff();
        for i in {0..<depth} {
            for j in halo_depth..<x-halo_depth {
                // buffer.updateFluff();
                buffer[j, halo_depth-i-1] = buffer[j, i + halo_depth];
                // buffer.updateFluff();
                buffer[j, x-halo_depth + i] = buffer[j, x-halo_depth-(i + 1)];
                // buffer.updateFluff();
            }
        }
        for i in halo_depth..<y-halo_depth {
            for j in {0..<depth} {
                // buffer.updateFluff();
                buffer[y - halo_depth + j, i] = buffer[y - halo_depth - (j + 1), i];
                // buffer.updateFluff();
                
                buffer[halo_depth - j - 1, i] = buffer[halo_depth + j, i];
                // buffer.updateFluff();
            }
        }
        // buffer.updateFluff();
    }
    proc distributedTest (){
        const x_inner : int = 8;
        const y_inner : int = 8;
        const halo_depth : int = 2;
        const local_Domain : domain(2) = {0..<y_inner+(halo_depth*2), 0..<x_inner + (halo_depth*2)};
        var DDomain = local_Domain dmapped Stencil(local_Domain, fluff=(1,1));

        var u: [DDomain] real = 1.1;    
        var u0: [DDomain] real; 
        const north = (1,0), south = (-1,0), east = (0,1), west = (0,-1);

        for 1..10 {       
            u.updateFluff();  
            update_face(x_inner+(halo_depth*2), y_inner+(halo_depth*2), halo_depth, 2, u);
            u.updateFluff();     
            forall ij in {halo_depth..<y_inner+halo_depth, halo_depth..<(x_inner + halo_depth)} {
                u0[ij] = u[ij] + u[ij + north] + u[ij + west] + u[ij + east] + u[ij + south];
            }
            u0.updateFluff();  
            update_face(x_inner+(halo_depth*2), y_inner+(halo_depth*2), halo_depth, 2, u0);
            u0.updateFluff();  
            u = u0;
            u.updateFluff(); 
        }
        var sum = + reduce u;
        writeln("u array \n", u);
        writeln("sum = ", sum);
        // writeln("u0 array \n", u0);

    }

    distributedTest(); 

    // assigning to array slices a constant value with forall loop
    proc test_sequence_1 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real){
        forall i in {0..<y/2} {
            buffer[i, 0..<x] = c; // assigning value same as all other array indicies
        }
    }

    // assigning to array slices another array slice
    proc test_sequence_2 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real, const ref buffer2: [0..<y, 0..<x] real){
        forall i in {0..<y/2} {
            buffer[i, 0..<x] = buffer2[i, 0..<x];
        }
    }

    /*
    // assigning to array slices a constant value with foreach loop
    proc test_sequence_3 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real){
        foreach i in {0..<y} {
            buffer[i, 0..<x] = c;
        }
    }

    // assigning to array slices another array slice with foreach loop
    proc test_sequence_4 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real, const ref buffer2: [0..<y, 0..<x] real){
        foreach i in {0..<y} {
            buffer[i, 0..<x] = buffer2[i, 0..<x];
        }
    }*/

    // assigning to array slices a constant value sequentially
    proc test_sequence_5 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real){
        for i in {0..<y/2} {
            buffer[i, 0..<x] = c;
        }
    }
    
    // assigning to array slices another array slice sequentially
    proc test_sequence_6 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real, const ref buffer2: [0..<y, 0..<x] real){
        for i in {0..<y/2} {
            buffer[i, 0..<x] = buffer2[i, 0..<x];
        }
    }

    // no loop array to const
    proc test_sequence_7 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real){
        buffer[0..<y/2, 0..<x] = c;
    }
    // no loop array to array
    proc test_sequence_8 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real, const ref buffer2: [0..<y, 0..<x] real){
        buffer[0..<y/2, 0..<x] = buffer2[0..<y/2, 0..<x];
    }

    //control group (no slicing) array=c
    proc test_sequence_9 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real){
        forall ij in {0..<y/2, 0..<x} {
            buffer[ij] = c;
        }
    }
    //control group (no slicing) array=array
    proc test_sequence_10 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real, const ref buffer2: [0..<y, 0..<x] real){
        forall ij in {0..<y/2, 0..<x} {
            buffer[ij] = buffer2[ij];
        }
    }
    //control group (no slicing) array=c sequential
    proc test_sequence_11 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real){
        for ij in {0..<y/2, 0..<x} {
            buffer[ij] = c;
        }
    }
    //control group (no slicing) array=array sequential
    proc test_sequence_12 (const in x: int, const in y: int, ref buffer: [0..<y, 0..<x] real, const ref buffer2: [0..<y, 0..<x] real){
        for ij in {0..<y/2, 0..<x} {
            buffer[ij] = buffer2[ij];
        }
    }

    proc strided_array_chplteam_code (const in x: int, const in y: int){
        var buffer : [1..51200, 1..512] real;
        buffer[1..51200 by 2, ..] = 1;
    }
    proc strided_array_original (const in x: int, const in y: int){
        var buffer : [1..51200, 1..512] real;
        for i in 1..51200 by 2 do
            buffer[i, ..] = 1;
    }
    proc halo_update_code_1 (const in x: int, const in y: int, const in halo_depth: int, ref A: [0..<y, 0..<x] real, const ref B: [0..<y, 0..<x] real){
        forall (kk, jj) in {0..<halo_depth, 0..<x} do{       //speed: 0.8s  // do more tests on this
            A[halo_depth-kk-1, jj] = B[kk + halo_depth, jj]; 
        }
        // or 
        // forall (jj, kk) in {halo_depth..<y-halo_depth, 0..<depth} do{
        //     buffer[halo_depth-kk-1, jj] = buffer[kk + halo_depth, jj]; 
        // }
    }
    proc halo_update_code_2 (const in x: int, const in y: int, const in halo_depth: int, ref A: [0..<y, 0..<x] real, const ref B: [0..<y, 0..<x] real){
        [i in 0..<halo_depth] A[halo_depth-i-1, 0..<x] = B[i + halo_depth, 0..<x];
    }

    // number of runs for statistical backing
    for run in 1..runs{

        // vary the grid sizes
        // for size in 1..3 {
        //     select(size){
        //         when 3{
        //             x = GRID_MEDIUM;
        //             y = GRID_SMALL;
        //             ITER = ITER_LONG;
        //         }
        //         when 2{
        //             x = GRID_SMALL;
        //             y = GRID_MEDIUM;
        //             ITER = ITER_LONG;
        //         }
        //         when 1{
        //             x = GRID_MEDIUM;
        //             y = GRID_MEDIUM;
        //             ITER = ITER_MEDIUM;
        //         }
        //     }

            // writeln("Grid size and depth values are ", x, "x", y, " for ", ITER, " iterations");

            // call test functions many times
            // for i in 1..ITER {
            // profiler_mini.startTimer("slice_to_constant_forall_loop");
            // test_sequence_1(x, y, buffer);
            // profiler_mini.stopTimer("slice_to_constant_forall_loop");
            // }

            // for i in 1..ITER {
            //     profiler_mini.startTimer("slice_to_slice_forall_loop");
            //     test_sequence_2(x, y, buffer, buffer2);
            //     profiler_mini.stopTimer("slice_to_slice_forall_loop");
            // }

            /*
            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_constant_foreach_loop");
                test_sequence_3(x, y, buffer);
                profiler_mini.stopTimer("slice_to_constant_foreach_loop");
            }

            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_slice_foreach_loop");
                test_sequence_4(x, y, buffer, buffer2);
                profiler_mini.stopTimer("slice_to_slice_foreach_loop");
            }*/

            // for i in 1..ITER {
            //     profiler_mini.startTimer("slice_to_constant_for_loop");
            //     test_sequence_5(x, y, buffer);
            //     profiler_mini.stopTimer("slice_to_constant_for_loop");
            // }

            // for i in 1..ITER {
            //     profiler_mini.startTimer("slice_to_slice_for_loop");
            //     test_sequence_6(x, y, buffer, buffer2);
            //     profiler_mini.stopTimer("slice_to_slice_for_loop");
            // }

            // for i in 1..ITER {
            //     profiler_mini.startTimer("slice_to_constant_no_loop");
            //     test_sequence_7(x, y, buffer);
            //     profiler_mini.stopTimer("slice_to_constant_no_loop");
            // }

            // for i in 1..ITER {
            //     profiler_mini.startTimer("slice_to_slice_no_loop");
            //     test_sequence_8(x, y, buffer, buffer2);
            //     profiler_mini.stopTimer("slice_to_slice_no_loop");
            // }

            // for i in 1..ITER {
            //     profiler_mini.startTimer("control_group_array_to_const");
            //     test_sequence_9(x, y, buffer);
            //     profiler_mini.stopTimer("control_group_array_to_const");
            // }
            // for i in 1..ITER {
            //     profiler_mini.startTimer("control_group_array_to_array");
            //     test_sequence_10(x, y, buffer, buffer2);
            //     profiler_mini.stopTimer("control_group_array_to_array");
            // }
            // for i in 1..ITER {
            //     profiler_mini.startTimer("strided_array_chplteam_code");
            //     strided_array_chplteam_code(x, y);
            //     profiler_mini.stopTimer("strided_array_chplteam_code");
            // }

            // for i in 1..ITER {
            //     profiler_mini.startTimer("strided_array_original");
            //     strided_array_original(x, y);
            //     profiler_mini.stopTimer("strided_array_original");
            // }
        //     for i in 1..ITER {
        //         profiler_mini.startTimer("halo_update_code_1");
        //         halo_update_code_1(x, y, 20, buffer, buffer2);
        //         profiler_mini.stopTimer("halo_update_code_1");
        //     }

        //     for i in 1..ITER {
        //         profiler_mini.startTimer("halo_update_code_2");
        //         halo_update_code_2(x, y, 20, buffer, buffer2);
        //         profiler_mini.stopTimer("halo_update_code_2");
        //     }

        //     profiler_mini.report();
        // // }
    }
}

module profile_mini {
    use Map;
    use Time;
    
    class ProfileTracker {
        var timers: domain(string);
        var timerVals: [timers] stopwatch;
        var callCounts: [timers] int;

        proc startTimer(name: string) {
            if !timers.contains(name) { 
                timers += name;
                timerVals[name] = new stopwatch();
                callCounts[name] = 0;
            }
            timerVals[name].start();
            callCounts[name] += 1;
        }

        proc stopTimer(name: string) {
            if timers.contains(name) {
                timerVals[name].stop();
            } else {
                writeln("Warning: Attempted to stop a timer that was never started: ", name);
            }
        }

        proc report() {
            writeln("Profile Summary:");
            for name in timers {
                writeln("   Procedure ", name, " called ", callCounts[name], 
                        " times.             Total time spent: ", timerVals[name].elapsed(), " seconds");
            }
            writeln("\n");
            // Clearing the timer data to reset arrays
            timers.clear();
        }
    }

    // Global tracker
    var profiler_mini = new ProfileTracker();
}
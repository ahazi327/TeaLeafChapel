module test{
    use profile_mini;
    param ITER_SHORT : int = 100;
    param ITER_MEDIUM : int = 5000;
    param ITER_LONG : int = 50000;
    var ITER : int = ITER_SHORT;


    param c : real = 0.05;
    param c2 : real = 0.03;

    param GRID_SMALL : int = 512;
    param GRID_MEDIUM : int = 5120;
    var x : int = GRID_SMALL; // this will affect the number of assignments taking place in an iteration
    var y : int = GRID_SMALL;

    var buffer : [0..<y, 0..<x] real = c2;
    var buffer2 : [0..<y, 0..<x] real = c;
    

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
        buffer[0..<y/2, 0..<x] = buffer2[0..<y, 0..<x];
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


    // vary the grid sizes
    for size in 1..4 {
        select(size){
            when 4{
                x = GRID_SMALL;
                y = GRID_SMALL;
                writeln("Grid size and depth values are ", GRID_SMALL, "x", GRID_SMALL);
            }
            when 3{
                x = GRID_MEDIUM;
                y = GRID_SMALL;
                writeln("Grid size and depth values are ", GRID_MEDIUM, "x", GRID_SMALL);
            }
            when 2{
                x = GRID_SMALL;
                y = GRID_MEDIUM;
                writeln("Grid size and depth values are ", GRID_SMALL, "x", GRID_MEDIUM);
            }
            when 1{
                x = GRID_MEDIUM;
                y = GRID_MEDIUM;
                writeln("Grid size and depth values are ", GRID_MEDIUM, "x", GRID_MEDIUM);
            }
        }

        // call test functions many times
        for i in 1..ITER {
        profiler_mini.startTimer("slice_to_constant_forall_loop");
        test_sequence_1(x, y, buffer);
        profiler_mini.stopTimer("slice_to_constant_forall_loop");
        }

        for i in 1..ITER {
            profiler_mini.startTimer("slice_to_slice_forall_loop");
            test_sequence_2(x, y, buffer, buffer2);
            profiler_mini.stopTimer("slice_to_slice_forall_loop");
        }

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

        for i in 1..ITER {
            profiler_mini.startTimer("slice_to_constant_for_loop");
            test_sequence_5(x, y, buffer);
            profiler_mini.stopTimer("slice_to_constant_for_loop");
        }

        for i in 1..ITER {
            profiler_mini.startTimer("slice_to_slice_for_loop");
            test_sequence_6(x, y, buffer, buffer2);
            profiler_mini.stopTimer("slice_to_slice_for_loop");
        }

        for i in 1..ITER {
            profiler_mini.startTimer("slice_to_constant_no_loop");
            test_sequence_7(x, y, buffer);
            profiler_mini.stopTimer("slice_to_constant_no_loop");
        }

        for i in 1..ITER {
            profiler_mini.startTimer("slice_to_slice_no_loop");
            test_sequence_8(x, y, buffer, buffer2);
            profiler_mini.stopTimer("slice_to_slice_no_loop");
        }

        for i in 1..ITER {
            profiler_mini.startTimer("control_group_array_to_const");
            test_sequence_9(x, y, buffer);
            profiler_mini.stopTimer("control_group_array_to_const");
        }
        for i in 1..ITER {
            profiler_mini.startTimer("control_group_array_to_array");
            test_sequence_10(x, y, buffer, buffer2);
            profiler_mini.stopTimer("control_group_array_to_array");
        }

        profiler_mini.report();
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
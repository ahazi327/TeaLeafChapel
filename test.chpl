module test{
    use profile_mini;
    param ITER_SHORT : int = 50;
    param ITER_MEDIUM : int = 500;
    param ITER_LONG : int = 5000;
    var ITER : int = ITER_SHORT;


    param c : real = 0.05;

    param GRID_SMALL : int = 512;
    param GRID_MEDIUM : int = 5120;
    var x : int = GRID_SMALL; // this will affect the number of assignments taking place in an iteration
    var y : int = GRID_SMALL;

    // Grid must be bigger than depth
    param DEPTH_SHALLOW : int = 20;
    param DEPTH_MEDIUM_DEPTH : int = 200;
    param DEPTH_DEEP : int = 2000;
    var depth : int = DEPTH_SHALLOW; // this should make the effect of the loop type larger

    var buffer : [0..<y, 0..<x] real = c;
    

    // assigning to array slices a constant value with forall loop
    proc test_sequence_1 (const in x: int, const in y: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        forall i in {0..<depth} {
            buffer[depth-i-1, depth..<x-depth] = c; // assigning value same as all other array indicies
        }
    }

    // assigning to array slices another array slice
    proc test_sequence_2 (const in x: int, const in y: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        forall i in {0..<depth} {
            buffer[depth-i-1, depth..<x-depth] = buffer[i + depth, depth..<x-depth];
        }
    }

    // assigning to array slices a constant value with foreach loop
    proc test_sequence_3 (const in x: int, const in y: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        foreach i in {0..<depth} {
            buffer[depth-i-1, depth..<x-depth] = c;
        }
    }

    // assigning to array slices another array slice with foreach loop
    proc test_sequence_4 (const in x: int, const in y: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        foreach i in {0..<depth} {
            buffer[depth-i-1, depth..<x-depth] = buffer[i + depth, depth..<x-depth];
        }
    }

    // assigning to array slices a constant value sequentially
    proc test_sequence_5 (const in x: int, const in y: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        for i in {0..<depth} {
            buffer[depth-i-1, depth..<x-depth] = c;
        }
    }
    
    // assigning to array slices another array slice sequentially
    proc test_sequence_6 (const in x: int, const in y: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        for i in {0..<depth} {
            buffer[depth-i-1, depth..<x-depth] = buffer[i + depth, depth..<x-depth];
        }
    }

    // vary the grid sizes
    for size in 1..3 {
        select(size){
            when 1{
                x = GRID_SMALL;
                y = GRID_SMALL;
                depth = DEPTH_SHALLOW;
                writeln("Grid size and depth values are ", GRID_SMALL, "x", GRID_SMALL, " and ", DEPTH_SHALLOW);
            }
            when 2{
                x = GRID_MEDIUM;
                y = GRID_SMALL;
                depth = DEPTH_MEDIUM_DEPTH;
                writeln("Grid size and depth values are ", GRID_MEDIUM, "x", GRID_SMALL, " and ", DEPTH_MEDIUM_DEPTH);
            }
            when 3{
                x = GRID_MEDIUM;
                y = GRID_MEDIUM;
                depth = DEPTH_DEEP;
                writeln("Grid size and depth values are ", GRID_MEDIUM, "x", GRID_MEDIUM, " and ", DEPTH_DEEP);
            }
        }
        // call test functions many times
        for iteration in 1..3{ 
            select(iteration){ // do tests with all 3 iteration counts
                when 1{
                    ITER = ITER_SHORT;
                    writeln("Iteration count is short @ 50");
                } 
                when 2{
                    ITER = ITER_MEDIUM;
                    writeln("Iteration count is short @ 500");
                } 
                when 3{
                    ITER = ITER_LONG;
                    writeln("Iteration count is short @ 5000");
                } 
            }

            for i in 1..ITER {
            profiler_mini.startTimer("slice_to_constant_forall_loop");
            test_sequence_1(x, y, depth, buffer);
            profiler_mini.stopTimer("slice_to_constant_forall_loop");
            }

            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_slice_forall_loop");
                test_sequence_2(x, y, depth, buffer);
                profiler_mini.stopTimer("slice_to_slice_forall_loop");
            }

            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_constant_foreach_loop");
                test_sequence_3(x, y, depth, buffer);
                profiler_mini.stopTimer("slice_to_constant_foreach_loop");
            }

            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_slice_foreach_loop");
                test_sequence_4(x, y, depth, buffer);
                profiler_mini.stopTimer("slice_to_slice_foreach_loop");
            }

            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_constant_for_loop");
                test_sequence_5(x, y, depth, buffer);
                profiler_mini.stopTimer("slice_to_constant_for_loop");
            }

            for i in 1..ITER {
                profiler_mini.startTimer("slice_to_slice_for_loop");
                test_sequence_6(x, y, depth, buffer);
                profiler_mini.stopTimer("slice_to_slice_for_loop");
            }

            profiler_mini.report();
            }
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
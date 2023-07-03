module test{
    use profile_mini;

    param c : real = 0.05;
    var x : int = 512;
    var y : int = 512;
    var halo_depth : int = 2;
    var buffer : [0..<x, 0..<y] real = c;
    

    // assigning to array slices a constant value
    proc test_sequence_1 (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        forall i in {0..<depth} {
            buffer[halo_depth-i-1, halo_depth..<x-halo_depth] = c; // assigning value same as all other array indicies
        }
    }

    // assigning to array slices another array slice
    proc test_sequence_2 (const in x: int, const in y: int, const in halo_depth: int, const in depth: int, ref buffer: [0..<y, 0..<x] real){
        forall i in {0..<depth} {
            buffer[halo_depth-i-1, halo_depth..<x-halo_depth] = buffer[i + halo_depth, halo_depth..<x-halo_depth];
        }
    }
    
    // call test functions many times
    for i in 1..10000 {
        profiler_mini.startTimer("test_sequence_1");
        test_sequence_1(x, y, halo_depth, halo_depth, buffer);
        profiler_mini.stopTimer("test_sequence_1");

        profiler_mini.startTimer("test_sequence_2");
        test_sequence_2(x, y, halo_depth, halo_depth, buffer);
        profiler_mini.stopTimer("test_sequence_2");
    }


    profiler_mini.report();

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
                writeln("Procedure ", name, " called ", callCounts[name], 
                        " times.             Total time spent: ", timerVals[name].elapsed(), " seconds");
            }
        }
    }

    // Global tracker
    var profiler_mini = new ProfileTracker();
}
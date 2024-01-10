module profile {
    use Map;
    use Time;
    use GPU;
    
    // on here.gpus[0] {
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
        var profiler = new ProfileTracker();
    // }
}
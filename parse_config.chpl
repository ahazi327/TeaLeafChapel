module parse_config {
    use settings;
    use IO;
    writeln("hello world");
    proc find_num_states (ref setting_var : setting){

        var tea_in = open (setting_var.tea_in_filename, iomode.r); // open file
        // var tea_in_reader = tea_in.reader(); // read file

        var counter : int;

        for line in tea_in.lines() { // as long as not last line
            if line.find("*tea", 0..) {
                continue;
            } else if line.find("*endtea", 0..) {
                break;  // End of file
            } else if line.find("state", 0..){
                counter += 1;
            } else break; // if past states lines then finish loop
        }
        tea_in.close();
        setting_var.num_states = counter;
    }

    // Read configuration file
    proc read_config(ref setting_var : setting, ref states : [0..<setting_var.num_states]  state){

        // Read all of the settings from the config
        read_file(setting_var, states);

        // Set the cell widths now
        setting_var.dx = (setting_var.grid_x_max - setting_var.grid_x_min) / setting_var.grid_x_cells;
        setting_var.dy = (setting_var.grid_y_max - setting_var.grid_y_min) / setting_var.grid_y_cells;
        
        
    }   

    proc read_file(ref setting_var : setting, ref states : [0..<setting_var.num_states]  state){ 
        // Open the configuration file
        var tea_in = open (setting_var.tea_in_filename, iomode.r);
        var tea_in_reader = tea_in.reader();
        var line: string;
        var counter : int; // fine line number

        while tea_in_reader.readLine(line) {
            counter += 1;

            // Check what the next line is equivalent to
            if line.find("*tea") != 1 {
                continue;
            } else if line.find("*endtea", 0..) {
                break;  // End of file
            } else if line.find("state ", 0..){
                var stateNum: int;
                var density: real;
                var energy: real;
                var geomType: string;
                var xmin: real;
                var xmax: real;
                var ymin: real;
                var ymax: real;
                var radius: real;  // Radius in text file goes last

                // Read all of the states from the configuration file
                if stateNum > 1 {
                    states[stateNum-1].defined = true;
                    states[stateNum-1].energy = energy;
                    states[stateNum-1].density = density;
                    states[stateNum-1].x_min = xmin;
                    states[stateNum-1].x_max = xmax;
                    states[stateNum-1].y_min = ymin;
                    states[stateNum-1].y_max = ymax;

                    if geomType =="rectangle"  
                        {states[stateNum-1].geometry = Geometry.RECTANGULAR;}
                    else if geomType =="circular" 
                        {states[stateNum-1].geometry = Geometry.CIRCULAR;
                        states[stateNum-1].radius = radius;}  // Only use radius var if geometry is set to circular
                    else if geomType =="point" 
                        {states[stateNum-1].geometry = Geometry.POINT;}
                } 
                else if stateNum == 1 { // State 1 is the default state so geometry irrelevant
                    states[stateNum-1].defined = true;
                    states[stateNum-1].energy = energy;
                    states[stateNum-1].density = density;
                }   
                continue;
            
            // Parse the switches
            } else if line.find("use_cg", 0..){
                setting_var.solver = Solver.CG_SOLVER;
                continue;
            } else if line.find("use_jacobi", 0..) {
                setting_var.solver = Solver.JACOBI_SOLVER;
                continue;
            } else if line.find("use_chebyshev", 0..) {
                setting_var.solver = Solver.CHEBY_SOLVER;
                continue;
            } else if line.find("use_ppcg", 0..) {
                setting_var.solver = Solver.PPCG_SOLVER;
                continue;
            } else if line.find("use_c_kernels", 0..) {
                // Do nothing
                continue;
            } else if line.find("check_result", 0..) {
                setting_var.check_result = true;
                continue;
            } else if line.find("errswitch", 0..) {
                setting_var.error_switch = true;
                continue;
            } else if line.find("preconditioner_on", 0..) {
                setting_var.preconditioner = true;
                continue;
            } else if line.find("coefficient_density", 0..) {
                setting_var.coefficient = CONDUCTIVITY;
                continue;
            } else if line.find("coefficient_inverse_density", 0..) {
                setting_var.coefficient = RECIP_CONDUCTIVITY;
                continue;
            } 

            // Parse the key-value pairs
            else if line.find("xmin", 0..) {
                var value = line.split('=')[1];
                setting_var.grid_x_min = value[1] : real;
                continue;
            } else if line.find("ymin", 0..) {
                var value = line.split('=')[1];
                setting_var.grid_y_min = value[1] : real;
                continue;
            } else if line.find("xmax", 0..) {
                var value = line.split('=')[1];
                setting_var.grid_x_max = value[1] : real;
                continue;
            } else if line.find("ymax", 0..) {
                var value = line.split('=')[1];
                setting_var.grid_y_max = value[1] : real;
                continue;
            } else if line.find("x_cells", 0..) {
                var value = line.split('=')[1];
                setting_var.grid_x_cells = value[1] : int;
                continue;
            } else if line.find("y_cells", 0..) {
                var value = line.split('=')[1];
                setting_var.grid_y_cells = value[1] : int;
                continue;
            } else if line.find("initial_timestep", 0..) {
                var value = line.split('=')[1];
                setting_var.dt_init = value[1] : real;
                continue;
            } else if line.find("end_time", 0..) {
                var value = line.split('=')[1];
                setting_var.end_time = value[1] : real;
                continue;
            } else if line.find("end_step", 0..) {
                var value = line.split('=')[1];
                setting_var.end_step = value[1] : real;
                continue;
            } else if line.find("summary_frequency", 0..) {
                var value = line.split('=')[1];
                setting_var.summary_frequency = value[1] : int;
                continue;
            } else if line.find("presteps", 0..) {
                var value = line.split('=')[1];
                setting_var.presteps = value[1] : int;
                continue;
            } else if line.find("ppcg_inner_steps", 0..) {
                var value = line.split('=')[1];
                setting_var.ppcg_inner_steps = value[1] : int;
                continue;
            } else if line.find("epslim", 0..) {
                var value = line.split('=')[1];
                setting_var.eps_lim = value[1] : real;
                continue;
            } else if line.find("max_iters", 0..) {
                var value = line.split('=')[1];
                setting_var.max_iters = value[1] : int;
                continue;
            } else if line.find("eps", 0..) {
                var value = line.split('=')[1];
                setting_var.eps = value[1] : real;
                continue;
            } else if line.find("num_chunks_per_rank", 0..) {
                var value = line.split('=')[1];
                setting_var.num_chunks_per_rank = value[1] : int;
                continue;
            } else if line.find("halo_depth", 0..) {
                var value = line.split('=')[1];
                setting_var.num_chunks_per_rank = value[1] : int;
                continue;
            } else {  // If file is not formatted properly
                writeln("Warning: unrecognized line ", counter, ": ", line);
            }
        }
        // close the file
        tea_in.close();
    }
}
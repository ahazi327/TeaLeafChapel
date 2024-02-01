// Initialise the chunkBlock
module chunks{
  use settings;
  use StencilDist;
  use BlockDist;

  const num_face_domain = {-1..<NUM_FACES, -1..<NUM_FACES};

  // Set as True if using multilocale
  config param useStencilDist = false;
  config param useBlockDist = false;
  config param useGPU = false;
  
  config var global_x = 512;
  config var global_y = 512;
  config var global_halo_depth = 2;
  config var global_dt_init = 0.0;

  proc set_var (const ref setting_var : settings.setting){
    global_halo_depth = setting_var.halo_depth;
    global_x = setting_var.grid_x_cells;
    global_y = setting_var.grid_y_cells;
    global_dt_init = setting_var.dt_init;
  }

  record Chunk{
    var halo_depth: int = global_halo_depth;
    var x_inner: int = global_x;
    var y_inner: int = global_y;

    var x: int = x_inner + halo_depth * 2;
    var y: int = y_inner + halo_depth * 2;
    
    // Domains
    const local_Domain : domain(2) = {0..<y, 0..<x};
    const OneD  : domain(1) = {0..<y*x};
    const reduced_local_domain = local_Domain.expand(-halo_depth);
    const reduced_OneD  : domain(1) = {0..<(y - 2 * halo_depth) * (x - 2 * halo_depth)};

    const x_domain : domain(1) = {0..<x};
    const y_domain : domain(1) = {0..<y};
    const x1_domain: domain(1)  = {0..<x+1};
    const y1_domain : domain(1) = {0..<y+1};
    // const x_area_domain : domain(2) = {0..<y, 0..<x+1};
    // const y_area_domain : domain(2) = {0..<y+1, 0..<x};
    const max_iter_domain : domain(1) = {0..<settings.max_iters};
    
    // Define the bounds of the arrays
    var Domain = if useStencilDist then local_Domain dmapped stencilDist(local_Domain, fluff=(1, 1))
                else if useBlockDist then local_Domain dmapped blockDist(local_Domain)
                else local_Domain;
    
    
    //TODO set up condition to make sure number of locales is only so big compared to grid size
    // if numLocales > (x * y) 
    // {
    //   writeln("Too few locales for grid size :", x,"x", y);
    //   exit(-1);
    // }

    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    
    var dt_init: real = global_dt_init;
    var neighbours: [num_face_domain] (int, int) = noinit;
    var density: [Domain] real = noinit; 
    var density0: [Domain] real = noinit;
    var energy: [Domain] real = noinit;
    var energy0: [Domain] real = noinit;

    var u: [Domain] real = noinit;
    var u0: [Domain] real = noinit;
    var p: [Domain] real = noinit;
    var r: [Domain] real = noinit;
    // var mi: [Domain] real = noinit;
    var w: [Domain] real = noinit;
    var kx: [Domain] real = noinit;
    var ky: [Domain] real = noinit;
    var sd: [Domain] real = noinit;
    var temp: [Domain] real = noinit;
    

    var cell_x: [x_domain] real = noinit;
    var cell_dx: [x_domain] real = noinit;
    var cell_y: [y_domain] real = noinit;
    var cell_dy: [y_domain] real = noinit;

    var vertex_x: [x1_domain] real = noinit;
    var vertex_dx: [x1_domain] real = noinit;
    var vertex_y: [y1_domain] real = noinit;
    var vertex_dy: [y1_domain] real = noinit;

    var volume: [Domain] real = noinit;
    // var x_area: [x_area_domain] real = noinit;
    // var y_area: [y_area_domain] real = noinit;

    // Cheby and PPCG arrays
    var theta: real;
    var eigmin: real;
    var eigmax: real;

    var cg_alphas: [max_iter_domain] real = noinit;
    var cg_betas: [max_iter_domain] real = noinit;
    var cheby_alphas: [max_iter_domain] real = noinit;
    var cheby_betas: [max_iter_domain] real = noinit;

  }
}
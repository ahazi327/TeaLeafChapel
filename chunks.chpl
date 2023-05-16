// Initialise the chunk
module chunks{
  use settings;

  const num_face_domain = {-1..<NUM_FACES, -1..<NUM_FACES};

  record Chunk{

    var x: int;
    var y: int;
    
    //Domains
    var Domain : domain(2) = {0..<y, 0..<x};
    var x_domain : domain(1) = {0..<x};
    var y_domain : domain(1) = {0..<y};
    var x1_domain: domain(1)  = {0..<x+1};
    var y1_domain : domain(1) = {0..<y+1};
    var x_area_domain : domain(2) = {0..<y, 0..<x+1};
    var y_area_domain : domain(2) = {0..<y+1, 0..<x};
    var max_iter_domain : domain(1) = {0..<settings.max_iters};

    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    
    var dt_init: real;
    var neighbours: [num_face_domain] (int, int) = noinit;
    var density: [Domain] real = noinit; 
    var density0: [Domain] real = noinit;
    var energy: [Domain] real = noinit;
    var energy0: [Domain] real = noinit;

    var u: [Domain] real = noinit;
    var u0: [Domain] real = noinit;
    var p: [Domain] real = noinit;
    var r: [Domain] real = noinit;
    var mi: [Domain] real = noinit;
    var w: [Domain] real = noinit;
    var kx: [Domain] real = noinit;
    var ky: [Domain] real = noinit;
    var sd: [Domain] real = noinit;

    var cell_x: [x_domain] real = noinit;
    var cell_dx: [x_domain] real = noinit;
    var cell_y: [y_domain] real = noinit;
    var cell_dy: [y_domain] real = noinit;

    var vertex_x: [x1_domain] real = noinit;
    var vertex_dx: [x1_domain] real = noinit;
    var vertex_y: [y1_domain] real = noinit;
    var vertex_dy: [y1_domain] real = noinit;

    var volume: [Domain] real = noinit;
    var x_area: [x_area_domain] real = noinit;
    var y_area: [y_area_domain] real = noinit;

    // Cheby and PPCG  
    var theta: real;
    var eigmin: real;
    var eigmax: real;

    var cg_alphas: [max_iter_domain] real = noinit;
    var cg_betas: [max_iter_domain] real = noinit;
    var cheby_alphas: [max_iter_domain] real = noinit;
    var cheby_betas: [max_iter_domain] real = noinit;

    proc init (const in halo_depth: int, const in x: int, const in y : int, const in dt_init : real) {
      this.x = x + halo_depth*2;
      this.y = y + halo_depth*2; 
      
      // Resize all domains to resize arrays
      this.Domain = {0..<this.y, 0..<this.x};
      this.x_domain = {0..<this.x};
      this.y_domain = {0..<this.y};
      this.x1_domain = {0..<this.x+1};
      this.y1_domain = {0..<this.y+1};
      this.x_area_domain = {0..<this.y, 0..<this.x+1};
      this.y_area_domain = {0..<this.y+1, 0..<this.x};
      this.dt_init = dt_init;
    }
    // int* neighbours; 
  }
}

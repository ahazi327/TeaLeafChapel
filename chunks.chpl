// Initialise the chunk
module chunks{
  use settings;
  use BlockDist;

  const num_face_domain = {-1..<NUM_FACES, -1..<NUM_FACES};

  record Chunk{

    var x: int;
    var y: int;
    
    // Domains
    // Local domains
    var local_Domain : domain(2) = {0..<y, 0..<x};
    var local_x_domain : domain(1) = {0..<x};
    var local_y_domain : domain(1) = {0..<y};
    var local_x1_domain: domain(1)  = {0..<x+1};
    var local_y1_domain : domain(1) = {0..<y+1};
    var local_x_area_domain : domain(2) = {0..<y, 0..<x+1};
    var local_y_area_domain : domain(2) = {0..<y+1, 0..<x};
    var local_max_iter_domain : domain(1) = {0..<settings.max_iters};

    // // Multi locale domains
    var Domain = local_Domain dmapped Block(local_Domain);
    var x_domain = local_x_domain dmapped Block(local_x_domain) ;
    var y_domain = local_y_domain dmapped Block(local_y_domain);
    var x1_domain = local_x1_domain dmapped Block(local_x1_domain);
    var y1_domain = local_y1_domain dmapped Block(local_y1_domain);
    var x_area_domain = local_x_area_domain dmapped Block(local_x_area_domain);
    var y_area_domain = local_y_area_domain dmapped Block(local_y_area_domain);
    var max_iter_domain = local_max_iter_domain dmapped Block(local_max_iter_domain);

    // locale subdomain indicies
    var D : [Domain] int = noinit;
    var x_D : [x_domain] int = noinit;
    var y_D : [y_domain] int = noinit;
    var x_1_D : [x1_domain] int = noinit;
    var y_1_D : [y1_domain] int = noinit;
    var x_a_D : [x_area_domain] int = noinit;
    var y_a_D : [y_area_domain] int = noinit;
    var m_i_D : [max_iter_domain] int = noinit;

    // TYPE 1
    // var D : [local_Domain] int = noinit;
    // var x_D : [local_x_domain] int = noinit;
    // var y_D : [local_y_domain] int = noinit;
    // var x_1_D : [local_x1_domain] int = noinit;
    // var y_1_D : [local_y1_domain] int = noinit;
    // var x_a_D : [local_x_area_domain] int = noinit;
    // var y_a_D : [local_y_area_domain] int = noinit;
    // var m_i_D : [local_max_iter_domain] int = noinit;

    // var left: int;
    // var right: int;
    // var bottom: int;
    // var top: int;
    
    // var dt_init: real;
    // var neighbours: [num_face_domain] (int, int) = noinit;
    // var density: [local_Domain] real = noinit; 
    // var density0: [local_Domain] real = noinit;
    // var energy: [local_Domain] real = noinit;
    // var energy0: [local_Domain] real = noinit;

    // var u: [local_Domain] real = noinit;
    // var u0: [local_Domain] real = noinit;
    // var p: [local_Domain] real = noinit;
    // var r: [local_Domain] real = noinit;
    // var mi: [local_Domain] real = noinit;
    // var w: [local_Domain] real = noinit;
    // var kx: [local_Domain] real = noinit;
    // var ky: [local_Domain] real = noinit;
    // var sd: [local_Domain] real = noinit;

    // var cell_x: [local_x_domain] real = noinit;
    // var cell_dx: [local_x_domain] real = noinit;
    // var cell_y: [local_y_domain] real = noinit;
    // var cell_dy: [local_y_domain] real = noinit;

    // var vertex_x: [local_x1_domain] real = noinit;
    // var vertex_dx: [local_x1_domain] real = noinit;
    // var vertex_y: [local_y1_domain] real = noinit;
    // var vertex_dy: [local_y1_domain] real = noinit;

    // var volume: [local_Domain] real = noinit;
    // var x_area: [local_x_area_domain] real = noinit;
    // var y_area: [local_y_area_domain] real = noinit;

    // // Cheby and PPCG  
    // var theta: real;
    // var eigmin: real;
    // var eigmax: real;

    // var cg_alphas: [local_max_iter_domain] real = noinit;
    // var cg_betas: [local_max_iter_domain] real = noinit;
    // var cheby_alphas: [local_max_iter_domain] real = noinit;
    // var cheby_betas: [local_max_iter_domain] real = noinit;



    //TYPE 2
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
      // Set new x and y
      this.x = x + halo_depth*2;
      this.y = y + halo_depth*2; 

      // Resize Domains
      this.local_Domain = {0..<this.y, 0..<this.x};
      this.local_x_domain = {0..<this.x};
      this.local_y_domain = {0..<this.y};
      this.local_x1_domain = {0..<this.x+1};
      this.local_y1_domain = {0..<this.y+1};
      this.local_x_area_domain = {0..<this.y, 0..<this.x+1};
      this.local_y_area_domain = {0..<this.y+1, 0..<this.x};
      
      // Resize blocks
      this.Domain = local_Domain dmapped Block(local_Domain);
      this.x_domain = local_x_domain dmapped Block(local_x_domain);
      this.y_domain = local_y_domain dmapped Block(local_y_domain);
      this.x1_domain = local_x1_domain dmapped Block(local_x1_domain);
      this.y1_domain = local_y1_domain dmapped Block(local_y1_domain);
      this.x_area_domain = local_x_area_domain dmapped Block(local_x_area_domain);
      this.y_area_domain = local_y_area_domain dmapped Block(local_y_area_domain);

      // Initialise arrays
      this.D = 0;
      this.x_D = 0;
      this.y_D = 0;
      this.x_1_D = 0;
      this.x_a_D = 0;
      this.y_a_D = 0;
      this.m_i_D = 0;

      // Set block indicies for arrays
      forall d in D do d = here.id;
      forall x in x_D do x = here.id;
      forall y in y_D do y = here.id;
      forall x1 in x_1_D do x1 = here.id;
      forall y1 in y_1_D do y1 = here.id;
      forall xa in x_a_D do xa = here.id;
      forall ya in y_a_D do ya = here.id;
      forall m in m_i_D do m = here.id;
    }
  }
}
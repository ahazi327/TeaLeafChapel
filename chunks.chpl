// Initialise the chunk
module chunks{
  use settings;
  //have a proc with an x and y input to use it to init a chunk with those values

  

  // Domains
  const num_face_domain = {-1..<NUM_FACES, -1..<NUM_FACES};

  record Chunk{

    var chunk_x: int;
    var chunk_y: int;
    var x: int = chunk_x;
    var y: int = chunk_y;
    
    //Domains
    var Domain : domain(2) = {0..<chunk_x, 0..<chunk_y};
    var x_domain : domain(1) = {0..<chunk_x};
    var y_domain : domain(1) = {0..<chunk_y};
    var x1_domain: domain(1)  = {0..<chunk_x+1};
    var y1_domain : domain(1) = {0..<chunk_y+1};
    var x_area_domain : domain(2) = {0..<(chunk_x+1), 0..<chunk_y};
    var y_area_domain : domain(2) = {0..<chunk_x, 0..<(chunk_y+1)};
    var max_iter_domain : domain(1) = {0..<settings.max_iters};

    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    
    var dt_init: real;
    var neighbours: [num_face_domain] (int, int);
    var density: [Domain] real; 
    var density0: [Domain] real;
    var energy: [Domain] real;
    var energy0: [Domain] real;

    var u: [Domain] real;
    var u0: [Domain] real;
    var p: [Domain] real;
    var r: [Domain] real;
    var mi: [Domain] real;
    var w: [Domain] real;
    var kx: [Domain] real;
    var ky: [Domain] real;
    var sd: [Domain] real;

    var cell_x: [x_domain] real;
    var cell_dx: [x_domain] real;
    var cell_y: [y_domain] real;
    var cell_dy: [y_domain] real;

    var vertex_x: [x1_domain] real;
    var vertex_dx: [x1_domain] real;
    var vertex_y: [y1_domain] real;
    var vertex_dy: [y1_domain] real;

    var volume: [Domain] real;
    var x_area: [x_area_domain] real;
    var y_area: [y_area_domain] real;

    // Cheby and PPCG  
    var theta: real;
    var eigmin: real;
    var eigmax: real;

    var cg_alphas: [max_iter_domain] real;
    var cg_betas: [max_iter_domain] real;
    var cheby_alphas: [max_iter_domain] real;
    var cheby_betas: [max_iter_domain] real;

    // int* neighbours; 
  }

  var chunk_var: Chunk;
  chunk_var = new Chunk();

  proc init_chunk (ref chunk_variable : [?D] Chunk, in cc : int, ref setting_var : settings.setting, const in x: int, const in y:int) {
    chunk_variable[cc].chunk_x = x + setting_var.halo_depth*2;
    chunk_variable[cc].chunk_y = y + setting_var.halo_depth*2;
    
    chunk_variable[cc].x = chunk_variable[cc].chunk_x;
    chunk_variable[cc].y = chunk_variable[cc].chunk_y; 
    
    // manually resize all domains to resize arrays
    chunk_variable[cc].Domain = {0..<chunk_variable[cc].chunk_x, 0..<chunk_variable[cc].chunk_y};
    chunk_variable[cc].x1_domain = {0..<chunk_variable[cc].chunk_x+1};
    chunk_variable[cc].y1_domain = {0..<chunk_variable[cc].chunk_y+1};
    chunk_variable[cc].x_domain = {0..<chunk_variable[cc].chunk_x};
    chunk_variable[cc].y_domain = {0..<chunk_variable[cc].chunk_y};
    chunk_variable[cc].x_area_domain = {0..<(chunk_variable[cc].chunk_x+1), 0..<chunk_variable[cc].chunk_y};
    chunk_variable[cc].y_area_domain = {0..<chunk_variable[cc].chunk_x, 0..<(chunk_variable[cc].chunk_y+1)};
    chunk_variable[cc].max_iter_domain = {0..<settings.max_iters};

    // set all values in arrays to 0 from nan
    chunk_variable[cc].u = 0;
    chunk_variable[cc].u0 = 0;
    chunk_variable[cc].p = 0;
    chunk_variable[cc].r = 0;
    chunk_variable[cc].mi = 0;
    chunk_variable[cc].w = 0;
    chunk_variable[cc].kx = 0;
    chunk_variable[cc].ky = 0;
    chunk_variable[cc].sd = 0;
    chunk_variable[cc].energy = 0;
    chunk_variable[cc].energy0 = 0;
    chunk_variable[cc].density = 0;
    chunk_variable[cc].density0 = 0;

    chunk_variable[cc].cell_x = 0;
    chunk_variable[cc].cell_dx = 0;
    chunk_variable[cc].cell_y = 0;
    chunk_variable[cc].cell_dy = 0;
    
    chunk_variable[cc].vertex_x = 0;
    chunk_variable[cc].vertex_dx = 0;
    chunk_variable[cc].vertex_y = 0;
    chunk_variable[cc].vertex_dy = 0;

    chunk_variable[cc].volume = 0;
    chunk_variable[cc].x_area = 0;
    chunk_variable[cc].y_area = 0;

    chunk_variable[cc].cg_alphas = 0;
    chunk_variable[cc].cg_betas = 0;
    chunk_variable[cc].cheby_alphas = 0;
    chunk_variable[cc].cheby_betas = 0;

    chunk_variable[cc].dt_init = setting_var.dt_init;
  }
}

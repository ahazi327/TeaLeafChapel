// Initialise the chunk
module chunks{
  use settings;
  //have a proc with an x and y input to use it to init a chunk with those values

  

  // Domains
  const num_face_domain = {0..<NUM_FACES};


  record Chunk{

    var chunk_x: int;
    var chunk_y: int;
    var x: int = chunk_x;
    var y: int = chunk_y;
    //Domains
    var Domain = {0..<chunk_x, 0..<chunk_y};  // should automatically reallocate arrays when chunk values are changed
    var x_domain = {0..<chunk_x};
    var y_domain = {0..<chunk_y};
    var x1_domain = {0..<chunk_x+1};
    var y1_domain = {0..<chunk_y+1};
    var x_area_domain = {0..<(chunk_x+1), 0..<chunk_y};
    var y_area_domain = {0..<chunk_x, 0..<(chunk_y+1)};
    var max_iter_domain = {0..<setting_var.max_iters};

    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    
    var dt_init: real;
    var neighbours: [num_face_domain] int; 
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

  proc init_chunk (ref chunk_variable : [?D] Chunk, in cc : int, ref setting_var : settings.setting, in x: int, in y:int) {
    
    chunk_variable[cc].chunk_x = x + settings.setting_var.halo_depth*2;
    chunk_variable[cc].chunk_y = y + settings.setting_var.halo_depth*2;
    chunk_variable[cc].dt_init = settings.setting_var.dt_init;
    // TODO might have to manually init all array domains and/or all arrays
  }

  proc init_states (x: int, y:int) {
     // init states
    var states_domain = {0..x, 0..y};
    var states: [states_domain] settings.state;
    states = new settings.state();
  }
     

}

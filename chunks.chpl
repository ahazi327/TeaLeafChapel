// Initialise the chunk
module chunks{
  use settings;
  //have a proc with an x and y input to use it to init a chunk with those values

  var chunk_x: int;
  var chunk_y: int;

  // Domains
  const num_face_domain = {0..<NUM_FACES};
  var Domain = {0..<chunk_x, 0..<chunk_y};  // should automatically reallocate arrays when chunk values are changed
  var states_domain = {0..chunk_x, 0..chunk_x};
  var x_domain = {0..<chunk_x};
  var y_domain = {0..<chunk_y};
  var x1_domain = {0..<chunk_x+1};
  var y1_domain = {0..<chunk_y+1};
  var x_area_domain = {0..<(chunk_x+1), 0..<chunk_y};
  var y_area_domain = {0..<chunk_x, 0..<(chunk_y+1)};
  var max_iter_domain = {0..<setting_var.max_iters};

  record Chunk{
    
    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    var x: int = chunk_x;
    var y: int = chunk_y;
    var dt_init: real;
    var neighbours: [num_face_domain] int; 
    var density: [Domain] real; // maybe use a domain var for initialising arrays
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
    // MPI comm buffers  - probably don't need mpi buffers
    // double* left_send;
    // double* left_recv;
    // double* right_send;
    // double* right_recv;
    // double* top_send;
    // double* top_recv;
    // double* bottom_send;
    // double* bottom_recv;
  }

  var chunk_var: Chunk;
  chunk_var = new Chunk();

  proc init_chunk_and_states (x: int, y:int) {
    chunk_x = x + settings.setting_var.halo_depth*2;
    chunk_y = y + settings.setting_var.halo_depth*2;

    //init chunks
    var chunk_var: Chunk;
    chunk_var = new Chunk();
    chunk_var.dt_init = settings.setting_var.dt_init;

    // init states
    var states: [states_domain] settings.state;
    states = new settings.state();
  }

}

// // Finalise the chunk
// void finalise_chunk(Chunk* chunk)
// {
//   free(chunk->neighbours);
//   free(chunk->ext);
//   free(chunk->left_send);
//   free(chunk->left_recv);
//   free(chunk->right_send);
//   free(chunk->right_recv);
//   free(chunk->top_send);
//   free(chunk->top_recv);
//   free(chunk->bottom_send);
//   free(chunk->bottom_recv);
// }

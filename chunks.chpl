// Initialise the chunk
module chunks{
  use settings;
  //have a proc with an x and y input to use it to init a chunk with those values

  var chunk_x: int;
  var chunk_y: int;

  record Chunk{
    
    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    var x: int = chunk_x;
    var y: int = chunk_y;
    var dt_init: real;
    var neighbours: [0..<NUM_FACES] int; 
    var density: [0..<chunk_x, 0..<chunk_y] real; // maybe use a domain var for initialising arrays
    var density0: [0..<chunk_x, 0..<chunk_y] real;
    var energy: [0..<chunk_x, 0..<chunk_y] real;
    var energy0: [0..<chunk_x, 0..<chunk_y] real;

    var u: [0..<chunk_x, 0..<chunk_y] real;
    var u0: [0..<chunk_x, 0..<chunk_y] real;
    var p: [0..<chunk_x, 0..<chunk_y] real;
    var r: [0..<chunk_x, 0..<chunk_y] real;
    var mi: [0..<chunk_x, 0..<chunk_y] real;
    var w: [0..<chunk_x, 0..<chunk_y] real;
    var kx: [0..<chunk_x, 0..<chunk_y] real;
    var ky: [0..<chunk_x, 0..<chunk_y] real;
    var sd: [0..<chunk_x, 0..<chunk_y] real;

    var cell_x: [0..<chunk_x] real;
    var cell_dx: [0..<chunk_x] real;
    var cell_y: [0..<chunk_y] real;
    var cell_dy: [0..<chunk_y] real;

    var vertex_x: [0..<chunk_x+1] real;
    var vertex_dx: [0..<chunk_x+1] real;
    var vertex_y: [0..<chunk_y+1] real;
    var vertex_dy: [0..<chunk_y+1] real;

    var volume: [0..<chunk_x, 0..<chunk_y] real;
    var x_area: [0..<(chunk_x+1), 0..<chunk_y] real;
    var y_area: [0..<x, 0..<(chunk_y+1)] real;

    // Cheby and PPCG  
    var theta: real;
    var eigmin: real;
    var eigmax: real;

    var cg_alphas: [0..<setting_var.max_iters] real;
    var cg_betas: [0..<setting_var.max_iters] real;
    var cheby_alphas: [0..<setting_var.max_iters] real;
    var cheby_betas: [0..<setting_var.max_iters] real;

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

  proc init_chunk_and_states (x: int, y:int) {
    chunk_x = x + settings.setting_var.halo_depth*2;
    chunk_y = y + settings.setting_var.halo_depth*2;

    //init chunks
    var chunk_var: Chunk;
    chunk_var = new Chunk();
    chunk_var.dt_init = settings.setting_var.dt_init;

    // init states
    var states: [0..chunk_var.x, 0..chunk_var.y] settings.state;
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

// Initialise the chunk
module chunks{
  import settings;
  record Chunk{
    
    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    const x: int;
    const y: int;
    var dt_init: real(64);
    var neighbours: [0..<settings.NUM_FACES] int; 
    var density: [1..4294967295] real; // unsigned long long  array size 
    var density0: [1..4294967295] real; // can reduce this to 100 * 100 as this is max grid size 
    var energy: [1..4294967295] real;
    var energy0: [1..4294967295] real;

    var u: [1..4294967295] real;
    var u0: [1..4294967295] real;
    var p: [1..4294967295] real;
    var r: [1..4294967295] real;
    var mi: [1..4294967295] real;
    var w: [1..4294967295] real;
    var kx: [1..4294967295] real;
    var ky: [1..4294967295] real;
    var sd: [1..4294967295] real;

    var cell_x: [1..4294967295] real;  // these only account for 1 dimension of the grid each, can be reduced
    var cell_dx: [1..4294967295] real;
    var cell_y: [1..4294967295] real;
    var cell_dy: [1..4294967295] real;

    var vertex_x: [1..4294967295] real;
    var vertex_dx: [1..4294967295] real;
    var vertex_y: [1..4294967295] real;
    var vertex_dy: [1..4294967295] real;

    var volume: [1..4294967295] real;
    var x_area: [1..4294967295] real;
    var y_area: [1..4294967295] real;

    // Cheby and PPCG  
    var theta: real;
    var eigmin: real;
    var eigmax: real;

    var cg_alphas: [1..4294967295] real;
    var cg_betas: [1..4294967295] real;
    var cheby_alphas: [1..4294967295] real;
    var cheby_betas: [1..4294967295] real;

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

  var states: [1..chunk_var.x*chunk_var.y] settings.state;
  states = new settings.state();

  proc init_chunk (x: int, y:int) {
    chunk_var.x  = x + settings.setting_var.halo_depth*2;
    chunk_var.y  = y + settings.setting_var.halo_depth*2;
    chunk_var.dt_init = settings.setting_var.dt_init;
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

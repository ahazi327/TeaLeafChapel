// Initialise the chunk
module chunks{
  import settings;
  record Chunk{
    
    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    var x: int;
    var y: int;
    var dt_init: real(64);
    var neighbours: [1..4294967295 * 4] int; // unsigned long long * NUM_FACES (4))
    var density: [1..4294967295] real(64); // unsigned long long  array size 
    var density0: [1..4294967295] real(64); // can reduce this to 100 * 100 as this is max grid size 
    var energy: [1..4294967295] real(64);
    var energy0: [1..4294967295] real(64);

    var u: [1..4294967295] real(64);
    var u0: [1..4294967295] real(64);
    var p: [1..4294967295] real(64);
    var r: [1..4294967295] real(64);
    var mi: [1..4294967295] real(64);
    var w: [1..4294967295] real(64);
    var kx: [1..4294967295] real(64);
    var ky: [1..4294967295] real(64);
    var sd: [1..4294967295] real(64);

    var cell_x: [1..4294967295] real(64);  // these only account for 1 dimension of the grid each, can be reduced
    var cell_dx: [1..4294967295] real(64);
    var cell_y: [1..4294967295] real(64);
    var cell_dy: [1..4294967295] real(64);

    var vertex_x: [1..4294967295] real(64);
    var vertex_dx: [1..4294967295] real(64);
    var vertex_y: [1..4294967295] real(64);
    var vertex_dy: [1..4294967295] real(64);

    var volume: [1..4294967295] real(64);
    var x_area: [1..4294967295] real(64);
    var y_area: [1..4294967295] real(64);

    // Cheby and PPCG  
    var theta: real(64);
    var eigmin: real(64);
    var eigmax: real(64);

    var cg_alphas: [1..4294967295] real(64);
    var cg_betas: [1..4294967295] real(64);
    var cheby_alphas: [1..4294967295] real(64);
    var cheby_betas: [1..4294967295] real(64);

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
  proc init_chunk (x: int, y:int) {
    var chunk_var: Chunk;
    chunk_var = new Chunk();
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


// Initialise the chunk
module chunks (x: int, y:int){
  import settings
  record Chunk{
    
    var dt_init: real;
    var left: int;
    var right: int;
    var bottom: int;
    var top: int;
    var x: int;
    var dt_init: real(64);
    var neighbours: [1..4294967295 * 4] int; // unsigned long long vs NUM_FACES (4))


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
  var chunk: Chunk;
  chunk = new Chunk;
  chunk.x  = x + setting.halo_depth*2;
  chunk.y  = y + setting.halo_depth*2;
  chunk.dt_init = setting.dt_init;

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

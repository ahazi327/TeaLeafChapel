module settings{
  
  param NUM_FIELDS: int = 6;
  // Global constants
  param MASTER: int = 0;
  param NUM_FACES: int = 4;
  param CHUNK_LEFT: int = 0;
  param CHUNK_RIGHT: int = 1;
  param CHUNK_BOTTOM: int = 2;
  param CHUNK_TOP: int = 3;
  param EXTERNAL_FACE: int = -1;
  param FIELD_DENSITY: int = 0;
  param FIELD_ENERGY0: int = 1;
  param FIELD_ENERGY1: int = 2;
  param FIELD_U: int = 3;
  param FIELD_P: int = 4;
  param FIELD_SD: int = 5;
  param CONDUCTIVITY: int = 1;
  param RECIP_CONDUCTIVITY: int = 2;
  param CG_ITERS_FOR_EIGENVALUES: int = 20;

  param ERROR_SWITCH_MAX: real = 1.0;

//come back to these later
// #define MIN(a, b) ((a < b) ? a : b)
// #define MAX(a, b) ((a > b) ? a : b)
// #define strmatch(a, b) (strcmp(a, b) == 0)
// #define sign(a,b) ((b)<0 ? -fabs(a) : fabs(a))

// Sparse Matrix Vector Product
// #define SMVP(a) \
//     (1.0 + (kx[index+1]+kx[index])\
//      + (ky[index+x]+ky[index]))*a[index]\
//      - (kx[index+1]*a[index+1]+kx[index]*a[index-1])\
//      - (ky[index+x]*a[index+x]+ky[index]*a[index-x]);

// #define GET_ARRAY_VALUE(len, buffer) \
//     temp = 0.0;\
//     for(int ii = 0; ii < len; ++ii) {\
//         temp += buffer[ii];\
//     }\
//     printf("%s = %.12E\n", #buffer, temp);

  enum Solver {JACOBI_SOLVER, CG_SOLVER, CHEBY_SOLVER, PPCG_SOLVER}
  enum Geometry {RECTANGULAR, CIRCULAR, POINT}
  class setting {   
    var test_problem_filename: string; // possibly need to change these to vars
    var tea_in_filename: string;
    var tea_out_filename: string;
    var tea_out_fps: nothing;
    var grid_x_min: real;
    var grid_y_min: real;
    var grid_x_max: real;
    var grid_y_max: real;
    var grid_x_cells: int;
    var grid_y_cells: int;
    var dt_init: real;
    var max_iters: int;
    var eps: real;
    var end_time: real;
    var rank: int;
    var end_step: real;
    var summary_frequency: int;
    // var solver: string;
    var coefficient: int;
    var error_switch: bool;
    var presteps: int;
    var eps_lim: real;
    var check_result: bool;
    var ppcg_inner_steps: int;
    var preconditioner: bool;
    var num_states: int;
    var num_chunks: int;
    var num_chunks_per_rank: int;
    var num_ranks: int;
    var halo_depth: int;
    var is_offload: bool;
    // const kernel_profile: 
    var fields_to_exchange: [0..<NUM_FIELDS] bool;
    var solver: Solver;
    var dx: real;
    var dy: real;
    // var solver: Solver;
    // const Kernal_language: bool;// not needed for now
    // not sure what the profile structs are
  }

  // record Profile  - TODO add this later when profiling

  record state { // maybe change into a record instead
    var defined: bool;
    var density: real;
    var energy: real;
    var x_min: real;
    var y_min: real;
    var x_max: real;
    var y_max: real;
    var radius: real;
    var geometry: Geometry;
  } //TODO init a copy of this into an array

  // not needed
  // var default_state: state;
  // default_state = new state();

  // default_state.defined=false;
  // default_state.density =0.0;
  // default_state.energy =0.0;
  // default_state.x_min =0.0;
  // default_state.y_min=0.0;
  // default_state.x_max =0.0;
  // default_state.x_min =0.0;
  // default_state.radius=0.0;
  // default_state.geometry=Geometry.RECTANGULAR;

  var max_iters: int;

  proc set_default_settings(ref setting_var : setting)
  {
    setting_var.test_problem_filename = "tea.problems";
    setting_var.tea_in_filename = "tea.in";
    setting_var.tea_out_filename = "tea.out";
    // setting_var.tea_out_fp = nothing;
    setting_var.grid_x_min = 0.0;
    setting_var.grid_y_min = 0.0;
    setting_var.grid_x_max = 100.0;
    setting_var.grid_y_max = 100.0;
    setting_var.grid_x_cells = 10;
    setting_var.grid_y_cells = 10;
    setting_var.dt_init = 0.1;
    setting_var.max_iters = 10000;
    setting_var.eps = 0.000000000000001;
    setting_var.end_time = 10.0;
    setting_var.end_step = 30; // revert back to max int 32 later '2147483647'
    setting_var.summary_frequency = 10;
    setting_var.solver = Solver.CG_SOLVER; //2 - cg_solver
    setting_var.coefficient = 1;
    setting_var.error_switch = false;
    setting_var.presteps = 30;
    setting_var.eps_lim = 0.00001;
    setting_var.check_result = true;
    setting_var.ppcg_inner_steps = 10;
    setting_var.preconditioner = false;
    setting_var.num_states = 0;
    setting_var.num_chunks = 1;
    setting_var.num_chunks_per_rank = 1;
    setting_var.num_ranks = 1;
    setting_var.halo_depth = 2; // TODO find out where i can override this
    setting_var.is_offload = false;

    max_iters = setting_var.max_iters;

  }

  // Resets all of the fields to be exchanged
  proc reset_fields_to_exchange(ref setting_var : setting)
  {
    // forall ii in 0..<NUM_FIELDS do 
    // {
    //   settings_var.fields_to_exchange[ii] = 0;
    // }
    setting_var.fields_to_exchange[0..<NUM_FIELDS] = false;
  }

  // Checks if any of the fields are to be exchanged
  proc is_fields_to_exchange(ref setting_var : setting)
  {
    var flag : bool = false;
    forall ii in 0..<NUM_FIELDS with (ref flag) do 
    {
      if setting_var.fields_to_exchange[ii] then
        flag = true;
    }
    return flag;
  }
}



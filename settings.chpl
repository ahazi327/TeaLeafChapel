module settings{
  const NUM_FIELDS: int = 6;

  // Global constants
  const MASTER: int = 0;
  const NUM_FACES: int = 4;
  const CHUNK_LEFT: int = 0;
  const CHUNK_RIGHT: int = 1;
  const CHUNK_BOTTOM: int = 2;
  const CHUNK_TOP: int = 3;
  const EXTERNAL_FACE: int = -1;
  const FIELD_DENSITY: int = 0;
  const FIELD_ENERGY0: int = 1;
  const FIELD_ENERGY1: int = 2;
  const FIELD_U: int = 3;
  const FIELD_P: int = 4;
  const FIELD_SD: int = 5;
  const CONDUCTIVITY: int = 1;
  const RECIP_CONDUCTIVITY: int = 2;
  const CG_ITERS_FOR_EIGENVALUES: int = 20;

  const ERROR_SWITCH_MAX: real = 1.0;

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
    const test_problem_filename: string; // possibly need to change these to vars
    const tea_in_filename: string;
    const tea_out_filename: string;
    const tea_out_fps: void;
    const grid_x_min: real(64);
    const grid_y_min: real(64);
    const grid_x_max: real(64);
    const grid_y_max: real(64);
    const grid_x_cells: int;
    const grid_y_cells: int;
    const dt_init: real(64);
    const max_iters: int;
    const eps: real(64);
    const end_time: real(64);
    const rank: int;
    const end_step: real(64);
    const summary_frequency: int;
    // var solver: string;
    const coefficient: int;
    const error_switch: bool;
    const presteps: int;
    const eps_lim: real(64);
    const check_result: int; // maybe bool
    const ppcg_inner_steps: int;
    const preconditioner: bool;
    const num_states: int;
    const num_chunks: int;
    const num_chunks_per_rank: int;
    const num_ranks: int;
    const halo_depth: int;
    const is_offload: bool;
    // const kernel_profile: 
    var fields_to_exchange: [1..NUM_FIELDS] bool;
    var solver: Solver;
    var dx: real(64);
    var dy: real(64);
    // var solver: Solver;
    // const Kernal_language: bool;// not needed for now
    // not sure what the profile structs are
  }
  class state { // maybe change into a record instead
    var defined: bool;
    var density: real(64);
    var energy: real(64);
    var x_min: real(64);
    var y_min: real(64);
    var x_max: real(64);
    var y_max: real(64);
    var radius: real(64);
    var geometry: Geometry;
  }

  var setting_var: setting;
  setting_var = new setting();

  proc set_default_settings()
  {
    setting_var.test_problem_filename = "tea.problems";
    setting_var.tea_in_filename = "tea.in";
    setting_var.tea_out_filename = "tea.out";
    setting_var.tea_out_fp = nothing;
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
    setting_var.end_step = 2147483647;
    setting_var.summary_frequency = 10;
    setting_var.solver = 2; //2 - cg_solver
    setting_var.coefficient = 1;
    setting_var.error_switch = 0;
    setting_var.presteps = 30;
    setting_var.eps_lim = 0.00001;
    setting_var.check_result = 1;
    setting_var.ppcg_inner_steps = 10;
    setting_var.preconditioner = 0;
    setting_var.num_states = 0;
    setting_var.num_chunks = 1;
    setting_var.num_chunks_per_rank = 1;
    setting_var.num_ranks = 1;
    setting_var.halo_depth = 2;
    setting_var.is_offload = 0;
  }

  // Resets all of the fields to be exchanged
  proc reset_fields_to_exchange()
  {
    forall ii in 1..NUM_FIELDS do 
    {
      setting_var.fields_to_exchange[ii] = 0;
    }
  }

  // Checks if any of the fields are to be exchanged
  proc is_fields_to_exchange()
  {
    var flag : bool = 0;
    forall ii in 1..NUM_FIELDS do 
    {
      if setting_var.fields_to_exchange[ii] then
        flag = 1;
    }
    return flag;

    // if flag then
    //   return 1;
    // else
    //   return 0;
  }
}



module settings{
  // Global constants
  param NUM_FIELDS: int = 6;
  param MASTER: int = 0;
  param NUM_FACES: int = 4;

  const CHUNK_LEFT: (int, int) = (0, 0);
  const CHUNK_RIGHT: (int, int) = (1, 1);
  const CHUNK_BOTTOM: (int, int) = (2, 2);
  const CHUNK_TOP: (int, int) = (3, 3);
  const EXTERNAL_FACE: (int, int) = (-1, -1);

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

  enum Solver {JACOBI_SOLVER, CG_SOLVER, CHEBY_SOLVER, PPCG_SOLVER}
  enum Geometry {RECTANGULAR, CIRCULAR, POINT}
  class setting {   
    var test_problem_filename: string;
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
    var fields_to_exchange: [0..<NUM_FIELDS] bool;
    var solver: Solver;
    var dx: real;
    var dy: real;
    // const Kernal_language: bool;// not needed for now
    // not sure what the profile structs are
  }

  // record Profile  - TODO add this later when profiling

  record state {
    var defined: bool;
    var density: real;
    var energy: real;
    var x_min: real;
    var y_min: real;
    var x_max: real;
    var y_max: real;
    var radius: real;
    var geometry: Geometry;
  }

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
    setting_var.end_step = 2147483647;
    setting_var.summary_frequency = 10;
    setting_var.solver = Solver.CG_SOLVER;
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
    setting_var.halo_depth = 2;
    setting_var.is_offload = false;

    max_iters = setting_var.max_iters;

  }

  // Resets all of the fields to be exchanged
  proc reset_fields_to_exchange(ref setting_var : setting)
  {
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



  GNU nano 4.8                                                   benchmark.sh                                                             # Create a function to generate the configuration file.
generate_config() {
    cat > tea.in <<EOF
*tea
state 1 density=100.0 energy=0.0001
state 2 density=0.1 energy=25.0 geometry=rectangle xmin=0.0 xmax=1.0 ymin=1.0 ymax=2.0
state 3 density=0.1 energy=0.1 geometry=rectangle xmin=1.0 xmax=6.0 ymin=1.0 ymax=2.0
state 4 density=0.1 energy=0.1 geometry=rectangle xmin=5.0 xmax=6.0 ymin=1.0 ymax=8.0
state 5 density=0.1 energy=0.1 geometry=rectangle xmin=5.0 xmax=10.0 ymin=7.0 ymax=8.0


xmin                = 0.0
ymin                = 0.0
xmax                = 10.0
ymax                = 10.0
x_cells             = $1
y_cells             = $2

$4
use_c_kernels
check_result

eps                 = 1.0e-15
max_iters           = 5000

initial_timestep    = 0.004
end_step            = $3
end_time            = 100.0

halo_depth          = 2

ppcg_inner_steps    = 350
epslim              = 0.0001
presteps            = 20

*endtea
EOF
}

# Multiple configuration variables.
x_cells=(512 1024 4000)
y_cells=(512 1024 4000)
end_step=(20 20 10)
solver_methods=(use_jacobi use_cg use_ppcg use_chebyshev)
threads=(1 2 4 8 16 32 64)  # Change this for each machine to test scaling

# Run the program with each configuration.
num_configs=3
repeat_tests=5
num_solvers=4

num_threads=7 # Change this for each machine to match number of threads tested on 

# Get architecture details 
hostname
lscpu
# Run loop 
for ((j=0; j<$num_solvers; j++)); do
    echo "Using solver method: ${solver_methods[$j]}"
    for ((i=0; i<$num_configs; i++)); do
        generate_config "${x_cells[$i]}" "${y_cells[$i]}" "${end_step[$i]}" "${solver_methods[$j]}"
        for ((k=0; k<$num_threads; k++)); do
            echo "Configuration $((i+1)): x_cells=${x_cells[$i]}, y_cells=${y_cells[$i]}, end_step=${end_step[$i]}" "${end_step[$i]}"
            echo "$((k+1)) number of threads for Configuration $((i+1))"
            for ((h=0; h<$repeat_tests; h++)); do
                echo "Test Repeat Number: $((h+1))"
                CHPL_RT_NUM_THREADS_PER_LOCALE=${threads[$k]} ./objects/tealeaf
            done
        done
    done
    echo "Completed all configurations for solver method: ${solver_methods[$j]}"
    echo "-------------------------------------" # To add a separator for better readability
done

# Remove tea.in after execution.
# rm tea.in
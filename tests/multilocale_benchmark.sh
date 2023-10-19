#!/bin/bash  
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

use_chebyshev
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
x_cells=(4096)
y_cells=(4096)
end_step=(1)
locales=(1 2 4 8 16 32 64 128 256)

# Run the program with each configuration.
num_configs=9
repeat_tests=1

# Get architecture details 
hostname
lscpu

# Chapel only 
$CHPL_HOME/util/printchplenv.sh --all

# Run loop 
for ((i=0; i<$num_configs; i++)); do
    generate_config "${x_cells[$i]}" "${y_cells[$i]}" "${end_step[$i]}"
    echo "Configuration $((i+1)): x_cells=${x_cells[$i]}, y_cells=${y_cells[$i]}, end_step=${end_step[$i]}" "${end_step[$i]}"
    ./objects/tealeaf -nl "${locales[$i]}"
done
echo "Completed all tests"
echo "-------------------------------------" # Separator for better readability


# Remove tea.in after execution.
# rm tea.in
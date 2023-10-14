import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import mpl

# Load the data from the Excel file
df = pd.read_excel("results1D.xlsx")

# Ensure that the 'threads' column is of integer type
df['threads'].fillna(-1, inplace=True)
df['threads'] = df['threads'].astype(int)
df['threads'].replace(-1, np.nan, inplace=True)
df.sort_values(by='threads', inplace=True)

# Debug: Print unique solver methods and configurations
print("Solver Methods:", df['solver_method'].unique())
print("Configurations:", df['configuration'].unique())

# Extract unique solver methods
methods = df['solver_method'].unique()

# Example of hardcoded labels
label_map = {
    "x_cells=512, y_cells=512, end_step=20 20": "Chapel 512x512 grid",
    "x_cells=1024, y_cells=1024, end_step=20 20": "Chapel 1024x1024 grid",
    "x_cells=4000, y_cells=4000, end_step=10 10": "Chapel 4000x4000 grid",
    "x_cells=512, y_cells=512, end_step=20 20 C": "C 512x512 grid",
    "x_cells=1024, y_cells=1024, end_step=20 20 C": "C 1024x1024 grid",
    "x_cells=4000, y_cells=4000, end_step=10 10 C": "C 4000x4000 grid",
    "x_cells=1024, y_cells=1024, end_step=20 20 1D": "Chapel 1D 1024x1024 grid",
}

# Define your preferred order of configurations
config_order = [
    "x_cells=512, y_cells=512, end_step=20 20",
    "x_cells=1024, y_cells=1024, end_step=20 20",
    "x_cells=4000, y_cells=4000, end_step=10 10",
    "x_cells=1024, y_cells=1024, end_step=20 20 1D",
    "x_cells=512, y_cells=512, end_step=20 20 C",
    "x_cells=1024, y_cells=1024, end_step=20 20 C",
    "x_cells=4000, y_cells=4000, end_step=10 10 C",
]

for method in methods:
    plt.figure(figsize=(12, 6))
    
    # Sort configurations based on the predefined order
    unique_configs = df['configuration'].unique()
    configs = sorted(unique_configs, key=lambda x: config_order.index(x) if x in config_order else len(config_order))

    for config in configs:
        if pd.isna(config):  # Skip NaN configurations
            continue
        
        threads = df[(df['solver_method'] == method) & (df['configuration'] == config)]['threads'].unique()
        avg_times = []

        for t in threads:
            subset_df = df[(df['solver_method'] == method) & (df['configuration'] == config) & (df['threads'] == t)]
            
            # Debug: Print subset data
            print(subset_df)
            
            avg_times.append(subset_df['median_total_time'].mean())

        # Debug: Print threads and avg_times
        print("Threads:", threads)
        print("Average Times:", avg_times)

        valid_data = [(int(t), a) for t, a in zip(threads, avg_times) if not np.isnan(t) and not np.isnan(a)]

        if valid_data:  # Only continue if there's any valid data
            filtered_threads, filtered_avg_times = zip(*valid_data)
            label_name = label_map.get(config, config)
            plt.plot(range(len(filtered_threads)), filtered_avg_times, marker='o', label=label_name)

    min_pow_10 = int(np.log10(df['median_total_time'].min()))
    max_pow_10 = int(np.log10(df['median_total_time'].max()))
    major_ticks = [10**i for i in range(min_pow_10, max_pow_10+1)]

    plt.yticks(major_ticks)
    plt.gca().yaxis.set_minor_formatter(mpl.ticker.NullFormatter())
    plt.gca().yaxis.set_major_formatter(mpl.ticker.ScalarFormatter())

    plt.yscale('log')
    plt.xticks(range(len(filtered_threads)), filtered_threads)
    plt.xlabel('Threads')
    plt.ylabel('Wallclock (s)')
    plt.legend(loc='upper left', bbox_to_anchor=(1,1))
    plt.grid(True, which="both", ls="--")
    plt.title(f'{method} Explorer Time-to-solution')
    plt.tight_layout()

    # Save the figure with some padding on the right for the legend
    plt.savefig(f'benchmark_results_{method}.png', bbox_inches='tight')

print("Graphs saved successfully!")
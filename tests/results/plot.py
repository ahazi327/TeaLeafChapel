import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load the data from both Excel files
chapel_df = pd.read_excel("results.xlsx")
c_df = pd.read_excel("c_results.xlsx")

# Add a new column to each dataframe to distinguish the source (Chapel vs C)
chapel_df['source'] = 'Chapel'
c_df['source'] = 'C'

# Combine the two dataframes
df = pd.concat([chapel_df, c_df], ignore_index=True)

# Ensure that the 'threads' column is of integer type
df['threads'].fillna(-1, inplace=True)
df['threads'] = df['threads'].astype(int)
df['threads'].replace(-1, np.nan, inplace=True)
df.sort_values(by='threads', inplace=True)

# Extract unique solver methods
methods = df['solver_method'].unique()

for method in methods:
    plt.figure(figsize=(12, 6))

    for source in ['Chapel', 'C']:
        configs = df[df['source'] == source]['configuration'].unique()

        for config in configs:
            threads = df[(df['solver_method'] == method) & (df['configuration'] == config) & (df['source'] == source)]['threads'].unique()
            avg_times = []

            for t in threads:
                subset_df = df[(df['solver_method'] == method) & (df['configuration'] == config) & (df['threads'] == t) & (df['source'] == source)]
                avg_times.append(subset_df['avg_total_time'].mean())

            valid_data = [(int(t), a) for t, a in zip(threads, avg_times) if not np.isnan(t) and not np.isnan(a)]

            if valid_data:  # Only continue if there's any valid data
                filtered_threads, filtered_avg_times = zip(*valid_data)
                label_name = f"{config} ({source})"
                plt.plot(range(len(filtered_threads)), filtered_avg_times, marker='o', label=label_name)

                for i, txt in enumerate(filtered_avg_times):
                    plt.annotate(f"{txt:.2f}", (i, filtered_avg_times[i]))

    plt.yscale('log')
    plt.xticks(range(len(filtered_threads)), filtered_threads)  # Set x-ticks to be every thread value
    plt.xlabel('Threads')
    plt.ylabel('Wallclock (s)')
    plt.legend(loc='upper left', bbox_to_anchor=(1,1))
    plt.grid(True, which="both", ls="--")
    plt.title(f'{method} Explorer Time-to-solution')
    plt.tight_layout()

    # Save the figure with some padding on the right for the legend
    plt.savefig(f'benchmark_results_{method}.png', bbox_inches='tight')

print("Graphs saved successfully!")

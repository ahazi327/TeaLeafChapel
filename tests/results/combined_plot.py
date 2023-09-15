import pandas as pd
import matplotlib.pyplot as plt

# Load data from Excel
df = pd.read_excel("results.xlsx")

# Remove NaN entries in 'configuration' column
df = df.dropna(subset=['configuration'])

# Get unique configurations
unique_configs = df['configuration'].unique()

# Create plots for each unique configuration
for config in unique_configs:
    # Filter dataframe based on current configuration
    subset_df = df[df['configuration'] == config]
    
    # Plot results for each solver
    for solver in subset_df['solver_method'].unique():
        solver_data = subset_df[subset_df['solver_method'] == solver]
        if not solver_data.empty:  # Check if there's data to plot
            plt.plot(solver_data['threads'], solver_data['avg_total_time'], label=solver, marker='o')
    
    # Styling the plot
    plt.title(f"Results for Configuration: {config}")
    plt.xlabel('Threads')
    plt.ylabel('Average Total Time')
    plt.xscale('log')
    plt.grid(True, which="both", ls="--", c='0.65')
    
    # Add legend only if there are labels to display
    if len(plt.gca().get_legend_handles_labels()[0]) > 0:
        plt.legend()
    
    # Save the plot to a file
    filename = f"graph_for_{str(config).replace(',', '_').replace(' ', '_')}.png"
    plt.savefig(filename)
    
    # Clear the current figure for the next plot
    plt.clf()  

print("Graphs saved successfully!")

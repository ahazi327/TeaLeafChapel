import re
import pandas as pd
import numpy as np

# Path to your output text file and the Excel file to save the results
input_file = "benchmarkTeaLeafChapelexplorer.out"
output_file = "results.xlsx"

# Patterns to search for in the output
patterns = {
    'solver_method': r"Using the (.+)",
    'configuration': r"Configuration \d+: (.+)",
    'threads': r"(\d+) threads for Configuration",
    'test_repeat': r"Test Repeat Number: (\d+)",
    'total_time': r"Total time elapsed: ([\d.]+) seconds",
    'expected': r"Expected: \n([\d.]+)",
    'actual': r"Actual: \n([\d.]+)"
}

# Read the file and extract the relevant information
with open(input_file, 'r') as f:
    content = f.read()

# Extract the runs
runs = content.split("End of Run")

data = []

# Iterate over each run and extract the relevant data
for run in runs:
    if not run.strip():
        continue

    info = {}
    for key, pattern in patterns.items():
        match = re.search(pattern, run)
        if match:
            info[key] = match.group(1)
    
    if 'expected' in info and 'actual' in info:
        try:
            info['error'] = float(info['actual']) - float(info['expected'])
        except:
            info['error'] = None

    data.append(info)

# Convert the data to a DataFrame
df = pd.DataFrame(data)

# Convert specific columns to their respective data types
df['total_time'] = df['total_time'].astype(float)

# Handle NaN values in test_repeat for conversion
placeholder = -1  # Define a placeholder value that doesn't clash with your data
df['test_repeat'].fillna(placeholder, inplace=True)
df['test_repeat'] = df['test_repeat'].astype(int)
df['test_repeat'].replace(placeholder, np.nan, inplace=True)

# Compute the median for total_time over the next 4 rows where test_repeat is 1
df['median_total_time'] = [df.iloc[i:i+5]['total_time'].median() if val == 1 else None for i, val in enumerate(df['test_repeat'])]

df.to_excel(output_file, index=True)

print("Results parsed successfully!")

import re
import pandas as pd
import numpy as np

# Path to your output text file and the Excel file to save the results
input_file = "benchmark_TeaLeafOMP_zenith.out"
output_file = "c_results.xlsx"

# Patterns to search for in the output
patterns = {
    'test_repeat': r"Test Repeat Number: (\d+)",
    'total_time': r"Total elapsed time: ([\d.]+)"
}

# Read the file and extract the relevant information
with open(input_file, 'r') as f:
    content = f.read()

# Extract the runs
runs = content.split("End of Run")

data = []

# Safely access list data
def safe_access(lst, idx):
    try:
        return lst[idx]
    except IndexError:
        return None

# Iterate over each run and extract the relevant data
for run in runs:
    if not run.strip():
        continue

    info = {}
    for key, pattern in patterns.items():
        matches = re.findall(pattern, run)
        if matches:
            info[key] = matches

    # Determine the maximum number of matches among all patterns
    max_matches = max(len(info.get('test_repeat', [])), len(info.get('total_time', [])))

    # Iterate through the maximum number of matches
    for i in range(max_matches):
        data_entry = {
            'test_repeat': safe_access(info.get('test_repeat', []), i),
            'total_time': safe_access(info.get('total_time', []), i)
        }
        data.append(data_entry)

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

df.to_excel(output_file, index=False)

print("Results parsed successfully!")

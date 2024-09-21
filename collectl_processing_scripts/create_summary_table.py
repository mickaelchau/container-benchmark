import pandas as pd
import os

def process_csv(file_path):
    # Extracting command, concurrency, and count from the file name
    file_name = os.path.basename(file_path)
    file_parts = file_name.replace(".csv", "").split("_")
    command_end_index = file_parts.index('command')
    command = '_'.join(file_parts[:command_end_index])
    
    concurrency = int(file_parts[command_end_index + 1])
    count = int(file_parts[command_end_index + 2])

    # Read the CSV into a DataFrame
    df = pd.read_csv(file_path, sep=';')

    # Compute mean of [CPU]Totl% excluding 0%
    cpu_column = '[CPU]Totl%'
    cpu_mean_excluding_zero = df[df[cpu_column] > 0][cpu_column].mean()

    # Compute mean of [MEM]Used
    mem_column = '[MEM]Used'
    mem_mean = df[mem_column].mean()
    
    # Compute sum of [DSK]ReadKBTot and [DSK]WriteKBTot
    dsk_read_column = '[DSK]ReadKBTot'
    dsk_write_column = '[DSK]WriteKBTot'
    disk_sum = df[dsk_read_column].sum() + df[dsk_write_column].sum()
    
    # Return the row data
    return {
        "concurrency": concurrency,
        "count": count,
        "command": command,
        "Mean [CPU]Totl% excluding 0%": cpu_mean_excluding_zero,
        "Mean [MEM]Used": mem_mean,
        "sum(Disk Read + Write KB)": disk_sum
    }

def create_summary_table(logs_dir):
    table_data = []

    # Process each file and gather data.
    for root, dirs, files in os.walk(logs_dir):
        for file in files:
            if file.endswith(".csv"):
                file_path = os.path.join(root, file)
                print(f"Processing file: {file_path}")
                row = process_csv(file_path)
                table_data.append(row)
        
    # Convert data to a pandas dataframe.
    summary_df = pd.DataFrame(table_data, columns=["concurrency", "count", "command", 
                                                   "Mean [CPU]Totl% excluding 0%", 
                                                   "Mean [MEM]Used", 
                                                   "sum(Disk Read + Write KB)"])
    return summary_df.sort_values(by=['command', 'concurrency', 'count'], ascending=[True, True, True])

logs_dirs = ["docker", "lxc", "podman"]

# Call the function to create the summary table for each container engine.
for logs_dir in logs_dirs:
    summary_table = create_summary_table(".\\" + logs_dir)
    summary_table.to_csv(logs_dir + '_summary.csv', index=False)
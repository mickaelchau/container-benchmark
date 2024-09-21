import pandas as pd
import os

def keep_wanted_columns(file_path, wanted_columns):
    # Load the file into a pandas DataFrame with semicolon as the delimiter
    df = pd.read_csv(file_path, sep=';')

    # Keep only the specified columns
    df_filtered = df[wanted_columns]

    # Save the filtered DataFrame back to the file (optional, if you want to overwrite the original file)
    df_filtered.to_csv(file_path, sep=';', index=False)

    # Return the filtered DataFrame
    return df_filtered

def process_tab_files_in_logs_dir(logs_dir):
    for root, dirs, files in os.walk(logs_dir):
        for file in files:
            if file.endswith(".tab"):
                file_path = os.path.join(root, file)
                print(f"Processing file: {file_path}")
                keep_wanted_columns(file_path, wanted_columns)

# Define the logs directory and wanted columns.
wanted_columns = ['[CPU]Totl%', '[MEM]Used', '[DSK]ReadKBTot', '[DSK]WriteKBTot']
logs_dir = "."

# Call the function to process the files
process_tab_files_in_logs_dir(logs_dir)
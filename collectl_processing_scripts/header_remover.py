import os

def remove_header_from_tab_file(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()

    # Find the index where actual data starts (after header).
    data_start_index = 0
    for i, line in enumerate(lines):
        if not line.startswith("#"):
            data_start_index = i
            break

    # Data start index is decremented to keep columns header.
    data_start_index -= 1

    # Write only the data lines (i.e., lines after the header) back to the file
    with open(file_path, 'w') as f:
        f.writelines(lines[data_start_index:])

def process_tab_files_in_logs_dir(logs_dir):
    for root, dirs, files in os.walk(logs_dir):
        for file in files:
            if file.endswith(".tab"):
                file_path = os.path.join(root, file)
                print(f"Processing file: {file_path}")
                remove_header_from_tab_file(file_path)

# Define the logs directory
logs_dir = "."

# Call the function to process the files
process_tab_files_in_logs_dir(logs_dir)
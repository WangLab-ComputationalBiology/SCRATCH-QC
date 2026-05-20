#!/usr/bin/env python3

####!/opt/conda/bin/python

import os
import sys
import re

def is_already_10x_format(sample_name, filename):
    """
    Determine if the filename matches the expected 10x Genomics format.
    {sample_name}_S\d+_L\d{3}_R[12]_001\.fastq\.gz

    Args:
        filename (str): The name of the file to check.
        sample_name (str): The sample name to use in the format check.

    Returns:
        bool: True if filename matches the 10x Genomics format, False otherwise.
    """

    pattern = re.compile(rf'^{re.escape(sample_name)}_S\d+_L\d{{3}}_R[12]_001.fastq.gz$')
    return pattern.match(filename)

def rename_fastqs(sample_name, fastq_dir):
    """
    Renames FASTQ files in the specified directory based on the sample name provided.

    Args:
        fastq_dir (str): Directory containing the FASTQ files.
        sample_name (str): Sample name to use in the new filename.
    Returns:
        string: Rename files
    """
    # Iterate over all files in the directory
    for filename in os.listdir(fastq_dir):
        if filename.endswith(".fastq.gz"):

            if not is_already_10x_format(sample_name, filename):
                
                print(f"Renaming {sample_name} {filename}")
                
                # Splitting the filename to extract parts
                parts = filename.split('_')

                # Extract pair number from the part before the ".fastq.gz"
                part_before_extension = parts[-1].split('.')[0]
                pair_number = part_before_extension[-1]

                # Creating string based on 10x format
                new_filename = f"{sample_name}_S1_L001_R{pair_number}_001.fastq.gz"

                # Renaming the file
                old_path = os.path.join(fastq_dir, filename)
                new_path = os.path.join(fastq_dir, new_filename)
                os.rename(old_path, new_path)
                
            else:
                print(f"This is 10x ready {filename}")

if __name__ == "__main__":
    sample_name, fastq_dir = sys.argv[1], sys.argv[2]
    rename_fastqs(sample_name, fastq_dir)



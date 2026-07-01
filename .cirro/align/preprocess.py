#!/usr/bin/env python3

from cirro.helpers.preprocess_dataset import PreprocessDataset
import pandas as pd
import os

def samplesheet_creation(ds: PreprocessDataset) -> pd.DataFrame:
    REQUIRED_COLUMNS = ["sample", "modality", "patient_id"]
    OPTIONAL_COLUMNS = ["timepoint", "batch"]

    available_optional = [c for c in OPTIONAL_COLUMNS if c in ds.samplesheet.columns]
    META_COLUMNS = REQUIRED_COLUMNS + available_optional

    ds.logger.info("Pivoting samplesheet:")

    sample_table = ds.pivot_samplesheet(
        index=["sampleIndex", "sample", "lane"],
        pivot_columns="read",
        metadata_columns=META_COLUMNS,
        column_prefix="fastq_"
    ).sort_values(by="sample")

    ds.logger.info("Checking transposed columns:")
    ds.logger.info(sample_table.columns)
    ds.logger.info(sample_table.to_csv(index=None))

    return sample_table

def setup_input_parameters(ds: PreprocessDataset):
    # Set alignment mode
    alignment_mode = ds.params.get("alignment_mode")
    ds.add_param("multi", alignment_mode == "multi")
    ds.add_param("demux", alignment_mode == "demux")
    ds.remove_param("alignment_mode")

    # Adding new samplesheet including modality
    ds.logger.info("Changing samplesheet dynamically:")

    if ds.params.get("samplesheet") is None:
        ds.add_param(
            "samplesheet",
            "${launchDir}/samplesheet.csv"
        )

if __name__ == "__main__":

    ds = PreprocessDataset.from_running()

    ds.logger.info("Exported paths:")
    ds.logger.info(os.environ['PATH'])

    ds.logger.info("Files annotated in the dataset:")
    ds.logger.info(ds.files)

    ds.logger.info("Checking metadata:")
    ds.logger.info(ds.samplesheet.columns)
    ds.logger.info(ds.samplesheet)

    ds.logger.info("Getwd/LaunchDir directory:")
    ds.logger.info(os.getcwd())

    ds.logger.info("List workdir directory:")
    ds.logger.info(os.listdir("."))

    # Make a sample table of the input data
    sample_table = samplesheet_creation(ds)
    sample_table.to_csv("samplesheet.csv", index=None)

    setup_input_parameters(ds)

    ds.logger.info("Printing out parameters:")
    ds.logger.info(ds.params)


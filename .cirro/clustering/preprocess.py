#!/usr/bin/env python3

from cirro.helpers.preprocess_dataset import PreprocessDataset
import pandas as pd
import os

def setup_input_parameters(ds: PreprocessDataset):

    # If the user did not select a custom malignant table, use the default
    if ds.params.get("input_cell_mask") is None:
        ds.add_param(
            "input_cell_mask",
            "${baseDir}/assets/NO_FILE"
        )

if __name__ == "__main__":

    ds = PreprocessDataset.from_running()
    setup_input_parameters(ds)

    ds.logger.info("Standard Cirro's samplesheet:")
    ds.logger.info(ds.samplesheet)

    ds.logger.info("Exported paths:")
    ds.logger.info(os.environ['PATH'])

    ds.logger.info("Printing out parameters:")
    ds.logger.info(ds.params)
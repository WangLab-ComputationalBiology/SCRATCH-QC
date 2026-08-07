#!/usr/bin/env python3

from cirro.helpers.preprocess_dataset import PreprocessDataset
import pandas as pd
import posixpath
import os

# The filtered-matrix h5 is named `filtered_feature_bc_matrix.h5` by cellranger
# count and `sample_filtered_feature_bc_matrix.h5` by cellranger multi. Both end
# with this suffix, so an endswith() match catches either.
H5_SUFFIX = "filtered_feature_bc_matrix.h5"
METRICS_NAME = "metrics_summary.csv"


def metrics_path_for(h5_path: str) -> str:
    """
    Locate metrics_summary.csv relative to a filtered-matrix h5, handling both
    aligner layouts:

      cellranger count : <sample>/outs/filtered_feature_bc_matrix.h5
                         <sample>/outs/metrics_summary.csv          (beside the h5)

      cellranger multi : <sample>/count/sample_filtered_feature_bc_matrix.h5
                         <sample>/metrics_summary.csv               (parent of count/)
    """
    h5_dir = posixpath.dirname(h5_path)
    if posixpath.basename(h5_dir) == "count":
        # cellranger multi: metrics lives one level up, outside the count/ dir
        return posixpath.join(posixpath.dirname(h5_dir), METRICS_NAME)
    # cellranger count (outs/) or any flat layout: metrics sits beside the h5
    return posixpath.join(h5_dir, METRICS_NAME)


def samplesheet_creation(ds: PreprocessDataset) -> pd.DataFrame:
    """
    Build ONE samplesheet covering every annotated sample, regardless of which
    source-dataset prefix its matrices live under.

    Why this exists
    ---------------
    The process-input.json template derives `input_gex_matrices_path` from
    `inputs[0].s3` — the S3 location of the *first* input dataset only — plus a
    `**/outs/*` glob. When the input references matrices spread across several
    source datasets, that single-prefix glob can only ever match the matrices
    under one dataset UUID, so the rest are silently dropped from QC.

    `ds.files` annotates every h5 across all inputs, so we build an explicit
    list instead of relying on a single-prefix wildcard.

    Notes
    -----
    * Cirro annotates only the h5 per sample (not metrics_summary.csv), so the
      metrics path is derived from the h5 (see metrics_path_for for the count
      vs multi layouts).
    * Metadata columns from ds.samplesheet are joined on `sample`; the same sheet
      is consumed by SEURAT_MERGE (path columns are dropped inside the notebook).
    """
    files = ds.files.copy()

    # One row per sample with its h5 path (matches both count and multi h5 names).
    matrices = (
        files[files["file"].str.endswith(H5_SUFFIX)]
        .loc[:, ["sample", "file"]]
        .rename(columns={"file": "h5"})
        .drop_duplicates(subset="sample")
    )

    # metrics_summary.csv location depends on the aligner layout (see metrics_path_for).
    matrices["metrics_csv"] = matrices["h5"].apply(metrics_path_for)

    # Attach metadata (joined by sample). Left join keeps every matrix even if
    # a sample has no metadata row.
    metadata = ds.samplesheet.copy()
    samplesheet = matrices.merge(metadata, on="sample", how="left").sort_values(by="sample")

    # Flag any samples that failed to pick up metadata.
    meta_cols = [c for c in metadata.columns if c != "sample"]
    if meta_cols:
        missing = samplesheet.loc[samplesheet[meta_cols].isna().all(axis=1), "sample"].tolist()
        if missing:
            ds.logger.info(f"WARNING: {len(missing)} sample(s) have no metadata: {missing}")

    # Required columns first, then any metadata columns.
    lead = ["sample", "h5", "metrics_csv"]
    samplesheet = samplesheet[lead + [c for c in samplesheet.columns if c not in lead]]

    ds.logger.info("QC samplesheet columns:")
    ds.logger.info(samplesheet.columns)
    ds.logger.info(f"QC samplesheet rows: {len(samplesheet)}")
    ds.logger.info(samplesheet.to_csv(index=None))

    return samplesheet


def setup_input_parameters(ds: PreprocessDataset):
    # Point the workflow at the explicit samplesheet instead of the glob.
    ds.add_param("input_samplesheet", "${launchDir}/samplesheet.csv")

    # Drop the single-prefix params so the deprecated glob cannot take effect.
    for stale in ("input_gex_matrices_path", "input_exp_table"):
        if ds.params.get(stale) is not None:
            ds.remove_param(stale)


if __name__ == "__main__":

    ds = PreprocessDataset.from_running()

    ds.logger.info("Exported paths:")
    ds.logger.info(os.environ['PATH'])

    ds.logger.info("Files annotated in the dataset:")
    ds.logger.info(ds.files)

    ds.logger.info("Checking metadata:")
    ds.logger.info(ds.samplesheet.columns)

    ds.logger.info("Getwd/LaunchDir directory:")
    ds.logger.info(os.getcwd())

    ds.logger.info("List workdir directory:")
    ds.logger.info(os.listdir("."))

    # Build a single samplesheet of ALL annotated samples and point at it.
    samplesheet = samplesheet_creation(ds)
    samplesheet.to_csv("samplesheet.csv", index=None)

    setup_input_parameters(ds)

    ds.logger.info("Printing out parameters:")
    ds.logger.info(ds.params)

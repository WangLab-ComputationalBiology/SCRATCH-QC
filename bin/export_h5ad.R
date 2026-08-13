#!/usr/bin/env Rscript
# Stream a BPCells-backed Seurat object to a single self-contained .h5ad.
# The counts matrix is written straight from the on-disk BPCells store via
# BPCells' AnnData writer (never realized in memory -> no 2.1B ceiling); the
# per-cell metadata (obs) and gene names (var) are attached with hdf5r using
# AnnData's dataframe encoding, so the file opens cleanly in both scanpy
# (Python) and BPCells/anndata (R).
suppressMessages({library(BPCells); library(hdf5r)})

args <- commandArgs(trailingOnly = TRUE)
get <- function(flag, default = NULL) {
  i <- which(args == flag)
  if (length(i)) args[i + 1] else default
}
rds   <- get("--rds")
store <- get("--store", "data/bpcells_counts")
out   <- get("--out")
stopifnot(!is.null(rds), !is.null(out))

obj  <- readRDS(rds)
mat  <- BPCells::open_matrix_dir(store)          # genes x cells, lazy/on-disk

# Align metadata to the matrix's cell order.
meta <- obj@meta.data
meta <- meta[colnames(mat), , drop = FALSE]

# Stream the counts to X (+ obs/var index datasets named 'bpcells_name').
if (file.exists(out)) unlink(out)
BPCells::write_matrix_anndata_hdf5(mat, out)

# Attach obs columns using AnnData dataframe encoding.
f   <- H5File$new(out, mode = "r+")
obs <- f[["obs"]]

# AnnData requires encoding-type/encoding-version as SCALAR string attributes
# (a length-1 array trips the Python reader with 'unhashable type: ndarray').
set_scalar_str <- function(h5obj, name, value) {
  if (h5obj$attr_exists(name)) h5obj$attr_delete(name)
  a <- h5obj$create_attr(name, robj = value, space = H5S$new("scalar"))
  a$close()
}

add_col <- function(grp, name, values) {
  if (grp$exists(name)) grp$link_delete(name)
  if (is.numeric(values)) {
    grp[[name]] <- as.double(values)
    set_scalar_str(grp[[name]], "encoding-type", "array")
  } else {
    v <- as.character(values)
    v[is.na(v)] <- "NA"
    grp[[name]] <- v
    set_scalar_str(grp[[name]], "encoding-type", "string-array")
  }
  set_scalar_str(grp[[name]], "encoding-version", "0.2.0")
}

cols <- colnames(meta)
for (cn in cols) add_col(obs, cn, meta[[cn]])

# column-order lists the data columns (not the index).
if (obs$attr_exists("column-order")) obs$attr_delete("column-order")
h5attr(obs, "column-order") <- cols

f$close_all()
cat(sprintf("Wrote %s: %d genes x %d cells, %d obs columns\n",
            out, nrow(mat), ncol(mat), length(cols)))

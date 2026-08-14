# Opening the SCRATCH-QC `.h5ad` objects (R + Python)

SCRATCH-QC exports two self-contained AnnData `.h5ad` files (produced by
[`export_h5ad.R`](./export_h5ad.R)):

| File | Contents |
|------|----------|
| `<project>_merged.h5ad`  | All QC-passing cells from all samples, merged — **doublets still included** |
| `<project>_singlet.h5ad` | Same object with **doublets removed** (only singlets); adds `class` + `scdbl_score` |

Both hold the raw counts (`X`), per-cell metadata (`obs`: `orig.ident`,
`patient_id`, `percent_mito`, …) and gene names (`var`). For most downstream
analysis, use the **singlet** file.

---

## ⚠️ One thing to know first: the R in-memory ceiling

R's standard sparse matrix (`dgCMatrix`) indexes stored values with a **32-bit
integer**, so it cannot hold more than **2,147,483,647 (~2.1 billion) non-zero
entries** (≈ 700k–1M cells). The `.h5ad` file itself has **no such limit** — it
uses 64-bit HDF5 — but **how you load it in R decides whether you hit the wall**:

- **Load lazily via BPCells** → the matrix stays on disk and streams → **no limit, any cohort size.**
- **Load fully into memory** (`zellkonverter::readH5AD`, `schard`, `anndata` → dense/sparse) → rebuilds a `dgCMatrix` → **fails for large cohorts (> ~1M cells).**

Python has no equivalent limit (`scipy` uses 64-bit indices), so Python users can
load the file any way they like.

| How you open it | Small cohort (< ~1M cells) | Full cohort (> ~1M cells) |
|---|---|---|
| Python / scanpy | ✅ | ✅ |
| R — BPCells (lazy) | ✅ | ✅ |
| R — `zellkonverter::readH5AD` (in-memory) | ✅ | ❌ hits ceiling |
| Metadata/summary only (`backed` / `hdf5r`) | ✅ | ✅ |

---

## Python (scanpy / anndata)

```python
import anndata as ad

# Full load — fine at any size (scipy is 64-bit)
a = ad.read_h5ad("project_singlet.h5ad")
print(a)                                   # cells x genes, obs/var
print(a.obs['orig.ident'].value_counts())  # cells per sample

# Metadata-only summary (instant, never loads the matrix)
a = ad.read_h5ad("project_singlet.h5ad", backed="r")
print("cells:", a.n_obs, "genes:", a.n_vars,
      "samples:", a.obs['orig.ident'].nunique())
a.file.close()
```

## R — the right way (BPCells, lazy, no ceiling)

```r
library(BPCells); library(Seurat); library(hdf5r)

path <- "project_singlet.h5ad"

# 1. Counts: on-disk, nothing realized
mat <- open_matrix_anndata_hdf5(path)

# 2. Metadata (obs): read directly with hdf5r
f    <- H5File$new(path, mode = "r")
obs  <- f[["obs"]]
idx  <- h5attr(obs, "_index")
cols <- setdiff(names(obs), idx)
meta <- as.data.frame(setNames(lapply(cols, function(c) obs[[c]][]), cols),
                      stringsAsFactors = FALSE)
rownames(meta) <- obs[[idx]][]
f$close_all()

# 3. Build a Seurat v5 object; all ops stream from disk
obj <- CreateSeuratObject(counts = mat, meta.data = meta)
obj <- NormalizeData(obj)
obj <- FindVariableFeatures(obj)
obj <- ScaleData(obj)
obj <- RunPCA(obj)                         # no 2.1B limit

table(obj$orig.ident)                       # cells per sample
```

### R — small cohorts only (simplest, but realizes the matrix)

Fine when the object is well under ~1M cells; **do not use on the full cohort.**

```r
library(zellkonverter)
sce <- readH5AD("project_singlet.h5ad")     # -> SingleCellExperiment (in memory)
```

---

## Quick metadata summary from R (no matrix, any size)

```r
library(hdf5r)
f    <- H5File$new("project_singlet.h5ad", "r")
obs  <- f[["obs"]]; idx <- h5attr(obs, "_index")
cols <- setdiff(names(obs), idx)
meta <- as.data.frame(setNames(lapply(cols, function(c) obs[[c]][]), cols))
rownames(meta) <- obs[[idx]][]; f$close_all()

cat("Total cells  :", nrow(meta), "\n")
cat("Total samples:", length(unique(meta$orig.ident)), "\n")
print(sort(table(meta$orig.ident), decreasing = TRUE))
if ("class" %in% cols) print(table(meta$class))
```

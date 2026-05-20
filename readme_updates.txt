================================================================================
SCRATCH-QC ALIGNMENT PIPELINE — CHANGE LOG
Feature: Demultiplexing support via --demux parameter
Date: 2026-05-06
================================================================================

OVERVIEW
--------
A new boolean parameter `--demux` (default: false) has been added to the
alignment pipeline (scratch_align_entry.nf). When set to true, the pipeline
runs `cellranger mkfastq` on Illumina BCL run directories before alignment,
enabling end-to-end processing from raw sequencing output to aligned matrices
in a single pipeline run.

This supports both:
  - Standard Illumina index-based library demultiplexing (multiple samples
    sequenced in the same lane, distinguished by index barcode).
  - Single-cell library demultiplexing: each 10x Genomics library (GEX, TCR)
    is demultiplexed separately from the shared BCL run using its assigned
    10x index set (e.g. SI-GA-A1) before alignment with cellranger count/vdj.


================================================================================
FILES CREATED
================================================================================

1. modules/local/cellranger/mkfastq/main.nf
   ----------------------------------------
   New Nextflow process: CELLRANGER_MKFASTQ

   - Runs `cellranger mkfastq` for one sample per process invocation.
   - Input tuple: (sample, run_dir, lane, index, modality)
       * run_dir is passed as a val (string), NOT a path, to avoid staging
         large BCL directories (which can be hundreds of GB) into the work dir.
       * lane accepts a lane number (e.g. "1") or "*" for all lanes.
       * index accepts 10x index sets (SI-GA-A1) or bare sequences (ATCG).
   - Internally generates a simple CSV (Lane,Sample,Index) and calls:
       cellranger mkfastq --run=<run_dir> --id=<sample> --csv=simple.csv
   - Output tuple: (sample, path("sample/outs/fastq_path"), modality)
       * The fastq_path directory (containing the demultiplexed FASTQs) is
         staged by Nextflow as "fastq_path/" in downstream work directories.
   - Includes a stub block for dry-run testing (creates empty placeholder files).
   - Uses the same container as count/vdj: syedsazaidi/scratch-cellranger8:latest
   - Labelled process_high (same resources as count/vdj: 24 CPUs, 64 GB RAM).

2. modules/local/cellranger/mkfastq/meta.yml
   -------------------------------------------
   Module metadata file describing inputs, outputs, tool, and keywords
   for the new CELLRANGER_MKFASTQ process. Follows existing meta.yml convention.

3. assets/test_demux_sample_table.csv
   ------------------------------------
   Example samplesheet for demux mode. Columns:
       sample, run_dir, lane, index, modality
   Contains two placeholder rows (one GEX, one TCR) with dummy paths that
   should be replaced with real BCL run paths before use.


================================================================================
FILES MODIFIED
================================================================================

4. scratch_align_entry.nf
   -----------------------
   - Added: `demux = params.demux ?: false`
     Reads the --demux param; defaults to false if not provided.
   - Updated log.info block to display "Demux: ${demux}" alongside other params.
   - Updated SCRATCH_ALIGN() call to pass `demux` as a 4th argument.

5. nextflow.config
   ----------------
   - Added to the params block:
       demux = false
     This sets the default so --demux is always defined (avoids null errors
     when params.demux is accessed in modules.config closures).
   - Added inline documentation comment explaining the two samplesheet formats.

6. subworkflow/local/scratch_align.nf
   ------------------------------------
   - Added include for CELLRANGER_MKFASTQ at the top of the file.
   - Added `demux` to the workflow `take:` block (4th parameter).
   - Refactored the main block into two conditional paths:

   IF demux == true (DEMUX PATH):
     * Parses the validated CSV expecting columns:
         sample, run_dir, lane, index, modality
       (the lane column falls back to '*' if absent)
     * Branches rows into .gex and .tcr by modality[4]
     * Merges both branches with .mix() and calls CELLRANGER_MKFASTQ once
       (single process definition, handles all samples in parallel).
     * Re-branches mkfastq output by modality[2] (carried through from input).
     * For GEX: maps (sample, fastq_dir, mod) -> (sample, fastq_dir) and calls
       CELLRANGER_COUNT. ext.fastqs_dir='fastq_path' in modules.config makes
       count use --fastqs=fastq_path (the staged directory) instead of --fastqs=.
     * For TCR: same pattern feeding CELLRANGER_VDJ.

   IF demux == false (STANDARD PATH — unchanged original behaviour):
     * Parses the validated CSV expecting columns:
         sample, fastq_1, fastq_2, modality
     * Branches into .gex and .tcr, groups by sample (to handle multi-lane
       inputs), and feeds into CELLRANGER_COUNT / CELLRANGER_VDJ as before.

   - Fixed the GEX+TCR regex from /\b(GEX+TCR)/ to /\b(GEX\+TCR)/ in both
     branches so the literal '+' is matched correctly (the original regex was
     a latent bug where '+' was interpreted as a regex quantifier).

7. modules/local/cellranger/count/main.nf
   -----------------------------------------
   - Added Groovy variables in both `script:` and `stub:` blocks:
       def fastqs_dir = task.ext.fastqs_dir ?: '.'
       def rename_cmd = (fastqs_dir == '.') ? "cellranger_renaming.py ..." : ''
   - Changed `--fastqs=.` to `--fastqs="${fastqs_dir}"` so the process can
     accept either the work directory (standard mode) or the staged fastq_path
     directory from mkfastq (demux mode).
   - The cellranger_renaming.py step is skipped when fastqs_dir != '.' because
     mkfastq output files are already in standard cellranger naming format
     (SAMPLE_S1_L001_R1_001.fastq.gz); renaming is only needed for raw inputs.

8. modules/local/cellranger/vdj/main.nf
   ----------------------------------------
   - Same changes as count/main.nf:
       def fastqs_dir = task.ext.fastqs_dir ?: '.'
       def rename_cmd = (fastqs_dir == '.') ? "cellranger_renaming.py ..." : ''
   - Changed `--fastqs=.` to `--fastqs="${fastqs_dir}"`.
   - renaming step skipped when fastqs_dir != '.'.

9. conf/modules.config
   ---------------------
   - Added CELLRANGER_MKFASTQ block:
       publishDir -> ${outdir}/data/CELLRANGER_MKFASTQ/ (copy, overwrite)
   - Updated CELLRANGER_COUNT block:
       ext.fastqs_dir = { params.demux ? 'fastq_path' : '.' }
     The closure evaluates at runtime so setting --demux true switches the
     fastqs directory automatically without touching process code.
   - Updated CELLRANGER_VDJ block:
       ext.fastqs_dir = { params.demux ? 'fastq_path' : '.' }

10. README.md
    ----------
    - Expanded the `scratch_align_entry.nf` section to document:
        * The two operating modes (standard vs demux).
        * The new --demux parameter.
        * Both samplesheet formats with column descriptions and examples.
        * Updated usage examples for both modes.


================================================================================
HOW THE DEMUX PATH WORKS (DATA FLOW)
================================================================================

  BCL Run Directory
        |
        v
  CELLRANGER_MKFASTQ  (one process per sample, runs in parallel)
  [cellranger mkfastq --run=<run_dir> --id=<sample> --csv=<lane/sample/index>]
        |
        | outputs: sample/outs/fastq_path/   (staged as "fastq_path/" in work dir)
        v
  Branch by modality
  /                    \
GEX branch           TCR branch
  |                    |
  v                    v
CELLRANGER_COUNT    CELLRANGER_VDJ
[--fastqs=fastq_path  [--fastqs=fastq_path
 --sample=<sample>]    --sample=<sample>]
  |                    |
  v                    v
sample/outs/*       sample/outs/*
(published to       (published to
 data/CELLRANGER_    data/CELLRANGER_
 COUNT/)             VDJ/)


================================================================================
BACKWARD COMPATIBILITY
================================================================================

- When --demux is not passed (or --demux false), the pipeline behaves exactly
  as before. No changes to the standard FASTQ-input path.
- The ext.fastqs_dir closure in modules.config defaults to '.' when demux=false,
  preserving the original --fastqs=. behaviour and enabling cellranger_renaming.py.
- Existing samplesheets (sample, fastq_1, fastq_2, modality) continue to work
  without modification.


================================================================================
NOTES FOR USERS
================================================================================

1. BCL directories are NOT staged (copied) by Nextflow. The run_dir column in
   the demux samplesheet must be an absolute path accessible from all compute
   nodes. This avoids copying hundreds of GB of raw sequencing data.

2. If multiple samples come from the same BCL run, list each as a separate row
   in the samplesheet. CELLRANGER_MKFASTQ will run once per row (one sample per
   call), enabling full parallelism across samples.

3. The lane column accepts:
   - A specific lane number: "1", "2", etc.
   - "*" to include all lanes (most common for NextSeq/NovaSeq runs).

4. The index column accepts:
   - 10x dual-index sets: SI-GA-A1, SI-TT-A1, etc.
   - Plain sequences: ATCGATCG (for custom indices).

5. Output of mkfastq is published to:
   <outdir>/data/CELLRANGER_MKFASTQ/<sample>/outs/fastq_path/

6. The stub: block in CELLRANGER_MKFASTQ allows the pipeline graph to be tested
   with `nextflow run ... -stub-run` without an actual BCL directory.

NOTE: The CELLRANGER_MKFASTQ module is retained in modules/local/cellranger/mkfastq/
but is no longer used in the main demux workflow. It is superseded by AUTO_DEMUX
(see v2 changes below) which works directly from FASTQ files and requires no user
knowledge of index sequences.

================================================================================


================================================================================
SCRATCH-QC ALIGNMENT PIPELINE — CHANGE LOG (v2)
Feature: Hassle-free auto-detection demux — user provides R1/R2/I1/I2 only
Date: 2026-05-06
================================================================================

MOTIVATION
----------
The v1 demux implementation required users to fill in sample names, BCL run
paths, lane numbers, and index sequences — information that is often unknown or
hard to look up. The v2 approach removes all of this: the user provides the raw
FASTQ files exactly as delivered by the sequencing core (R1, R2, I1, optional I2)
and the pipeline automatically detects which samples are present, assigns names,
and demultiplexes before alignment.


================================================================================
FILES CREATED (v2)
================================================================================

1. bin/auto_demux.py  (executable Python 3 script)
   -------------------------------------------------
   Pure-stdlib Python script that performs two tasks:

   PHASE 1 — Sample detection (fast):
     * Reads the first --n-detect (default 50,000) records from I1.fastq.gz.
     * Builds a frequency table of all I1 barcode sequences.
     * Uses greedy centroid selection: any barcode sequence above --min-freq
       (default 1% of sampled reads) that is NOT within Hamming distance 1 of
       an already-chosen centroid becomes a new sample.
     * Auto-names samples: <run_id>_S01_<centroid>, _S02_, ..., in descending
       frequency order.
     * Writes detected_samples.csv (sample, centroid, modality) which Nextflow
       uses in a flatMap to create one channel element per sample.

   PHASE 2 — Demultiplexing (streaming):
     * Builds an O(1) lookup dict from all centroid sequences AND their
       1-mismatch neighbours (conflicts between two samples are discarded).
     * Streams R1, R2, I1 in lockstep (lock-step iteration, no random access).
     * Each read is assigned to its sample in O(1); reads with no match go to
       Undetermined.
     * Output FASTQs follow cellranger naming:
         <sample>_S1_L001_R1_001.fastq.gz / <sample>_S1_L001_R2_001.fastq.gz
       so they feed directly into cellranger count/vdj with --fastqs=. --sample=.
     * Writes demux_stats.csv with per-sample read counts and fractions.

   Error handling:
     * Exits with a clear message if no barcodes exceed the frequency threshold,
       with actionable suggestions (lower --min-freq or increase --n-detect).

   The script lives in bin/ which Nextflow automatically adds to PATH inside
   every process work directory — no separate container needed.

2. modules/local/auto_demux/main.nf
   ----------------------------------
   Nextflow process AUTO_DEMUX wrapping auto_demux.py.

   Input tuple: (run_id, path(r1), path(r2), path(i1), val(i2), modality)
     * i2 is val (string) not path so that an empty value is accepted for
       single-indexed runs without staging an empty path object.

   Output:
     * tuple(path("demuxed/"), path("demuxed/detected_samples.csv")),
       emit: demux_result   — consumed by flatMap in the subworkflow
     * path("demuxed/demux_stats.csv"), emit: stats
     * path("versions.yml"), emit: versions

   Runtime parameters (from nextflow.config params, tunable via CLI):
     * params.demux_n_detect   → --n-detect
     * params.demux_min_freq   → --min-freq
     * params.demux_mismatches → --mismatches

   Container: syedsazaidi/scratch-cellranger8:latest (already has Python 3).
   Label: process_medium (24 CPUs, 32 GB RAM — detection is fast; demux is I/O
   bound and benefits from multiple CPUs for gzip decompression).

   Stub block: creates a two-sample detected_samples.csv and empty FASTQ files
   so the pipeline DAG can be validated with -stub-run.

   Published outputs (to <outdir>/data/AUTO_DEMUX/):
     * demux_stats.csv     — read assignment statistics per sample
     * detected_samples.csv — manifest of auto-detected samples


================================================================================
FILES MODIFIED (v2)
================================================================================

3. subworkflow/local/scratch_align.nf
   ------------------------------------
   - Replaced `include { CELLRANGER_MKFASTQ }` with `include { AUTO_DEMUX }`.
   - DEMUX PATH completely rewritten:

     Samplesheet parsing:
       run_id, r1, r2, i1, i2, modality
       r1/r2/i1 parsed as file() paths (staged by Nextflow).
       i2 parsed as string (val) — empty string when column is blank.

     AUTO_DEMUX called once per row → emits (demux_dir, manifest).

     flatMap expansion:
       Reads detected_samples.csv from the manifest path.
       For each sample line, resolves:
         demux_dir.resolve("<sample>_S1_L001_R1_001.fastq.gz")
         demux_dir.resolve("<sample>_S1_L001_R2_001.fastq.gz")
       Emits: tuple(sample, [r1, r2], modality)
       This converts one (run, N samples) result into N parallel channel
       elements — all without the user specifying any sample names.

     Downstream (CELLRANGER_COUNT / CELLRANGER_VDJ) unchanged.

4. modules/local/cellranger/count/main.nf
   -----------------------------------------
   Reverted to original (pre-v1) clean state.
   The ext.fastqs_dir mechanism is removed — AUTO_DEMUX output files are
   already in cellranger naming format and staged flat in the work dir,
   so --fastqs=. and cellranger_renaming.py work as designed.

5. modules/local/cellranger/vdj/main.nf
   ----------------------------------------
   Same revert as count/main.nf.

6. conf/modules.config
   ---------------------
   - Removed CELLRANGER_MKFASTQ block.
   - Removed ext.fastqs_dir closures from CELLRANGER_COUNT and CELLRANGER_VDJ.
   - Added AUTO_DEMUX block:
       Publishes demux_stats.csv and detected_samples.csv to
       <outdir>/data/AUTO_DEMUX/ (per-sample FASTQs are NOT published —
       they are large intermediate files; only statistics are kept).

7. nextflow.config
   ----------------
   Updated demux param block comment to describe the new FASTQ-based approach.
   Added three new tuning parameters:
     demux_n_detect   = 50000   (reads sampled from I1 for detection)
     demux_min_freq   = 0.01    (1% threshold to call a barcode as a sample)
     demux_mismatches = 1       (mismatch tolerance for read assignment)

8. assets/test_demux_sample_table.csv
   -------------------------------------
   Updated to the new column format: run_id, r1, r2, i1, i2, modality
   Second row shows an empty i2 column for a single-indexed TCR run.

9. README.md
   ----------
   Completely rewrote the scratch_align_entry.nf section:
   - Explains the auto-detection approach (no index knowledge required).
   - Parameter table with all new demux_* params.
   - Column-by-column table for both samplesheet formats.
   - Three usage examples: standard, full demux, and sensitivity-tuned demux.


================================================================================
HOW THE AUTO-DEMUX PATH WORKS (DATA FLOW)
================================================================================

  Pooled FASTQs from sequencing core
  (Undetermined_R1, R2, I1, [I2])
               |
               | one row per sequencing run
               v
         AUTO_DEMUX
         ─────────────────────────────────────────
         Phase 1 — scan 50k I1 reads
           → frequency table of 8-mer barcodes
           → centroids above 1% threshold
           → auto-name: Run_S01_ATCG, Run_S02_GCTA...
         Phase 2 — build mismatch-tolerant lookup
         Phase 3 — stream R1/R2/I1, assign each read
           → per-sample cellranger-named FASTQs
           → Undetermined FASTQs
         Phase 4 — write stats + manifest
         ─────────────────────────────────────────
               |
               | flatMap over detected_samples.csv
               | → N parallel channel elements
               v
         Branch by modality
         /                    \
    GEX branch            TCR branch
         |                    |
         v                    v
  CELLRANGER_COUNT      CELLRANGER_VDJ
  --fastqs=.            --fastqs=.
  --sample=<sample>     --sample=<sample>
         |                    |
         v                    v
  sample/outs/*         sample/outs/*


================================================================================
TUNING GUIDE
================================================================================

If AUTO_DEMUX detects too few samples (samples missed):
  → Lower --demux_min_freq (e.g. 0.005 for very unequal pools)
  → Increase --demux_n_detect (e.g. 200000 for very low-input libraries)

If AUTO_DEMUX detects too many samples (phantom barcodes called):
  → Raise --demux_min_freq (e.g. 0.05 for balanced pools)

If reads are assigned to wrong samples (misassignment):
  → Lower --demux_mismatches to 0 (exact-match only)
  → Inspect demux_stats.csv: Undetermined fraction > 15% indicates problems

================================================================================

#!/bin/bash
set -euo pipefail  

# Paths
BASE_DIR="/home/SuGaR"
DATA_DIR="$BASE_DIR/gaussian_splatting/data"
INPUT_DIR="$DATA_DIR/input"
SCRIPT_DIR="/home/georeferenced_gsplat/scripts"
IMAGES_DIR="/home/images"
OUTPUT_DIR="$BASE_DIR/output"
DEST_DIR="/home/georeferenced_gsplat/output"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

START_TIME=$(date +%s)

log "Starting pipeline..."

# Prepare data folder
mkdir -p "$INPUT_DIR"

# Copy images
if [ -d "$IMAGES_DIR" ]; then
    log "Copying images from $IMAGES_DIR to $INPUT_DIR"
    cp -r "$IMAGES_DIR"/* "$INPUT_DIR"/
else
    log "ERROR: Source images folder $IMAGES_DIR not found."
    exit 1
fi

# Run COLMAP conversion
log "Running COLMAP conversion..."
cd "$BASE_DIR/gaussian_splatting"
stdbuf -oL -eL xvfb-run -s "-screen 0 640x480x24" python3 convert.py -s data/

# Run exif_to_txt.py
log "Running exif_to_txt.py..."
cd "$DATA_DIR"
if [ ! -f "$SCRIPT_DIR/exif_to_txt.py" ]; then
    log "ERROR: exif_to_txt.py not found in $SCRIPT_DIR"
    exit 1
fi
cp "$SCRIPT_DIR/exif_to_txt.py" .
stdbuf -oL -eL python3 exif_to_txt.py

# Run COLMAP model alignment
log "Running COLMAP model_aligner..."
stdbuf -oL -eL xvfb-run -s "-screen 0 640x480x24" colmap model_aligner \
    --input_path "$DATA_DIR/sparse/0" \
    --output_path "$DATA_DIR/sparse/0" \
    --ref_images_path "$DATA_DIR/geotags.txt" \
    --ref_is_gps 1 \
    --alignment_type enu \
    --robust_alignment_max_error 3.0

# Run SuGaR full pipeline
log "Running SuGaR full training pipeline..."
cd "$BASE_DIR"
stdbuf -oL -eL python3 train_full_pipeline.py \
    -s "$DATA_DIR" \
    -r dn_consistency \
    --high_poly True \
    --export_obj True \
    --gpu 1

log "Pipeline completed successfully!"

# Export results
log "Exporting output to $DEST_DIR..."
mkdir -p "$DEST_DIR"
cp -r "$OUTPUT_DIR"/* "$DEST_DIR/"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
log "Done. Total runtime: $((ELAPSED / 3600))h $((ELAPSED % 3600 / 60))m $((ELAPSED % 60))s"

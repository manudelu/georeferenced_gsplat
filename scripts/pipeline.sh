#!/bin/bash
set -euo pipefail
ulimit -n 65535

BASE_DIR="/home/SuGaR"
DATA_DIR="$BASE_DIR/gaussian_splatting/data"
INPUT_DIR="$DATA_DIR/input"
SCRIPT_DIR="/home/manueld/georeferenced_gsplat/scripts"
IMAGES_DIR="/home/manueld/fegino_images"
OUTPUT_DIR="$BASE_DIR/output"
DEST_DIR="/home/manueld/georeferenced_gsplat/output"
GS_OUTPUT_DIR="$BASE_DIR/output/vanilla_gs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

START_TIME=$(date +%s)
log "Starting pipeline..."

# Prepare input dir
mkdir -p "$INPUT_DIR"

# Copy images
if [ -d "$INPUT_DIR" ] && [ "$(ls -A "$INPUT_DIR")" ]; then
    log "Skipping image copy — $INPUT_DIR already contains files"
else
    log "Copying images from $IMAGES_DIR..."
    cp -r "$IMAGES_DIR"/* "$INPUT_DIR"/
fi

# Run COLMAP conversion t
if [ -d "$DATA_DIR/sparse/0" ]; then
    log "Skipping COLMAP conversion — already exists"
else
    log "Running COLMAP conversion..."
    cd "$BASE_DIR/gaussian_splatting"
    stdbuf -oL -eL xvfb-run -s "-screen 0 640x480x24" python3 convert.py -s data/
fi

# Run exif_to_txt.py 
if [ -f "$DATA_DIR/geotags.txt" ]; then
    log "Skipping exif_to_txt.py — geotags.txt already present"
else
    log "Running exif_to_txt.py..."
    cd "$DATA_DIR"
    cp "$SCRIPT_DIR/exif_to_txt.py" .
    stdbuf -oL -eL python3 exif_to_txt.py
fi

# Run model_aligner
if [ -f "$DATA_DIR/sparse/0/cameras.bin" ]; then
    log "Skipping model_aligner — seems already aligned"
else
    log "Running COLMAP model_aligner..."
    stdbuf -oL -eL xvfb-run -s "-screen 0 640x480x24" colmap model_aligner \
        --input_path "$DATA_DIR/sparse/0" \
        --output_path "$DATA_DIR/sparse/0" \
        --ref_images_path "$DATA_DIR/geotags.txt" \
        --ref_is_gps 1 \
        --alignment_type enu \
        --alignment_max_error 3.0
fi

# Run Gaussian Splatting on CPU if output doesn't exist
if [ -d "$GS_OUTPUT_DIR" ] && [ "$(ls -A "$GS_OUTPUT_DIR")" ]; then
    log "Skipping Gaussian Splatting training — output already exists"
else
    log "Running Gaussian Splatting training..."
    mkdir -p "$GS_OUTPUT_DIR"
    cd /home/SuGaR/gaussian_splatting
    python train.py -s data/ --data_device cpu --model_path "$GS_OUTPUT_DIR"
fi

# Run SuGaR pipeline
log "Running SuGaR training pipeline..."
cd "$BASE_DIR"
stdbuf -oL -eL python3 train_full_pipeline.py \
    -s "$DATA_DIR" \
    -r dn_consistency \
    --high_poly True \
    --export_obj True \
    --gpu 1 \
    --gs_output_dir "$GS_OUTPUT_DIR" \

# Copy results
if [ -d "$DEST_DIR" ] && [ "$(ls -A "$DEST_DIR")" ]; then
    log "Skipping export — destination not empty"
else
    log "Exporting output to $DEST_DIR..."
    mkdir -p "$DEST_DIR"
    cp -r "$OUTPUT_DIR"/* "$DEST_DIR/"
fi

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
log "Done. Total runtime: $((ELAPSED / 3600))h $((ELAPSED % 3600 / 60))m $((ELAPSED % 60))s"

#!/bin/bash
set -euo pipefail
ulimit -n 65535

# === LOG FUNCTION ===
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# === ACTIVATE CONDA ENVIRONMENT ===
eval "$(/opt/conda/bin/conda shell.bash hook)"
conda activate sugar

# === PATH SETUP ===
BASE_DIR="/home/workspace"
IMAGES_DIR="$BASE_DIR/images"
DATA_DIR="$BASE_DIR/georeferenced_gsplat/data"
SCRIPT_DIR="$BASE_DIR/georeferenced_gsplat/scripts"
OUTPUT_DIR="$BASE_DIR/georeferenced_gsplat/output"
SUGAR_DIR="/home/SuGaR"
SUGAR_OUTPUT_DIR="$SUGAR_DIR/output"

log "Starting SuGaR pipeline for georeferenced Gaussian Splatting..."

# === PREPARE INPUT ===
mkdir -p "$DATA_DIR/input"
if [ -d "$DATA_DIR/input" ] && [ "$(ls -A "$DATA_DIR/input")" ]; then
    log "Skipping image copy $DATA_DIR/input already contains files"
else
    log "Copying images from $IMAGES_DIR..."
    cp -r "$IMAGES_DIR"/* "$DATA_DIR/input"/
fi

# === COLMAP CONVERSION ===
if [ -d "$DATA_DIR/sparse/0" ]; then
    log "Skipping COLMAP conversion already exists"
else
    log "Running COLMAP conversion..."
    cd "$SUGAR_DIR/gaussian_splatting"
    stdbuf -oL -eL xvfb-run -s "-screen 0 640x480x24" python3 convert.py -s "$DATA_DIR"
fi

# === EXIF EXTRACTION ===
log "Running exif_to_txt.py..."
cd "$DATA_DIR"
cp "$SCRIPT_DIR/exif_to_txt.py" . || true
stdbuf -oL -eL python3 exif_to_txt.py

# === MODEL ALIGNMENT ===
log "Running COLMAP model_aligner (georeferencing)..."
stdbuf -oL -eL xvfb-run -s "-screen 0 640x480x24" colmap model_aligner \
    --input_path "$DATA_DIR/sparse/0" \
    --output_path "$DATA_DIR/sparse/0" \
    --ref_images_path "$DATA_DIR/geotags.txt" \
    --ref_is_gps 1 \
    --alignment_type enu \
    --alignment_max_error 3.0

# === GSPLAT TRAINING ON CPU ==
log "Running Gaussian Splatting training..."
mkdir -p "$OUTPUT_DIR/vanilla_gs"
cd "$SUGAR_DIR/gaussian_splatting"
python train.py -s "$DATA_DIR" --data_device cpu --iterations 7_000 --model_path "$OUTPUT_DIR/vanilla_gs"

# === SUGAR TRAINING PIPELINE ===
log "Running SuGaR full pipeline..."
cd "$SUGAR_DIR"

# Detect GPU
if python3 -c "import torch; exit(0) if torch.cuda.is_available() else exit(1)"; then
    GPU_FLAG="--gpu 0"
    log "GPU detected using GPU for training"
else
    GPU_FLAG=""
    log "No GPU detected training will use CPU"
fi

stdbuf -oL -eL python3 train_full_pipeline.py \
    -s "$DATA_DIR" \
    -r dn_consistency \
    --high_poly True \
    --export_obj True \
    --gs_output_dir "$OUTPUT_DIR/vanilla_gs" \
    $GPU_FLAG

# === EXPORT RESULTS ===
log "Exporting final output to $OUTPUT_DIR..."
cp -r "$SUGAR_OUTPUT_DIR"/* "$OUTPUT_DIR/" || true
log "Results copied successfully"
log "Pipeline completed successfully!"

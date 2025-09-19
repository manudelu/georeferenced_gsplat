#!/bin/bash
set -e  # stop if any command fails

# Paths
BASE_DIR="/home/SuGaR"
DATA_DIR="$BASE_DIR/gaussian_splatting/data"
INPUT_DIR="$DATA_DIR/input"
SCRIPT_DIR="$BASE_DIR/georeferenced_splat/scripts"  

# Activate conda environment
cd "$BASE_DIR"
source ~/miniconda3/etc/profile.d/conda.sh
conda activate sugar

# Prepare data folder
cd "$BASE_DIR/gaussian_splatting"
mkdir -p "$INPUT_DIR"

echo ">>> Please copy your input images into: $INPUT_DIR"
read -p "Press ENTER after inserting your images..."

# Run COLMAP conversion
xvfb-run -s "-screen 0 640x480x24" python3 convert.py -s data/

# Run exif_to_txt.py from your repo
cd "$DATA_DIR"
cp "$SCRIPT_DIR/exif_to_txt.py" .
chmod +x exif_to_txt.py
python3 exif_to_txt.py

# Run COLMAP model alignment
xvfb-run -s "-screen 0 640x480x24" colmap model_aligner \
    --input_path "$DATA_DIR/sparse/0" \
    --output_path "$DATA_DIR/sparse/0" \
    --ref_images_path "$DATA_DIR/geotags.txt" \
    --ref_is_gps 1 \
    --alignment_type enu \
    --robust_alignment_max_error 3.0

# Run SuGaR full pipeline
cd "$BASE_DIR/SuGaR"
python train_full_pipeline.py \
    -s "$DATA_DIR/iplom" \
    -r dn_consistency \
    --high_poly True \
    --export_obj True

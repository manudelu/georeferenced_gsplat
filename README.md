# Gaussian Splatting Pipeline with Georeferencing and Correct Scaling

This repository provides a pipeline for Gaussian Splatting with georeferencing and accurate scaling. Starting from drone images that contain GPS EXIF data, this workflow produces 3D reconstructions that are nearly perfectly scaled and aligned with real-world coordinates. The reference frame is anchored to the GPS position of the first image in the dataset.

The following images illustrate the results: on the left is the Gaussian Splatting reconstruction, and on the right is the SuGaR-refined Gaussian representation, both uploaded to Cesium Ion.

<img width="3835" height="945" alt="Comparison1" src="https://github.com/user-attachments/assets/3f9ba663-9007-4837-8b53-171b39f2801a" />
<img width="3840" height="946" alt="Comparison2" src="https://github.com/user-attachments/assets/d2ed34bc-c13c-46be-b516-57509542e46c" />
<img width="3842" height="946" alt="Comparison3" src="https://github.com/user-attachments/assets/854e806a-3d11-42c1-82f1-232acaae9141" />

## Technologies Used

- **CUDA 12.5** – Provides GPU acceleration to train the Gaussian Splatting model efficiently.
- **COLMAP** – Performs Structure-from-Motion (SfM) and Multi-View Stereo (MVS) reconstruction to generate georeferenced sparse and dense 3D point clouds from drone images. These point clouds are georeferenced and scaled according to GPS data.
- [**Gaussian Splatting**](https://github.com/graphdeco-inria/gaussian-splatting) – A neural rendering method that converts 3D points into Gaussian representations, producing highly detailed and accurate 3D reconstructions.
- [**SuGaR**](https://github.com/Anttwo/SuGaR) – A framework built around Gaussian Splatting that orchestrates the full pipeline:
  - *Short vanilla 3DGS optimization* – Optimizes a vanilla 3D Gaussian Splatting model for 7k iterations to position Gaussians in the scene.
  - *SuGaR optimization* – Refines Gaussian positions and aligns them to the surface of the scene.
  - *Mesh extraction* – Extracts a mesh from the optimized Gaussians.
  - *SuGaR refinement* – Builds a hybrid representation combining Gaussians and mesh for maximum accuracy.
  - *Textured mesh extraction (optional)* – Produces a traditional textured mesh for visualization, composition, and animation in Blender.

## Pipeline Overview

The pipeline.sh automates the process of converting GPS-tagged drone images into a georeferenced, scaled 3D reconstruction using Gaussian Splatting. The workflow is divided into four main stages:

1. **Data Preparation**
  - Copy raw drone images into the pipeline input folder.
  - Extract GPS EXIF data from the images into a text file (geotags.txt) using exif_to_txt.py.

2. **COLMAP Reconstruction**
  - Run COLMAP to perform Structure-from-Motion (SfM) and Multi-View Stereo (MVS) reconstruction.
  - Convert the reconstruction to an ENU (East-North-Up) frame using the GPS of the first image as reference.
  - The sparse and dense point clouds produced by COLMAP are aligned with real-world coordinates and scaled appropriately.

3. **Gaussian Splatting Training**
  - Train the Gaussian Splatting model using the georeferenced point cloud.
  - Use GPU acceleration for fast processing.
  - The training outputs:
    - Refined 3D Gaussians (.ply)
    - UV-textured mesh (.obj)

4. **Output Export**
  - Copy the final 3D reconstruction and mesh into the designated output directory.
  - The output is ready for visualization in tools like Cesium Ion, CloudCompare, Unreal Engine or any 3D GIS/game engines.

## How to Run the Pipeline

1. **Prepare Environment**
  - Ensure you have GPU support with CUDA 12.5 or compatible version.
  - Install Docker (optional) for reproducibility.
  - Activate the sugar conda environment:
    ```bash
    conda activate sugar
    ```

2. **Organize Data**
  - Place drone images in /home/images
  - Ensure images contain GPS EXIF metadata.
  - clone the repository in /home/
    ```bash
    git clone https://github.com/manudelu/georeferenced_gsplat.git
    cd georeferenced_gsplat
    ```

3. **Run the Pipeline**
  - Execute the main shell script:
    ```bash
    ./pipeline.sh
    ```
  - The script automatically:
    - Copies images.
    - Runs COLMAP reconstruction and alignment.
    - Runs SuGaR training.
    - Exports the final outputs to /home/georeferenced_gsplat/output

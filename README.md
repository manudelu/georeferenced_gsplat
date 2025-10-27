# Gaussian Splatting Pipeline with Georeferencing and Correct Scaling

This repository provides a pipeline for Gaussian Splatting with georeferencing and accurate scaling. Starting from drone images that contain GPS EXIF data, this workflow produces 3D reconstructions that are nearly perfectly scaled and aligned with real-world coordinates. The reference frame is anchored to the GPS position of the first image in the dataset.

The following images illustrate the results: on the left is the Gaussian Splatting reconstruction, and on the right is the SuGaR-refined Gaussian representation, both uploaded to Cesium Ion.

<img width="3835" height="945" alt="Comparison1" src="https://github.com/user-attachments/assets/3f9ba663-9007-4837-8b53-171b39f2801a" />
<img width="3840" height="946" alt="Comparison2" src="https://github.com/user-attachments/assets/d2ed34bc-c13c-46be-b516-57509542e46c" />
<img width="3842" height="946" alt="Comparison3" src="https://github.com/user-attachments/assets/854e806a-3d11-42c1-82f1-232acaae9141" />

## Technologies Used

- **[COLMAP](https://colmap.github.io/)** – Performs Structure-from-Motion (SfM) reconstruction to generate georeferenced sparse 3D point clouds from drone images. These point clouds are georeferenced and scaled according to GPS data.
- [**Gaussian Splatting**](https://github.com/graphdeco-inria/gaussian-splatting) – A neural rendering method that converts 3D points into Gaussian representations, producing highly detailed and accurate 3D reconstructions.
- [**SuGaR**](https://github.com/Anttwo/SuGaR) – A framework built around Gaussian Splatting that orchestrates the full pipeline:
  - *Short vanilla 3DGS optimization* – Optimizes a vanilla 3D Gaussian Splatting model for 7k iterations to position Gaussians in the scene.
  - *SuGaR optimization* – Refines Gaussian positions and aligns them to the surface of the scene.
  - *Mesh extraction* – Extracts a mesh from the optimized Gaussians.
  - *SuGaR refinement* – Builds a hybrid representation combining Gaussians and mesh for maximum accuracy.
  - *Textured mesh extraction (optional)* – Produces a traditional textured mesh for visualization, composition, and animation in Blender.

## Docker Installation

For reproducibility and ease of use, the pipeline is provided in a Docker image.

Before running the container, you need to organize your local workspace. This ensures your data and outputs persist even after you stop or rebuild the Docker image.

**1. Create the Workspace Structure**

On your host machine, create a main project folder. The structure should look like this:
```bash
/workspace/
 ├── images/                 # Folder containing your raw drone images (with GPS EXIF data)
 └── georeferenced_gsplat/   # Folder where the processing scripts and outputs will live
```

**2. Clone the repository**

Inside the `/workspace` folder, clone the repository:
```bash
git clone https://github.com/manudelu/georeferenced_gsplat.git
```

**3. Build the Docker image**
```bash
docker build -t georeferenced_gsplat:latest .
```

> **Important:** Before building, make sure to update the Dockerfile:
> * Set ENV TORCH_CUDA_ARCH_LIST to match your GPU(s) compute capability
> * Set -DCMAKE_CUDA_ARCHITECTURES in any CMake commands to your GPU(s) compute capability

**4. Run the Docker Container**
```bash
docker run --gpus all -it --name sugar-env -v /workspace:/home/workspace gaussian-splatting:22 bash
```

## Pipeline Overview

The `pipeline.sh` automates the process of converting GPS-tagged drone images into a georeferenced, scaled 3D reconstruction using Gaussian Splatting. The workflow is divided into four main stages:

1. **Data Preparation**
  - Copy raw drone images into the pipeline input folder.
  - Extract GPS EXIF data from the images into a text file (`geotags.txt`) using `exif_to_txt.py`.

2. **COLMAP Reconstruction**
  - Run COLMAP to perform Structure-from-Motion (SfM) reconstruction.
  - Convert the reconstruction to an ENU (East-North-Up) frame using the GPS of the first image as reference.
  - The sparse point cloud produced by COLMAP are aligned with real-world coordinates and scaled appropriately.

3. **Gaussian Splatting Training (SuGaR)**
  - Train the Gaussian Splatting model using the georeferenced point cloud.
  - Use GPU acceleration for fast processing.
  - The training outputs:
    - Refined 3D Gaussians (`.ply`)
    - UV-textured mesh (`.obj`)

4. **Output Export**
  - Copy the final 3D reconstruction and mesh into the designated output directory.
  - The output is ready for visualization in tools like Cesium Ion, CloudCompare, Unreal Engine or any 3D GIS/game engines.

## Running the Pipeline

Make the script executable and launch it:
```bash
cd /home/workspace/georeferenced_gsplat/scripts
chmod +x pipeline.sh
./pipeline.sh
```

The script automatically:
  - Copies images from `/home/workspace/images` to `/home/workspace/data/input`.
  - Runs COLMAP reconstruction (SfM) - converts the dataset to COLMAP sparse model format and aligns the model geospatially using the geotags.
  - Trains the Gaussian Splatting model, which will be saved in `/home/workspace/georeferenced_gsplat/output/vanilla_gs`.
  - Runs the SuGaR training pipeline, generating refined 3D outputs such as UV-textured meshes (`.obj`) and Gaussian point clouds (`.ply`) inside the output directory.
  - Exports the final results by copying all files from `/home/SuGaR/output` to `/home/workspace/georeferenced_gsplat/output`

> If running on a remote server (e.g., via SSH):
>```bash
>nohup ./pipeline.sh > pipeline.log 2>&1 &
>tail -f pipeline.log  # To monitor progress
>```
   
## Importing into Cesium Ion

1. Login to [Cesium Ion](https://cesium.com/platform/cesium-ion/).
2. Go to `My Assets` -> `Add Data`.
3. Upload the `.ply` generated by SuGaR (refined point cloud).
4. To georeference:
   * Use the GPS coordinates of the first image in the dataset.
   * Adjust location in Cesium Ion and save.
     
> Your Gaussian Splatting reconstruction will now be correctly aligned to real-world coordinates.

## Importing into Ureaal Engine

1. Open your Unreal Engine project (with [Cesium for Unreal](https://www.fab.com/listings/76c295fe-0dc6-4fd6-8319-e9833be427cd) and [LumaAI](https://www.fab.com/listings/b52460e0-3ace-465e-a378-495a5531e318) or [XScene](https://github.com/xverse-engine/XScene-UEPlugin) plugin installed).
2. Import the refined `.ply` into Unreal Engine.
3. Drag it into the Viewport.
4. Add a `Cesium Globe Anchor` actor.
   * Make the point cloud a child of the globe anchor or other 3D tiles (e.g., Google Photorealistic 3D Tiles).
   * Set the location to the GPS coordinates of the first image.
   * Adjust rotation if necessary.
  
> Now your Gaussian Splatting reconstruction is correctly georeferenced in Unreal Engine.

## Notes
* The pipeline automatically detects available GPUs for SuGaR training. If you want to force CPU-only execution or specify a different GPU, you can edit the `pipeline.sh` file.
* Mounting the `/workspace` directory ensures your data, scripts, and outputs persist across Docker rebuilds, keeping your experiments reproducible, organized, and clean.

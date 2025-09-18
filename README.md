# Gaussian Splatting Pipeline with Georeferencing and Correct Scaling

This repository provides a pipeline for Gaussian Splatting with georeferencing and accurate scaling. Starting from drone images that contain GPS EXIF data, this workflow produces 3D reconstructions that are nearly perfectly scaled and aligned with real-world coordinates. The reference frame is anchored to the GPS position of the first image in the dataset.

The following images illustrate the results: on the left is the Gaussian Splatting reconstruction, and on the right is the refined point cloud, both uploaded to Cesium Ion.

<img width="3835" height="945" alt="Comparison1" src="https://github.com/user-attachments/assets/3f9ba663-9007-4837-8b53-171b39f2801a" />
<img width="3840" height="946" alt="Comparison2" src="https://github.com/user-attachments/assets/d2ed34bc-c13c-46be-b516-57509542e46c" />
<img width="3842" height="946" alt="Comparison3" src="https://github.com/user-attachments/assets/854e806a-3d11-42c1-82f1-232acaae9141" />


## Installation Guide - Ubuntu 22.04

1. System Update and Essentials

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git build-essential cmake curl unzip wget -y
```

2. Install Miniconda

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

3. Install CUDA 11.8 Toolkit

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600

wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2004-11-8-local/cuda-368EAC11-keyring.gpg /usr/share/keyrings/

echo "deb [signed-by=/usr/share/keyrings/cuda-368EAC11-keyring.gpg] file:///var/cuda-repo-ubuntu2004-11-8-local /" | sudo tee /etc/apt/sources.list.d/cuda-local.list

sudo apt update
sudo apt install -y cuda-toolkit-11-8
```

Update environment variables:

```bash
export PATH=/usr/local/cuda-11.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
source ~/.bashrc
```

Check:

```bash
nvcc --version
```

4. Install PyTorch 2.0.1 with CUDA 11.8

```bash
sudo apt install -y python3 python3-pip
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118
```

5. Cleanup Installers

```bash
rm -rf cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb cuda-repo-wsl-ubuntu-12-6-local_12.6.0-1_amd64.deb Miniconda3-latest-Linux-x86_64.sh
```

6. Install COLMAP

```bash
sudo apt install -y colmap
```

7. Install SuGaR

```bash
git clone https://github.com/Anttwo/SuGaR.git --recursive
cd SuGaR/
python3 install.py
```

Activate the Conda environment: 

```bash
conda activate sugar
```

Install additional Python dependency:

```bash
pip install exifread
```

## Pipeline

FROM nvidia/cuda:12.5.0-devel-ubuntu22.04

# --- System dependencies ---
RUN apt-get update && apt-get install -y \
    git build-essential cmake curl unzip wget xvfb colmap \
    && rm -rf /var/lib/apt/lists/*

# --- Install Miniconda ---
WORKDIR /tmp
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /root/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH="/root/miniconda3/bin:$PATH"

# --- Environment variables ---
ENV PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
    TORCH_CUDA_ARCH_LIST="8.9"

# --- Clone SuGaR ---
WORKDIR /home
RUN git clone https://github.com/Anttwo/SuGaR.git --recursive
WORKDIR /home/SuGaR

# --- Create conda env and install deps ---
RUN conda create -n sugar -y python=3.9 && \
    conda install -n sugar -y \
      -c pytorch -c nvidia -c pytorch3d \
        pytorch pytorch-cuda torchvision torchaudio pytorch3d \
      -c fvcore -c iopath -c conda-forge \
        fvcore iopath plotly rich plyfile jupyterlab nodejs ipywidgets ninja open3d pymcubes \
      -c open3d open3d

# --- Switch shell to always run inside conda env ---
SHELL ["conda", "run", "-n", "sugar", "/bin/bash", "-c"]

# --- Install pip-based packages ---
RUN pip install -e gaussian_splatting/submodules/diff-gaussian-rasterization/
RUN cd gaussian_splatting/submodules/simple-knn && \
    sed -i '1i #include <float.h>' simple_knn.cu && \
    pip install -e .
RUN git clone https://github.com/NVlabs/nvdiffrast && \
    cd nvdiffrast && pip install .
RUN pip install exifread

# --- Fix rasterizer for CUDA ---
RUN sed -i 's/RasterizeGLContext()/RasterizeCudaContext()/g' /home/SuGaR/sugar_utils/mesh_rasterization.py

WORKDIR /home/SuGaR

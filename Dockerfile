FROM nvidia/cuda:12.5.0-devel-ubuntu22.04

# Noninteractive frontend
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Update and install basic tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        git build-essential cmake curl unzip wget xvfb \
        bash ca-certificates ninja-build bzip2 \
        libboost-program-options-dev libboost-graph-dev libboost-system-dev \
        libeigen3-dev libfreeimage-dev libmetis-dev libgoogle-glog-dev \
        libgtest-dev libgmock-dev libsqlite3-dev libglew-dev qtbase5-dev \
        libqt5opengl5-dev libcgal-dev libceres-dev libcurl4-openssl-dev libmkl-full-dev \
    && rm -rf /var/lib/apt/lists/*

# CUDA paths
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV TORCH_CUDA_ARCH_LIST="8.9"

# Install Miniconda
WORKDIR /opt
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda \
    && rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/opt/conda/bin:$PATH

# Accept Anaconda TOS for automated builds
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Create conda environment "sugar" with Python 3.9 and necessary packages
RUN conda create --name sugar -y python=3.9
RUN conda init bash

# Install Python packages in sugar environment
RUN conda install -n sugar -c fvcore -c iopath -c conda-forge fvcore iopath -y \
 && conda install -n sugar -c pytorch -c nvidia -c pytorch3d pytorch-cuda pytorch pytorch3d torchvision torchaudio -y \
 && conda install -n sugar -c plotly plotly -y \
 && conda install -n sugar -c conda-forge rich plyfile jupyterlab nodejs ipywidgets ninja -y \
 && conda run -n sugar pip install --no-cache-dir open3d PyMCubes exifread \
 && conda clean -afy

# Clone SuGaR repository
WORKDIR /home
RUN git clone https://github.com/Anttwo/SuGaR.git --recursive
WORKDIR /home/SuGaR/

# Install Gaussian Splatting submodules
RUN conda run -n sugar pip install --no-deps --no-build-isolation gaussian_splatting/submodules/diff-gaussian-rasterization/
RUN cd gaussian_splatting/submodules/simple-knn/ && sed -i '1i #include <float.h>' simple_knn.cu && conda run -n sugar pip install --no-deps --no-build-isolation .

# Install nvdiffrast
RUN git clone https://github.com/NVlabs/nvdiffrast.git
RUN cd nvdiffrast && conda run -n sugar pip install .

# Cleanup Git repos and caches
RUN find /home/SuGaR -name ".git" -type d -prune -exec rm -rf {} + || true \
 && rm -rf /root/.cache/pip /root/.cache/matplotlib || true

# Patch SuGaR Python scripts
RUN sed -i 's/RasterizeGLContext()/RasterizeCudaContext()/g' /home/SuGaR/sugar_utils/mesh_rasterization.py
RUN sed -i 's/--SiftExtraction\.use_gpu/--FeatureExtraction.use_gpu/g' /home/SuGaR/gaussian_splatting/convert.py
RUN sed -i 's/--SiftMatching\.use_gpu/--FeatureMatching.use_gpu/g' /home/SuGaR/gaussian_splatting/convert.py

# Install COLMAP from source
WORKDIR /tmp
RUN git clone https://github.com/colmap/colmap.git
WORKDIR /tmp/colmap/build
RUN cmake .. -GNinja -DBLA_VENDOR=Intel10_64lp -DCMAKE_CUDA_ARCHITECTURES=89
RUN ninja && ninja install

# Clean up conda and tmp
WORKDIR /opt
RUN conda clean -afy

# Set default working directory
WORKDIR /home

# Default command for interactive use
CMD ["/bin/bash"]

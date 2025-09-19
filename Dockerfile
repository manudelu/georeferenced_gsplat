FROM ubuntu-ldap:22-cuda
RUN apt update
RUN apt install git build-essential cmake curl unzip wget xvfb -y
WORKDIR /tmp
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -c
RUN rm Miniconda3-latest-Linux-x86_64.sh
 
ENV PATH /usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV TORCH_CUDA_ARCH_LIST="8.9"
 
RUN apt install -y python3 python3-pip

RUN apt install colmap -y

WORKDIR /home
RUN git clone https://github.com/Anttwo/SuGaR.git --recursive
WORKDIR /home/SuGaR/

ENV PATH /root/miniconda3/condabin:$PATH

RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN conda create --name sugar -y python=3.9
RUN conda init bash

RUN conda install -n sugar -c fvcore -c iopath -c conda-forge fvcore iopath -y
RUN conda install -n sugar -c pytorch -c nvidia -c pytorch3d pytorch-cuda pytorch pytorch3d torchvision torchaudio  -y
RUN conda install -n sugar -c plotly plotly -y
RUN conda install -n sugar -c conda-forge rich -y
RUN conda install -n sugar -c conda-forge plyfile -y
RUN conda install -n sugar -c conda-forge jupyterlab -y
RUN conda install -n sugar -c conda-forge nodejs -y
RUN conda install -n sugar -c conda-forge ipywidgets -y
RUN conda install -n sugar -c conda-forge ninja -y
RUN pip install open3d
RUN pip install --upgrade PyMCubes

RUN conda run -n sugar pip install -e gaussian_splatting/submodules/diff-gaussian-rasterization/
RUN cd gaussian_splatting/submodules/simple-knn/ && sed -i '1i #include <float.h>' simple_knn.cu && conda run -n sugar pip install -e .

WORKDIR /home/SuGaR
RUN git clone https://github.com/NVlabs/nvdiffrast
RUN cd nvdiffrast  && conda run -n sugar pip install .
RUN conda run -n sugar pip install exifread

RUN sed -i 's/RasterizeGLContext()/RasterizeCudaContext()/g' /home/SuGaR/sugar_utils/mesh_rasterization.py
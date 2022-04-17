
# FROM nvidia/cuda:11.6.2-cudnn8-runtime-ubuntu20.04
FROM nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04
MAINTAINER duclm29@viettel.com.vn

ENV DEBIAN_FRONTEND=noninteractive \
    TF_FORCE_GPU_ALLOW_GROWTH=true

# ============== Step1: Install all OS dependenciesm =================
RUN apt-get update && \
    apt-get install -yq --no-install-recommends --no-upgrade \
    apt-utils && \
    apt-get install -yq --no-install-recommends --no-upgrade \
    curl \
    wget \
    bzip2 \
    ca-certificates \
    locales \
    fonts-liberation \
    tmux \
    build-essential \
    cmake \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    pandoc \
    libjpeg-dev \
    libpng-dev  \
    ffmpeg \
    graphviz\
    git \
    nano \
    htop \
    zip \
    unzip \
    python3.7 \
    python3-pip \
    libncurses5-dev \
    libncursesw5-dev \
    libopenblas-base \
    libopenblas-dev \
    libboost-all-dev \
    libsdl2-dev \
    swig \
    pkg-config \
    g++ \
    zlib1g-dev \
    patchelf \
    sudo \
    && apt-get purge jed -y \
    && apt-get autoremove -y \
    && apt-get clean && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# RUN pip install --upgrade pip==21.1.3
# RUN conda install python==3.7.13
# =========== Step2: install java ===========
# Install OpenJDK-8
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;

# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME


#Downgrade CUDA, TF issue: https://github.com/tensorflow/tensorflow/issues/17566#issuecomment-372490062
# RUN apt-get install --allow-downgrades -y libcudnn7=7.0.5.15-1+cuda9.0

#Install MINICONDA
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda.sh && \
	/bin/bash Miniconda.sh -b -p /opt/conda && \
	rm Miniconda.sh

ENV PATH /opt/conda/bin:$PATH
RUN conda update conda
#Create ANACONDA Environment: jupyter_env python3.7
RUN conda create -y -n jupyter_env python=3.7 anaconda

# install libs by conda
# RUN /bin/bash -c "source activate jupyter_env && conda install pytorch torchvision -c pytorch"
USER root

# install tensorflow
RUN /bin/bash -c "source activate jupyter_env" &&\
    /bin/bash -c conda install -c anaconda -c pytorch --quiet --yes \
      'python=3.7' \
      pytorch torchvision torchaudio \
      tensorflow-gpu \
      tensorflow-hub \
      tensorflow-datasets \
      'cudatoolkit=11.2' && \
    /opt/conda/envs/jupyter_env/bin/pip  install --no-cache-dir torchtext pytorch-lightning['extra'] && \
    /opt/conda/envs/jupyter_env/bin/pip  uninstall pillow -y && \
      CC="cc -mavx2" /opt/conda/envs/jupyter_env/bin/pip install -U --force-reinstall --no-cache-dir pillow-simd && \
    /bin/bash -c conda clean -tipsy && \
    /bin/bash -c conda build purge-all

# install rapids
RUN /bin/bash -c "source activate jupyter_env" &&\
    /bin/bash -c conda install \
      -c nvidia \
      -c rapidsai \
      -c numba -c conda-forge -c defaults \
      'python=3.7' \
      'rapids-blazing' \
      'cudatoolkit=11.2' && \
    /bin/bash -c conda install \
      -c rapidsai/label/xgboost \
      'xgboost' \
      'dask-xgboost' && \
    /opt/conda/envs/jupyter_env/bin/pip  install --no-cache-dir \
      dask_labextension && \
    /bin/bash -c conda clean -tipsy && \
    /bin/bash -c conda build purge-all

#     jupyter labextension install dask-labextension && jupyter lab clean && \

# using pip install
# RUN	/opt/conda/envs/jupyter_env/bin/pip install tensorflow-gpu keras jupyter-tensorboard jupyterlab
ADD requirements.txt requirements.txt
RUN /opt/conda/envs/jupyter_env/bin/pip install --trusted-host=pypi.python.org --trusted-host=pypi.org --trusted-host=files.pythonhosted.org -r requirements.txt
#Launch JUPYTER COMMAND
CMD /opt/conda/envs/jupyter_env/bin/jupyter notebook --ip=* --no-browser --allow-root --notebook-dir=/tmp
# #


# Copyright (c) 2025 Junya Wada
# This software is released under the MIT License.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    wget git curl build-essential vim nano tmux \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 
ENV PATH="/root/miniconda3/bin:${PATH}"

WORKDIR /workspace

# 3. Create Conda environment
RUN conda create -n omnivla python=3.10 -c conda-forge --override-channels -y

# 4. Set shell
SHELL ["conda", "run", "-n", "omnivla", "/bin/bash", "-c"]

# 5. Install General Dependencies FIRST
# (To prevent them from upgrading PyTorch later)
RUN pip install \
    numpy==1.26.4 \
    utm matplotlib transformers timm wandb termcolor scipy \
    opencv-python-headless huggingface_hub peft accelerate \
    bitsandbytes datasets pandas einops dill ipykernel

# 6. Install PyTorch (Specific CUDA version)
# We install this AFTER general deps to ensure version 2.2.0 stays fixed
RUN pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 \
     --index-url https://download.pytorch.org/whl/cu118

# 7. Install Flash Attention 2
# Must be compiled against the EXACT PyTorch version installed above
ENV MAX_JOBS=4
RUN pip install packaging ninja psutil
RUN pip install "flash-attn==2.5.5" --no-build-isolation

# 8. Copy source code
# Only copy the OmniVLA folder from host to /workspace/OmniVLA in container
COPY OmniVLA /workspace/OmniVLA

# 9. Install OmniVLA package
# Set WORKDIR to exactly where setup.py is located
WORKDIR /workspace/OmniVLA
RUN pip install -e .

# 10. Set PYTHONPATH
ENV PYTHONPATH="${PYTHONPATH}:/workspace/OmniVLA:/workspace/Learning-to-Drive-Anywhere-with-MBRA/train:/workspace/lerobot"

# 11. Auto-activate Conda
RUN echo "source /root/miniconda3/etc/profile.d/conda.sh && conda activate omnivla" >> ~/.bashrc

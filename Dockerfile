# Base image with Python 3.11, PyTorch, CUDA 12.4.1, and Ubuntu 22.04
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
USER root
# Set the working directory inside the container
WORKDIR /workspace
COPY node.sh /workspace/node.sh
RUN chmod +x /workspace/node.sh
# Install necessary packages and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*
ENV INSTALL_NODE_VER=22
ENV INSTALL_NVM_VER=0.40.1

RUN node.sh

# Clone your repository
RUN git clone https://github.com/aredden/flux-fp8-api

# Change directory to the cloned repo
WORKDIR /workspace/flux-fp8-api

# Install Python dependencies
RUN pip install -r requirements.txt

# Download the required model files
RUN wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors -O /workspace/flux1-schnell.safetensors && \
    wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors -O /workspace/ae.safetensors

# Expose necessary HTTP ports
EXPOSE 8888 7860

# Set the command to run your Python script
CMD /bin/bash -c "source $NVM_DIR/nvm.sh && node index.js && gradio main_gr.py"

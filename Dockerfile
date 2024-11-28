# Base image with Python 3.11, PyTorch, CUDA 12.4.1, and Ubuntu 22.04
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04 AS base

# Set the working directory inside the container
WORKDIR /workspace

# Copy the application files
COPY . /workspace/

# Install dependencies and Node.js 22 in a single RUN command to reduce layers
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    curl && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.40.1/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install 22 && \
    nvm alias default 22 && \
    nvm use default && \
    git clone https://github.com/aredden/flux-fp8-api && \
    cd flux-fp8-api && \
    pip install -r requirements.txt

# Download large files in a separate stage
FROM base AS downloader

# Download the required model files
RUN wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors -O /workspace/flux1-schnell.safetensors && \
    wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors -O /workspace/ae.safetensors

# Final stage to create the final image
FROM base

# Copy the downloaded files from the downloader stage
COPY --from=downloader /workspace/flux1-schnell.safetensors /workspace/
COPY --from=downloader /workspace/ae.safetensors /workspace/

# Set up environment for NVM
ENV NVM_DIR /root/.nvm
ENV NODE_VERSION 22
RUN echo "source $NVM_DIR/nvm.sh" >> /root/.bashrc

# Expose necessary HTTP ports
EXPOSE 8888 7860

# Set the command to run your Python script
CMD /bin/bash -c "source $NVM_DIR/nvm.sh && node index.js && gradio main_gr.py"
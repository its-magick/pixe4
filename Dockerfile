# Base image with Python 3.11, PyTorch, CUDA 12.4.1, and Ubuntu 22.04
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set the working directory inside the container
WORKDIR /workspace

# Install necessary packages and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*
ENV INSTALL_NODE_VER=22
ENV INSTALL_NVM_VER=0.40.1
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v{$INSTALL_NVM_VER}/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install $INSTALL_NODE_VER && \
    nvm alias default $INSTALL_NODE_VER && \
    nvm use default

# Set up environment for NVM
ENV NVM_DIR=/root/.nvm
ENV NODE_VERSION=$INSTALL_NODE_VER
RUN echo "source $NVM_DIR/nvm.sh" >> /root/.bashrc

# Install Node.js and npm
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install 22 && nvm alias default 22 && nvm use default"

# Check versions and print binary paths
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm --version && node --version && npm --version && which npm && which node"

# Clear NVM cache and install npm packages
RUN /bin/bash -c "nvm cache clear && npm install"

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

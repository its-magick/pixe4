# Base image with Python 3.11, PyTorch, CUDA 12.4.1, and Ubuntu 22.04
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set the working directory inside the container
WORKDIR /workspace

# Install necessary packages and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone your repository
RUN git clone https://github.com/Yuanshi9815/OminiControl
COPY . /workspace/fp8
# Change directory to the cloned repo
WORKDIR /workspace/fp8

# Install Python dependencies
RUN pip install -r requirements.txt

# Download the required model files
RUN wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors -O /workspace/flux1-schnell.safetensors && \
    wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors -O /workspace/ae.safetensors

# Expose necessary HTTP ports
EXPOSE 8888 7860

# Set the command to run your Python script
CMD ["python", "main_gr.py"]

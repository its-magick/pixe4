# Base image with Python 3.11, PyTorch, CUDA 12.4.1, and Ubuntu 22.04
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
USER root
# Set the working directory inside the container
WORKDIR /workspace

RUN curl https://nodejs.org/dist/v4.2.4/node-v4.2.4-linux-x64.tar.gz | tar xzvf - --exclude CHANGELOG.md --exclude LICENSE --exclude README.md --strip-components 1 -C /usr/local/

# Clone your repository
RUN git clone https://github.com/aredden/flux-fp8-api

# Change directory to the cloned repo


# Install Python dependencies
RUN pip install -r requirements.txt

# Download the required model files
RUN wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors -O /flux1-schnell.safetensors && \
    wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors -O /ae.safetensors

# Expose necessary HTTP ports
EXPOSE 8888 7860

# Set the command to run your Python script
CMD /bin/bash -c "node index.js && gradio main_gr.py"

# Build stage
FROM ubuntu:22.04 AS build

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        curl \
        gnupg && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

# Install Miniconda
WORKDIR /opt
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    sh Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -f Miniconda3-latest-Linux-x86_64.sh

# Set the path for conda
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/opt/miniconda3/bin:$PATH

# Update conda, install jupyterlab, extensions (jupyterlab-variableInspector, black, isort)
RUN conda update conda && \
    conda install -y jupyterlab && \
    conda clean -afy && \
    pip install lckr-jupyterlab-variableinspector && \
    jupyter lab build && \
    pip install black isort && \
    jupyter labextension install @ryantam626/jupyterlab_code_formatter && \
    pip install jupyterlab_code_formatter && \
    jupyter serverextension enable --py jupyterlab_code_formatter && \
    mkdir -p /root/.jupyter/lab/user-settings/@ryantam626/jupyterlab_code_formatter && \
    echo '{ "default_formatter": "black" }' > /root/.jupyter/lab/user-settings/@ryantam626/jupyterlab_code_formatter/settings.jupyterlab-settings

# Upgrade pip and install required Python packages
RUN pip install --upgrade pip && \
    pip install pandas matplotlib seaborn && \
    rm -rf /root/.cache/pip

# Enable Dark mode & 'Auto Close Brackets'
RUN mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension && \
    echo '{ "theme": "JupyterLab Dark" }' > /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings && \
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/notebook-extension && \
    echo '{ "codeCellConfig": { "autoClosingBrackets": true } }' > /root/.jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings

# Runtime stage
FROM ubuntu:22.04

# Set the path for conda
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/opt/miniconda3/bin:$PATH

COPY --from=build /opt/miniconda3 /opt/miniconda3
COPY --from=build /root/.jupyter /root/.jupyter

# Set working directory and start JupyterLab
WORKDIR /
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--ServerApp.token="]

# $ docker build -t ubun_mini_jupy_basic .
# $ docker run -p 8888:8888 -v "/mnt/c/Users/yourUserID/Desktop":/work --rm --name ubun_mini_jupy_basic ubun_mini_jupy_basic

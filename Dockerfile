FROM ubuntu:18.04

# Set up timezone.
RUN apt-get -q update \
    && apt-get install -y tzdata \
    && ln -fs /usr/share/zoneinfo/Asia/Taipei /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Upgrade existing packages.
RUN apt-get -qy dist-upgrade \
    && apt-get -qy install \
        sudo build-essential make cmake silversearcher-ag \
        libc6-dev gcc-7 g++-7 gcc-multilib

# Install building tools.
RUN apt-get -qy install sudo build-essential make cmake silversearcher-ag \
  libc6-dev gcc-7 g++-7 gcc-multilib \
  curl git

# Setup Home dir
ENV user ubuntu
RUN useradd -m -d /home/${user} ${user} && \
    chown -R ${user} /home/${user} && \
    adduser ${user} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV user_home /home/${user}

USER ${user}
WORKDIR ${user_home}

RUN git clone https://github.com/yungyuc/workspace.git workspace \
    && rm -rf .git \
    && mv workspace/.git . \
    && rm -rf workspace \
    && git checkout -- .

RUN mkdir -p tmp \
    && rm -rf tmp/* \
    && mkdir -p work/tmp \
    && rm -rf work/tmp/*


# Install miniconda
RUN curl -SL -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash miniconda.sh -b -p opt/conda \
    && rm -rf miniconda.sh

#ENV PATH=${USER_HOME}/opt/conda/bin:${PATH}
#ENV CONDA_BIN /home/ubuntu/opt/conda/bin/conda

# update conda
RUN export PATH=opt/conda/bin:${PATH} \
    && conda config --set channel_priority strict \
    && conda update --all --yes \
    && conda install --yes pip python numpy scipy pytest pandas matplotlib mkl-include

RUN export PATH=opt/conda/bin:${PATH} \
    && pip install nbgitpuller sphinx-gallery notebook jupyterlab rise cxxfilt \
    && pip install https://github.com/aldanor/ipybind/tarball/master

# ENV INSTALL_PREFIX ${INSTALL_PREFIX:-{HOME}/opt/conda}
# ENV INSTALL_VERSION ${INSTALL_VERSION:-master}

COPY contrib/install_docker.sh /build/install_docker.sh
WORKDIR /build

RUN export PATH=/home/${user}/opt/conda/bin:${PATH} \
    && export INSTALL_PREFIX="${INSTALL_PREFIX:-${HOME}/opt/conda}" \
    && export INSTALL_VERSION="${INSTALL_VERSION:-master}" \
    && bash install_docker.sh

# user programs 
# RUN apt-get -yq install git \
#     && rm -rf /var/lib/apt/lists/*

USER root
RUN rm -rf /var/lib/apt/lists/* \
    && chown -R ${user}:${user} /home/${user}

USER ${user}
WORKDIR /home/${user}
ENV PATH="/home/${user}/opt/conda/bin:${PATH}"

CMD ["/bin/bash"]
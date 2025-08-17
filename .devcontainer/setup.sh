#!/bin/bash

echo "Creating KryptoNyte environment. This will take some time (minutes)"

cat >> ~/.bashrc << EOF
if [[ ":\$PATH:" != *":/usr/local/bin:"* ]]; then
    export PATH="/usr/local/bin:\$PATH"
fi
EOF
`export PATH="/usr/local/bin:$PATH"`

# Install g++14
add-apt-repository -y ppa:ubuntu-toolchain-r/ppa
apt update && apt install -y gcc-14 g++-14 && apt clean
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
update-alternatives --set gcc /usr/bin/gcc-14 && \
update-alternatives --set g++ /usr/bin/g++-14

##################
# Install SDKMAN!
##################
curl -s "https://get.sdkman.io" | bash && \
bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && \
            sdk install java 23.0.1-oracle --default && \
            sdk install sbt && \
            sdk install scala 2.13.15 --default"

###################
# Install verilator
###################
apt install -y verilator

################################
# Download and install firtools
################################
FIRTOOL_URL=$(curl -s https://api.github.com/repos/llvm/circt/releases/latest | \
    jq -r '.assets[] | select(.name == "firrtl-bin-linux-x64.tar.gz") | .browser_download_url') && \
    wget --no-check-certificate $FIRTOOL_URL -O /tmp/firtool.tar.gz && \
    mkdir -p /tmp/firtool && \
    tar -xzf /tmp/firtool.tar.gz -C /tmp/firtool && \
    find /tmp/firtool -type f -name firtool -exec mv {} /usr/local/bin/ \; && \
    chmod +x /usr/local/bin/firtool && \
    rm -rf /tmp/firtool /tmp/firtool.tar.gz

#####################################################
# Download and install OSS-CAD Suite (contains yosys)
#####################################################
OSS_CAD_URL=$(curl -s https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest | \
    jq -r '.assets[] | select(.name | contains("linux-x64")) | .browser_download_url') && \
    wget --no-check-certificate $OSS_CAD_URL -O /tmp/oss-cad-suite.tar.xz && \
    mkdir -p /opt/oss-cad-suite && \
    tar -xf /tmp/oss-cad-suite.tar.xz -C /opt/oss-cad-suite --strip-components=1 && \
    rm /tmp/oss-cad-suite.tar.xz

# Add OSS-CAD Suite to PATH
cat >> ~/.bashrc << EOF
if [[ ":\$PATH:" != *":/opt/oss-cad-suite/bin:"* ]]; then
    export PATH="/opt/oss-cad-suite/bin:\$PATH"
fi
EOF
`export PATH="/opt/oss-cad-suite/bin:$PATH"`

yosys --version
    
######################################
# Install netlistsvg (requires nodejs)
######################################
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt install -y nodejs && \
    npm install -g npm@latest

npm install -g netlistsvg

##################################
# Download and install sv2v binary
##################################
SV2V_URL=$(curl -s https://api.github.com/repos/zachjs/sv2v/releases/latest | \
    jq -r '.assets[] | select(.name == "sv2v-Linux.zip") | .browser_download_url') && \
    wget $SV2V_URL -O /tmp/sv2v.zip && \
    mkdir -p /tmp/sv2v && \
    unzip /tmp/sv2v.zip -d /tmp/sv2v && \
    find /tmp/sv2v -type f -name sv2v -exec mv {} /usr/local/bin/ \; && \
    chmod +x /usr/local/bin/sv2v && \
    rm -rf /tmp/sv2v /tmp/sv2v.zip

sv2v --version

#####################################
# Install rsvg-convert, and Inkscape
#####################################
apt update && apt install -y \
    librsvg2-bin \
    inkscape \
    && apt clean

rsvg-convert --version
inkscape --version



echo "Setup completed successfully!"

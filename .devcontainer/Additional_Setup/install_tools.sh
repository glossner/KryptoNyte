#######################################
# RISC-V Prebuilt Toolchain from Collab
#######################################
RISCV_TOOLS_VERSION="2025.08.08"
RISCV_TOOLS_INSTALL_DIR="/opt/riscv/collab"
cd /tmp 

# 32-bit tools
wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/${RISCV_TOOLS_VERSION}/riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz 
mkdir -p ${RISCV_TOOLS_INSTALL_DIR}
tar -xvf riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz -C ${RISCV_TOOLS_INSTALL_DIR} --strip-components=1

# 64-bit tools
wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/${RISCV_TOOLS_VERSION}/riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz 
mkdir -p ${RISCV_TOOLS_INSTALL_DIR}
tar -xvf riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz -C ${RISCV_TOOLS_INSTALL_DIR} --strip-components=1

cat >> ~/.bashrc << EOF
# FlowNyte RISC-V Tools
if [[ ":\$PATH:" != *":${RISCV_TOOLS_INSTALL_DIR}:"* ]]; then
    export PATH="${RISCV_TOOLS_INSTALL_DIR}:\$PATH"
fi
EOF

export PATH="${RISCV_TOOLS_INSTALL_DIR}:$PATH"
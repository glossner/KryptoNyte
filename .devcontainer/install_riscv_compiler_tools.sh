#!/bin/bash

#######################################
# RISC-V Prebuilt Toolchain from Collab
# Enhanced with --with-sudo option
#######################################

# Script configuration
RISCV_TOOLS_VERSION="2025.08.08"
RISCV_TOOLS_INSTALL_DIR="/opt/riscv/collab"
USE_SUDO=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-sudo)
            USE_SUDO=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--with-sudo] [--help]"
            echo ""
            echo "Options:"
            echo "  --with-sudo    Use sudo for commands requiring elevated privileges"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "This script installs RISC-V toolchain to ${RISCV_TOOLS_INSTALL_DIR}"
            echo "and updates PATH in ~/.bashrc"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to execute commands with optional sudo
run_cmd() {
    if [ "$USE_SUDO" = true ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Function to check if directory requires sudo access
check_sudo_needed() {
    local dir="$1"
    local parent_dir=$(dirname "$dir")
    
    # Check if we can write to the parent directory
    if [ ! -w "$parent_dir" ] 2>/dev/null; then
        return 0  # sudo needed
    fi
    
    # Check if directory exists and we can write to it
    if [ -d "$dir" ] && [ ! -w "$dir" ]; then
        return 0  # sudo needed
    fi
    
    return 1  # sudo not needed
}

# Auto-detect if sudo is needed for installation directory
if [ "$USE_SUDO" = false ] && check_sudo_needed "$RISCV_TOOLS_INSTALL_DIR"; then
    echo "Warning: Installation directory ${RISCV_TOOLS_INSTALL_DIR} requires elevated privileges."
    echo "Consider running with --with-sudo option or as root."
    echo "Continuing anyway - commands may fail..."
    echo ""
fi

echo "Installing RISC-V Toolchain v${RISCV_TOOLS_VERSION}"
echo "Installation directory: ${RISCV_TOOLS_INSTALL_DIR}"
echo "Using sudo: ${USE_SUDO}"
echo ""

# Change to temporary directory
cd /tmp || exit 1

# 32-bit tools
echo "Downloading 32-bit RISC-V toolchain..."
wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/${RISCV_TOOLS_VERSION}/riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz || {
    echo "Error: Failed to download 32-bit toolchain"
    exit 1
}

echo "Creating installation directory and extracting 32-bit tools..."
run_cmd mkdir -p "${RISCV_TOOLS_INSTALL_DIR}" || {
    echo "Error: Failed to create installation directory"
    exit 1
}

run_cmd tar -xf riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz -C "${RISCV_TOOLS_INSTALL_DIR}" --strip-components=1 || {
    echo "Error: Failed to extract 32-bit toolchain"
    exit 1
}

# 64-bit tools  
echo "Downloading 64-bit RISC-V toolchain..."
wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/${RISCV_TOOLS_VERSION}/riscv64-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz || {
    echo "Error: Failed to download 64-bit toolchain"
    exit 1
}

echo "Extracting 64-bit tools..."
run_cmd tar -xf riscv64-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz -C "${RISCV_TOOLS_INSTALL_DIR}" --strip-components=1 || {
    echo "Error: Failed to extract 64-bit toolchain"
    exit 1
}

# Update PATH in ~/.bashrc (always runs as current user, never needs sudo)
echo "Updating PATH in ~/.bashrc..."
cat >> ~/.bashrc << EOF
# KryptoNyte RISC-V Tools
if [[ ":\$PATH:" != *":${RISCV_TOOLS_INSTALL_DIR}/bin:"* ]]; then
    export PATH="${RISCV_TOOLS_INSTALL_DIR}/bin:\$PATH"
fi
EOF

# Set PATH for current session
export PATH="${RISCV_TOOLS_INSTALL_DIR}/bin:$PATH"

# Test installation
echo ""
echo "Testing installation..."
if command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
    echo "✓ 32-bit toolchain installed successfully"
    riscv32-unknown-elf-gcc --version | head -1
else
    echo "✗ 32-bit toolchain installation failed"
fi

if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    echo "✓ 64-bit toolchain installed successfully"  
    riscv64-unknown-elf-gcc --version | head -1
else
    echo "✗ 64-bit toolchain installation failed"
fi

# Cleanup
echo ""
echo "Cleaning up temporary files..."
rm -f riscv32-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz
rm -f riscv64-elf-ubuntu-24.04-gcc-nightly-${RISCV_TOOLS_VERSION}-nightly.tar.xz

source ~/.bashrc

echo ""
echo "Installation complete!"
echo "Toolchain installed to: ${RISCV_TOOLS_INSTALL_DIR}"
echo "PATH updated in ~/.bashrc"
echo ""



#!/bin/bash

#######################################
# KryptoNyte Development Environment Setup
# Enhanced for both Codespace and standalone use
#######################################

# Script configuration
USE_SUDO=false
VERBOSE=true

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-sudo)
            USE_SUDO=true
            shift
            ;;
        --quiet)
            VERBOSE=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--with-sudo] [--quiet] [--help]"
            echo ""
            echo "KryptoNyte Development Environment Setup"
            echo ""
            echo "Options:"
            echo "  --with-sudo    Use sudo for commands requiring elevated privileges"
            echo "  --quiet        Reduce output verbosity"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "This script installs all tools needed for KryptoNyte development:"
            echo "  - GCC 14 compiler"
            echo "  - SDKMAN with Java, SBT, and Scala"
            echo "  - Verilator HDL simulator"
            echo "  - FIRRTL tools (firtool)"
            echo "  - OSS-CAD Suite (Yosys, etc.)"
            echo "  - Node.js and netlistsvg"
            echo "  - sv2v SystemVerilog converter"
            echo "  - Graphics tools (rsvg-convert, Inkscape)"
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

# Function to print large banner messages
print_banner() {
    local message="$1"
    local color="$2"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "\n${color}"
        echo "=================================================================="
        echo "  $message"
        echo "=================================================================="
        echo -e "${NC}"
    fi
}

# Function to print step messages
print_step() {
    local message="$1"
    local color="${2:-$CYAN}"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "\n${color}▶ $message${NC}"
    fi
}

# Function to print success messages
print_success() {
    local message="$1"
    echo -e "${GREEN}✓ $message${NC}"
}

# Function to print error messages
print_error() {
    local message="$1"
    echo -e "${RED}✗ Error: $message${NC}" >&2
}

# Function to print warning messages
print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ Warning: $message${NC}"
}

# Function to check if running in Codespace
is_codespace() {
    [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]
}

# Function to detect if sudo is needed
check_sudo_needed() {
    # Check if we can write to /usr/local/bin
    if [ ! -w "/usr/local/bin" ] 2>/dev/null; then
        return 0  # sudo needed
    fi
    
    # Check if we can run apt commands
    if ! apt list --installed >/dev/null 2>&1; then
        return 0  # sudo needed
    fi
    
    return 1  # sudo not needed
}

# Auto-detect environment and sudo needs
if is_codespace; then
    print_banner "DETECTED: GitHub Codespace Environment" "$PURPLE"
    # In Codespaces, we typically have sudo access
    if [ "$USE_SUDO" = false ] && check_sudo_needed; then
        print_warning "Codespace detected but sudo may be needed for some operations"
        print_warning "Consider running with --with-sudo if commands fail"
    fi
else
    print_banner "DETECTED: Standalone Environment" "$PURPLE"
    if [ "$USE_SUDO" = false ] && check_sudo_needed; then
        print_warning "Standalone environment detected and elevated privileges needed"
        print_warning "Consider running with --with-sudo option"
        echo ""
    fi
fi

print_banner "KRYTPONYTE DEVELOPMENT ENVIRONMENT SETUP" "$WHITE"
echo -e "${CYAN}This will install all tools needed for KryptoNyte development${NC}"
echo -e "${CYAN}Installation may take several minutes...${NC}"
echo ""
echo "Configuration:"
echo "  Using sudo: $USE_SUDO"
echo "  Verbose output: $VERBOSE"
echo "  Environment: $(if is_codespace; then echo "Codespace"; else echo "Standalone"; fi)"

# Update PATH for current session
print_step "Setting up PATH for current session"
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/oss-cad-suite/bin:$PATH"

# Update ~/.bashrc with PATH additions
print_step "Updating ~/.bashrc with PATH additions"
cat >> ~/.bashrc << 'EOF'
# KryptoNyte Development Tools
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    export PATH="/usr/local/bin:$PATH"
fi
if [[ ":$PATH:" != *":/opt/oss-cad-suite/bin:"* ]]; then
    export PATH="/opt/oss-cad-suite/bin:$PATH"
fi
EOF

#######################################
# Setup Package Management 
#######################################
print_banner "CONFIGURING PACKAGE MANAGEMENT" "$CYAN"

# Set non-interactive mode to prevent prompts and warnings
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

print_step "Updating package lists"
run_cmd apt update || {
    print_error "Failed to update package lists"
    exit 1
}

print_step "Installing apt-utils to prevent debconf warnings"
run_cmd apt install -y apt-utils || {
    print_warning "Failed to install apt-utils (continuing anyway)"
}

print_step "Cleaning package cache"
run_cmd apt clean

print_success "Package management configured"


#######################################
# Install GCC 14
#######################################
print_banner "INSTALLING GCC 14 COMPILER" "$BLUE"

print_step "Adding Ubuntu toolchain repository"
run_cmd add-apt-repository -y ppa:ubuntu-toolchain-r/ppa || {
    print_error "Failed to add Ubuntu toolchain repository"
    exit 1
}

print_step "Updating package lists"
run_cmd apt update || {
    print_error "Failed to update package lists"
    exit 1
}

print_step "Installing GCC 14 and G++ 14"
run_cmd apt install -y gcc-14 g++-14 && run_cmd apt clean || {
    print_error "Failed to install GCC 14"
    exit 1
}

print_step "Setting up GCC 14 as default compiler"
run_cmd update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
run_cmd update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
run_cmd update-alternatives --set gcc /usr/bin/gcc-14 && \
run_cmd update-alternatives --set g++ /usr/bin/g++-14 || {
    print_error "Failed to set GCC 14 as default"
    exit 1
}

print_success "GCC 14 installed and configured"
gcc --version | head -1

#######################################
# Install SDKMAN and Java/Scala tools
#######################################
print_banner "INSTALLING SDKMAN WITH JAVA, SBT, AND SCALA" "$GREEN"

print_step "Downloading and installing SDKMAN"
curl -s "https://get.sdkman.io" | bash || {
    print_error "Failed to install SDKMAN"
    exit 1
}

print_step "Installing Java 23, SBT, and Scala via SDKMAN"
bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && \
            sdk install java 23.0.1-oracle --default && \
            sdk install sbt && \
            sdk install scala 2.13.15 --default" || {
    print_error "Failed to install Java/Scala tools via SDKMAN"
    exit 1
}

print_success "SDKMAN and Java/Scala tools installed"

#######################################
# Install Verilator
#######################################
print_banner "INSTALLING VERILATOR HDL SIMULATOR" "$YELLOW"

print_step "Installing Verilator from package manager"
run_cmd apt install -y verilator || {
    print_error "Failed to install Verilator"
    exit 1
}

print_success "Verilator installed"
verilator --version | head -1

#######################################
# Install FIRRTL tools
#######################################
print_banner "INSTALLING FIRRTL TOOLS (FIRTOOL)" "$PURPLE"

print_step "Fetching latest FIRRTL tools release"
FIRTOOL_URL=$(curl -s https://api.github.com/repos/llvm/circt/releases/latest | \
    jq -r '.assets[] | select(.name == "firrtl-bin-linux-x64.tar.gz") | .browser_download_url')

if [ -z "$FIRTOOL_URL" ] || [ "$FIRTOOL_URL" = "null" ]; then
    print_error "Failed to fetch FIRRTL tools release information"
    exit 1
fi

print_step "Downloading FIRRTL tools"
if ! wget --no-check-certificate "$FIRTOOL_URL" -O /tmp/firtool.tar.gz; then
    print_error "Failed to download FIRRTL tools"
    exit 1
fi

print_step "Extracting FIRRTL tools"
mkdir -p /tmp/firtool
if ! tar -xzf /tmp/firtool.tar.gz -C /tmp/firtool; then
    print_error "Failed to extract FIRRTL tools archive"
    rm -rf /tmp/firtool /tmp/firtool.tar.gz
    exit 1
fi

print_step "Locating firtool binary"
FIRTOOL_PATH=$(find /tmp/firtool -type f -name firtool -executable 2>/dev/null | head -1)

if [ -z "$FIRTOOL_PATH" ]; then
    print_error "firtool binary not found in extracted archive"
    print_step "Archive contents:"
    find /tmp/firtool -type f -name "*firtool*" 2>/dev/null || echo "No firtool files found"
    rm -rf /tmp/firtool /tmp/firtool.tar.gz
    exit 1
fi

print_step "Installing firtool to /usr/local/bin"
if run_cmd mv "$FIRTOOL_PATH" /usr/local/bin/firtool; then
    run_cmd chmod +x /usr/local/bin/firtool
    print_success "FIRRTL tools (firtool) installed"
else
    print_error "Failed to install firtool to /usr/local/bin"
    rm -rf /tmp/firtool /tmp/firtool.tar.gz
    exit 1
fi

# Cleanup
rm -rf /tmp/firtool /tmp/firtool.tar.gz

# Verify installation
if command -v firtool >/dev/null 2>&1; then
    firtool --version | head -1
else
    print_error "firtool installation verification failed"
    exit 1
fi


#######################################
# Install OSS-CAD Suite
#######################################
print_banner "INSTALLING OSS-CAD SUITE (YOSYS, NEXTPNR, ETC.)" "$CYAN"

print_step "Fetching latest OSS-CAD Suite release"
OSS_CAD_URL=$(curl -s https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest | \
    jq -r '.assets[] | select(.name | contains("linux-x64")) | .browser_download_url') || {
    print_error "Failed to fetch OSS-CAD Suite release information"
    exit 1
}

print_step "Downloading OSS-CAD Suite (this may take a while)"
wget --no-check-certificate "$OSS_CAD_URL" -O /tmp/oss-cad-suite.tar.xz || {
    print_error "Failed to download OSS-CAD Suite"
    exit 1
}

print_step "Installing OSS-CAD Suite to /opt/oss-cad-suite"
run_cmd mkdir -p /opt/oss-cad-suite && \
run_cmd tar -xf /tmp/oss-cad-suite.tar.xz -C /opt/oss-cad-suite --strip-components=1 && \
rm /tmp/oss-cad-suite.tar.xz || {
    print_error "Failed to install OSS-CAD Suite"
    exit 1
}

print_success "OSS-CAD Suite installed"
/opt/oss-cad-suite/bin/yosys --version | head -1

#######################################
# Install Node.js and netlistsvg
#######################################
print_banner "INSTALLING NODE.JS AND NETLISTSVG" "$GREEN"

print_step "Installing Node.js 22.x"
curl -fsSL https://deb.nodesource.com/setup_22.x | run_cmd bash - || {
    print_error "Failed to add Node.js repository"
    exit 1
}

run_cmd apt install -y nodejs && run_cmd apt clean || {
    print_error "Failed to install Node.js"
    exit 1
}

print_step "Updating npm to latest version"
run_cmd npm install -g npm@latest || {
    print_error "Failed to update npm"
    exit 1
}

print_step "Installing netlistsvg globally"
run_cmd npm install -g netlistsvg || {
    print_error "Failed to install netlistsvg"
    exit 1
}

print_success "Node.js and netlistsvg installed"
node --version
npm --version

#######################################
# Install sv2v 
#######################################
print_banner "INSTALLING SV2V SYSTEMVERILOG CONVERTER" "$BLUE"

print_step "Fetching latest sv2v release"
SV2V_URL=$(curl -s https://api.github.com/repos/zachjs/sv2v/releases/latest | \
    jq -r '.assets[] | select(.name == "sv2v-Linux.zip") | .browser_download_url')

if [ -z "$SV2V_URL" ] || [ "$SV2V_URL" = "null" ]; then
    print_error "Failed to fetch sv2v release information"
    exit 1
fi

print_step "Downloading sv2v"
if ! wget "$SV2V_URL" -O /tmp/sv2v.zip; then
    print_error "Failed to download sv2v"
    exit 1
fi

print_step "Extracting sv2v"
mkdir -p /tmp/sv2v
if ! unzip /tmp/sv2v.zip -d /tmp/sv2v; then
    print_error "Failed to extract sv2v archive"
    rm -rf /tmp/sv2v /tmp/sv2v.zip
    exit 1
fi

print_step "Locating sv2v binary"
SV2V_PATH=$(find /tmp/sv2v -type f -name sv2v -executable 2>/dev/null | head -1)

if [ -z "$SV2V_PATH" ]; then
    print_error "sv2v binary not found in extracted archive"
    print_step "Archive contents:"
    find /tmp/sv2v -type f -name "*sv2v*" 2>/dev/null || echo "No sv2v files found"
    rm -rf /tmp/sv2v /tmp/sv2v.zip
    exit 1
fi

print_step "Installing sv2v to /usr/local/bin"
if run_cmd mv "$SV2V_PATH" /usr/local/bin/sv2v; then
    run_cmd chmod +x /usr/local/bin/sv2v
    print_success "sv2v installed"
else
    print_error "Failed to install sv2v to /usr/local/bin"
    rm -rf /tmp/sv2v /tmp/sv2v.zip
    exit 1
fi

# Cleanup
rm -rf /tmp/sv2v /tmp/sv2v.zip

# Verify installation
if command -v sv2v >/dev/null 2>&1; then
    sv2v --version
else
    print_error "sv2v installation verification failed"
    exit 1
fi


#######################################
# Install Graphics Tools
#######################################
print_banner "INSTALLING GRAPHICS TOOLS (RSVG-CONVERT, INKSCAPE)" "$PURPLE"

print_step "Updating package lists"
run_cmd apt update || {
    print_error "Failed to update package lists"
    exit 1
}

print_step "Installing graphics tools"
run_cmd apt install -y \
    librsvg2-bin \
    inkscape \
    && run_cmd apt clean || {
    print_error "Failed to install graphics tools"
    exit 1
}

print_success "Graphics tools installed"
rsvg-convert --version | head -1
inkscape --version | head -1

#######################################
# Final Setup and Verification
#######################################
print_banner "SETUP COMPLETE - VERIFYING INSTALLATION" "$WHITE"

echo ""
echo -e "${GREEN}🎉 KryptoNyte Development Environment Setup Complete! 🎉${NC}"
echo ""
echo "Installed tools:"
echo -e "  ${CYAN}✓ GCC 14:${NC}        $(gcc --version | head -1)"
echo -e "  ${CYAN}✓ Verilator:${NC}     $(verilator --version | head -1)"
echo -e "  ${CYAN}✓ firtool:${NC}       $(firtool --version | head -1)"
echo -e "  ${CYAN}✓ Yosys:${NC}         $(/opt/oss-cad-suite/bin/yosys --version | head -1)"
echo -e "  ${CYAN}✓ Node.js:${NC}       $(node --version)"
echo -e "  ${CYAN}✓ sv2v:${NC}          $(sv2v --version)"
echo -e "  ${CYAN}✓ rsvg-convert:${NC}  $(rsvg-convert --version | head -1)"
echo -e "  ${CYAN}✓ Inkscape:${NC}      $(inkscape --version | head -1)"

echo ""
echo "SDKMAN tools (source ~/.sdkman/bin/sdkman-init.sh to use):"
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
    echo -e "  ${CYAN}✓ Java:${NC}          $(java --version 2>/dev/null | head -1 || echo "Available via SDKMAN")"
    echo -e "  ${CYAN}✓ Scala:${NC}         $(scala --version 2>/dev/null || echo "Available via SDKMAN")"
    echo -e "  ${CYAN}✓ SBT:${NC}           $(sbt --version 2>/dev/null || echo "Available via SDKMAN")"
else
    echo -e "  ${YELLOW}⚠ SDKMAN tools available after sourcing ~/.sdkman/bin/sdkman-init.sh${NC}"
fi

echo ""
echo "Next steps:"
if is_codespace; then
    echo "  1. Your Codespace is ready for KryptoNyte development!"
    echo "  2. SDKMAN tools are automatically available in new terminals"
else
    echo "  1. Start a new terminal session or run: source ~/.bashrc"
    echo "  2. For SDKMAN tools, run: source ~/.sdkman/bin/sdkman-init.sh"
fi
echo "  3. Begin developing your KryptoNyte processor cores!"

echo ""
print_success "All tools successfully installed and configured!"

unset DEBIAN_FRONTEND
unset DEBCONF_NONINTERACTIVE_SEEN


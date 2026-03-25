#!/usr/bin/env bash

################################################################################
# Docker Engine Installation Script for Ubuntu
# 
# Description: Installs Docker Engine following official documentation
# Supported: Ubuntu 22.04, 24.04, 25.10
# References:
#   - https://docs.docker.com/engine/install/ubuntu/
#   - https://docs.docker.com/engine/install/linux-postinstall/
#
# Usage:
#   sudo ./install.sh [OPTIONS]
#
# Options:
#   --version <ver>        Install specific Docker version (default: latest)
#   --list-versions        List available Docker versions and exit
#   --non-interactive      Run without prompts (auto-confirm all)
#   --skip-postinstall     Skip adding user to docker group
#   --help                 Show this help message
#
# Exit Codes:
#   0   Success
#   1   General error
#   2   Not Ubuntu or unsupported version
#   3   Not running with sudo
#   4   User declined to proceed
#   5   Docker already installed (use --force to reinstall)
################################################################################

set -euo pipefail

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="/var/log/docker-install.log"
readonly DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
readonly DOCKER_GPG_KEY="/etc/apt/keyrings/docker.asc"
readonly DOCKER_SOURCES_FILE="/etc/apt/sources.list.d/docker.sources"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------
DOCKER_VERSION="latest"
NON_INTERACTIVE=false
SKIP_POSTINSTALL=false
LIST_VERSIONS=false

#------------------------------------------------------------------------------
# Logging Functions
#------------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

show_help() {
    cat << EOF
Docker Engine Installation Script for Ubuntu v${SCRIPT_VERSION}

Usage: sudo $0 [OPTIONS]

Options:
  --version <ver>        Install specific Docker version (e.g., 29.2.1)
                         Default: latest
  --list-versions        List available Docker versions and exit
  --non-interactive      Run without prompts (auto-confirm all)
  --skip-postinstall     Skip adding user to docker group
  --help                 Show this help message

Examples:
  # Install latest version
  sudo $0

  # Install specific version
  sudo $0 --version 29.2.1

  # List available versions
  $0 --list-versions

  # Non-interactive installation (for CI/CD)
  sudo $0 --non-interactive

Exit Codes:
  0   Success
  1   General error
  2   Not Ubuntu or unsupported version
  3   Not running with sudo
  4   User declined to proceed
  5   Docker already installed

For detailed documentation, see README.md
For troubleshooting, see TROUBLESHOOTING.md

EOF
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log_info "Non-interactive mode: auto-accepting prompt"
        return 0
    fi
    
    local yn
    while true; do
        if [[ "$default" == "y" ]]; then
            read -rp "$prompt [Y/n]: " yn
            yn=${yn:-y}
        else
            read -rp "$prompt [y/N]: " yn
            yn=${yn:-n}
        fi
        
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

#------------------------------------------------------------------------------
# Validation Functions
#------------------------------------------------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo or as root"
        log_error "Usage: sudo $0"
        exit 3
    fi
    
    # Check if running as root directly (not via sudo)
    if [[ -z "${SUDO_USER:-}" ]]; then
        log_error "This script must be run with 'sudo', not as root directly"
        log_error "Reason: Cannot detect user to add to docker group"
        log_error "Usage: sudo $0"
        exit 3
    fi
    
    log_success "Running with sudo as user: $SUDO_USER"
}

check_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found. Cannot determine OS."
        exit 2
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script is for Ubuntu only. Detected: $ID"
        log_error "Please use the appropriate script for your distribution."
        exit 2
    fi
    
    # Check supported versions
    local supported_versions=("22.04" "24.04" "25.10")
    local version_supported=false
    
    for ver in "${supported_versions[@]}"; do
        if [[ "$VERSION_ID" == "$ver" ]]; then
            version_supported=true
            break
        fi
    done
    
    if [[ "$version_supported" == "false" ]]; then
        log_warn "Ubuntu $VERSION_ID is not officially tested"
        log_warn "Supported versions: ${supported_versions[*]}"
        if ! prompt_yes_no "Continue anyway?"; then
            log_error "Installation cancelled by user"
            exit 4
        fi
    fi
    
    log_success "Detected Ubuntu $VERSION_ID ($VERSION_CODENAME)"
}

check_architecture() {
    local arch=$(dpkg --print-architecture)
    local supported_archs=("amd64" "arm64" "armhf" "s390x" "ppc64el")
    
    if [[ ! " ${supported_archs[*]} " =~ ${arch} ]]; then
        log_error "Unsupported architecture: $arch"
        log_error "Supported: ${supported_archs[*]}"
        exit 2
    fi
    
    log_success "Architecture: $arch"
}

#------------------------------------------------------------------------------
# Docker Detection and Cleanup
#------------------------------------------------------------------------------

detect_conflicting_packages() {
    log_info "Checking for conflicting Docker packages..."
    
    local packages=("docker.io" "docker-compose" "docker-compose-v2" "docker-doc" "podman-docker" "containerd" "runc")
    local installed=()
    
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$pkg"; then
            local version=$(dpkg -l | grep "^ii.*$pkg" | awk '{print $3}')
            installed+=("$pkg ($version)")
        fi
    done
    
    if [[ ${#installed[@]} -eq 0 ]]; then
        log_success "No conflicting packages found"
        return 0
    fi
    
    log_warn "Conflicting Docker packages detected:"
    for pkg in "${installed[@]}"; do
        log_warn "  - $pkg"
    done
    
    echo ""
    log_warn "These packages conflict with Docker Engine from the official repository."
    log_warn "They must be removed before proceeding."
    
    if ! prompt_yes_no "Remove conflicting packages?"; then
        log_error "Cannot proceed with conflicting packages installed"
        exit 4
    fi
    
    log_info "Removing conflicting packages..."
    DEBIAN_FRONTEND=noninteractive apt-get remove -y \
        docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc \
        2>&1 | tee -a "$LOG_FILE" || true
    
    log_success "Conflicting packages removed"
}

check_docker_installed() {
    if command -v docker &> /dev/null; then
        local current_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_warn "Docker is already installed: $current_version"
        
        if ! prompt_yes_no "Reinstall or update Docker?"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
}

#------------------------------------------------------------------------------
# Installation Functions
#------------------------------------------------------------------------------

setup_docker_repository() {
    log_info "Setting up Docker's official APT repository..."
    
    # Install prerequisites
    log_info "Installing prerequisites..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        ca-certificates \
        curl \
        2>&1 | tee -a "$LOG_FILE"
    
    # Create keyrings directory
    log_info "Creating keyrings directory..."
    install -m 0755 -d /etc/apt/keyrings
    
    # Download Docker's GPG key
    log_info "Downloading Docker's GPG key..."
    curl -fsSL "$DOCKER_GPG_URL" -o "$DOCKER_GPG_KEY" 2>&1 | tee -a "$LOG_FILE"
    chmod a+r "$DOCKER_GPG_KEY"
    
    # Verify GPG key was downloaded
    if [[ ! -f "$DOCKER_GPG_KEY" ]]; then
        log_error "Failed to download Docker GPG key"
        exit 1
    fi
    
    log_success "GPG key installed: $DOCKER_GPG_KEY"
    
    # Add Docker repository
    log_info "Adding Docker repository to APT sources..."
    source /etc/os-release
    local codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
    
    cat > "$DOCKER_SOURCES_FILE" << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${codename}
Components: stable
Signed-By: ${DOCKER_GPG_KEY}
EOF
    
    log_success "Docker repository configured: $DOCKER_SOURCES_FILE"
    
    # Update package index
    log_info "Updating package index..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Docker repository setup complete"
}

list_docker_versions() {
    log_info "Fetching available Docker versions..."
    
    # Ensure repository is set up
    if [[ ! -f "$DOCKER_SOURCES_FILE" ]]; then
        log_warn "Docker repository not configured. Setting up..."
        DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl 2>&1 | tee -a "$LOG_FILE"
        setup_docker_repository
    fi
    
    echo ""
    echo "Available Docker Engine versions:"
    echo "=================================="
    apt-cache madison docker-ce | awk '{print $3}' | head -20
    echo ""
    echo "Showing latest 20 versions. For more, run: apt-cache madison docker-ce"
}

install_docker() {
    log_info "Installing Docker Engine..."
    
    local packages=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-buildx-plugin"
        "docker-compose-plugin"
    )
    
    if [[ "$DOCKER_VERSION" == "latest" ]]; then
        log_info "Installing latest version of Docker..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            "${packages[@]}" \
            2>&1 | tee -a "$LOG_FILE"
    else
        log_info "Installing Docker version: $DOCKER_VERSION"
        
        # Find full package version string
        local full_version=$(apt-cache madison docker-ce | grep "$DOCKER_VERSION" | head -1 | awk '{print $3}')
        
        if [[ -z "$full_version" ]]; then
            log_error "Docker version $DOCKER_VERSION not found"
            log_info "Run '$0 --list-versions' to see available versions"
            exit 1
        fi
        
        log_info "Full version string: $full_version"
        
        # Install specific version
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            docker-ce="$full_version" \
            docker-ce-cli="$full_version" \
            containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin \
            2>&1 | tee -a "$LOG_FILE"
    fi
    
    log_success "Docker Engine installed successfully"
}

#------------------------------------------------------------------------------
# Post-Installation
#------------------------------------------------------------------------------

configure_postinstall() {
    if [[ "$SKIP_POSTINSTALL" == "true" ]]; then
        log_info "Skipping post-installation configuration (--skip-postinstall)"
        return 0
    fi
    
    log_info "Configuring post-installation settings..."
    
    # Create docker group (if it doesn't exist)
    if ! getent group docker > /dev/null 2>&1; then
        log_info "Creating docker group..."
        groupadd docker
        log_success "Docker group created"
    else
        log_info "Docker group already exists"
    fi
    
    # Add user to docker group
    local target_user="$SUDO_USER"
    log_info "Adding user '$target_user' to docker group..."
    usermod -aG docker "$target_user"
    log_success "User '$target_user' added to docker group"
    
    # Enable Docker service
    log_info "Enabling Docker service to start on boot..."
    systemctl enable docker.service 2>&1 | tee -a "$LOG_FILE"
    systemctl enable containerd.service 2>&1 | tee -a "$LOG_FILE"
    log_success "Docker service enabled"
    
    # Start Docker service
    log_info "Starting Docker service..."
    systemctl start docker.service 2>&1 | tee -a "$LOG_FILE"
    log_success "Docker service started"
    
    log_success "Post-installation configuration complete"
}

#------------------------------------------------------------------------------
# Verification
#------------------------------------------------------------------------------

verify_installation() {
    log_info "Verifying Docker installation..."
    
    # Check Docker version
    if ! command -v docker &> /dev/null; then
        log_error "Docker command not found after installation"
        exit 1
    fi
    
    local docker_version=$(docker --version)
    log_success "Docker installed: $docker_version"
    
    # Check Docker Compose
    local compose_version=$(docker compose version)
    log_success "Docker Compose installed: $compose_version"
    
    # Check Docker service status
    if systemctl is-active --quiet docker; then
        log_success "Docker service is running"
    else
        log_warn "Docker service is not running"
        log_info "Starting Docker service..."
        systemctl start docker
    fi
    
    # Test Docker with hello-world
    log_info "Testing Docker with hello-world image..."
    if docker run --rm hello-world > /dev/null 2>&1; then
        log_success "Docker is working correctly"
    else
        log_warn "Could not run hello-world container"
        log_warn "This may be normal if running as sudo (user not in docker group yet)"
    fi
}

#------------------------------------------------------------------------------
# Main Installation Flow
#------------------------------------------------------------------------------

main() {
    # Print banner
    echo ""
    echo "=========================================="
    echo "  Docker Engine Installation for Ubuntu"
    echo "  Version: $SCRIPT_VERSION"
    echo "=========================================="
    echo ""
    
    # Initialize log file
    : > "$LOG_FILE"
    log_info "Installation started"
    
    # Validation
    check_root
    check_ubuntu
    check_architecture
    
    # Handle --list-versions
    if [[ "$LIST_VERSIONS" == "true" ]]; then
        list_docker_versions
        exit 0
    fi
    
    # Check for existing installation
    check_docker_installed
    
    # Detect and remove conflicting packages
    detect_conflicting_packages
    
    # Setup Docker repository
    setup_docker_repository
    
    # Install Docker
    install_docker
    
    # Post-installation
    configure_postinstall
    
    # Verify installation
    verify_installation
    
    # Final messages
    echo ""
    echo "=========================================="
    log_success "Docker installation completed successfully!"
    echo "=========================================="
    echo ""
    
    if [[ "$SKIP_POSTINSTALL" == "false" ]]; then
        log_info "IMPORTANT: Log out and log back in for group changes to take effect"
        log_info "Or run: newgrp docker"
        echo ""
        log_info "Test Docker without sudo:"
        echo "  $ docker run hello-world"
    fi
    
    echo ""
    log_info "Installed versions:"
    echo "  Docker Engine: $(docker --version)"
    echo "  Docker Compose: $(docker compose version)"
    echo ""
    log_info "Installation log saved to: $LOG_FILE"
    echo ""
}

#------------------------------------------------------------------------------
# Argument Parsing
#------------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                DOCKER_VERSION="$2"
                shift 2
                ;;
            --list-versions)
                LIST_VERSIONS=true
                shift
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --skip-postinstall)
                SKIP_POSTINSTALL=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

#------------------------------------------------------------------------------
# Entry Point
#------------------------------------------------------------------------------

# Parse arguments
parse_args "$@"

# Run main installation
main

exit 0

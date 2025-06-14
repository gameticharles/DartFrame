#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

GEOS_VERSION="3.13.1"
GEOS_TARBALL="geos-${GEOS_VERSION}.tar.bz2"
GEOS_DOWNLOAD_URL="https://download.osgeo.org/geos/${GEOS_TARBALL}"
GEOS_SOURCE_DIR="geos-${GEOS_VERSION}"
INSTALL_DIR_NAME="geos_install" # Directory name for installed GEOS libs/includes

# Get the absolute path of the script's directory (project root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
FULL_INSTALL_PATH="${SCRIPT_DIR}/${INSTALL_DIR_NAME}"
BUILD_TEMP_DIR="geos_build_temp"

echo "GEOS Build Script"
echo "-------------------"
echo "This script will download GEOS ${GEOS_VERSION}, build it, and install it into:"
echo "${FULL_INSTALL_PATH}"
echo ""
read -p "Do you want to continue? (y/n): " choice
case "$choice" in
  y|Y ) echo "Proceeding with GEOS build...";;
  n|N ) echo "Exiting."; exit 0;;
  * ) echo "Invalid choice. Exiting."; exit 1;;
esac

# Clean up previous attempts
echo "Cleaning up previous build attempts if any..."
rm -rf "${BUILD_TEMP_DIR}"
rm -rf "${FULL_INSTALL_PATH}" # Also remove previous install dir to ensure fresh install

# Create a temporary directory for building
echo "Creating temporary build directory: ${BUILD_TEMP_DIR}"
mkdir -p "${BUILD_TEMP_DIR}"
cd "${BUILD_TEMP_DIR}"

# Download GEOS
if [ -f "${GEOS_TARBALL}" ]; then
    echo "GEOS tarball already downloaded."
else
    echo "Downloading GEOS ${GEOS_VERSION} from ${GEOS_DOWNLOAD_URL}..."
    if command -v curl &> /dev/null; then
        curl -L -O "${GEOS_DOWNLOAD_URL}"
    elif command -v wget &> /dev/null; then
        wget "${GEOS_DOWNLOAD_URL}"
    else
        echo "Error: Neither curl nor wget found. Please install one and try again."
        exit 1
    fi
fi

# Extract GEOS
echo "Extracting ${GEOS_TARBALL}..."
tar -xjf "${GEOS_TARBALL}"

# Navigate to GEOS source directory
cd "${GEOS_SOURCE_DIR}"

# Create build directory for CMake
echo "Creating CMake build directory..."
mkdir -p build
cd build

# Configure CMake
# We point CMAKE_INSTALL_PREFIX to the absolute path created earlier
echo "Configuring CMake with install prefix: ${FULL_INSTALL_PATH}..."
cmake -DCMAKE_BUILD_TYPE=Release       -DCMAKE_INSTALL_PREFIX="${FULL_INSTALL_PATH}"       ..

# Build GEOS
echo "Building GEOS... (This may take a while)"
make -j$(nproc || sysctl -n hw.ncpu || echo 2) # Use multiple cores if possible

# Install GEOS
echo "Installing GEOS to ${FULL_INSTALL_PATH}..."
make install

# Navigate back to the project root
cd "${SCRIPT_DIR}"

# Clean up temporary build directory (optional)
# read -p "Build and installation complete. Remove temporary build directory ${BUILD_TEMP_DIR}? (y/n): " cleanup_choice
# case "$cleanup_choice" in
#   y|Y ) rm -rf "${BUILD_TEMP_DIR}"; echo "${BUILD_TEMP_DIR} removed.";;
#   * ) echo "Temporary build directory ${BUILD_TEMP_DIR} was not removed.";;
# esac

echo "GEOS ${GEOS_VERSION} build and installation complete."
echo "Installed files are in: ${FULL_INSTALL_PATH}"
echo "This directory should contain include/ and lib/ subdirectories."
echo "Make sure to add ${FULL_INSTALL_PATH}/lib to your dynamic linker path (e.g., LD_LIBRARY_PATH or DYLD_LIBRARY_PATH) if you intend to run programs linking against these libraries outside of a build system that knows this path."

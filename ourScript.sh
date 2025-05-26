#!/bin/bash

echo "=== Fixing MobileInsight for Raspberry Pi ==="

# Remove the incompatible installation
echo "Removing incompatible MobileInsight installation..."
sudo rm -rf /usr/local/lib/python3.12/dist-packages/MobileInsight-*

# Install required build dependencies for Raspberry Pi
echo "Installing build dependencies..."
sudo apt update
sudo apt install -y python3-dev python3-setuptools python3-wheel build-essential

# Go to your source directory
cd ~/laksh/mobileinsight-core

# Clean any previous builds
echo "Cleaning previous builds..."
sudo python3 setup.py clean --all
rm -rf build/
rm -rf dist/
find . -name "*.so" -delete
find . -name "*.pyc" -delete
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Rebuild from source for ARM64
echo "Building MobileInsight from source for ARM64..."
python3 setup.py build

if [ $? -ne 0 ]; then
    echo "Build failed. This might be due to Python 3.12 compatibility issues."
    echo "Let's try with some compatibility flags..."
    
    # Try with compatibility flags
    CFLAGS="-DPY_SSIZE_T_CLEAN" python3 setup.py build
    
    if [ $? -ne 0 ]; then
        echo "Build still failed. You may need to fix C extension compatibility manually."
        exit 1
    fi
fi

# Install the rebuilt version
echo "Installing rebuilt MobileInsight..."
sudo python3 setup.py install --break-system-packages

# Test the installation
echo "Testing installation..."
python3 -c "import mobile_insight; print('MobileInsight version:', mobile_insight.__version__)"

if [ $? -eq 0 ]; then
    echo "✅ MobileInsight successfully rebuilt for Raspberry Pi!"
    
    # Test the offline example
    echo "Testing offline analysis example..."
    cd examples
    python3 offline-analysis-example.py
    
    if [ $? -eq 0 ]; then
        echo "✅ Offline analysis example works!"
    else
        echo "❌ Offline analysis example still has issues"
    fi
else
    echo "❌ Installation verification failed"
    exit 1
fi

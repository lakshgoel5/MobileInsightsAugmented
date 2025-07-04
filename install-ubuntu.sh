#!/bin/bash
# Installation script for mobileinsight-core on Ubuntu
# It installs package under /usr/local folder

# set -e
# set -u

echo "** Installer Script for mobileinsight-core on Ubuntu **"
echo " "
echo "  Author : Zengwen Yuan (zyuan [at] cs.ucla.edu), Haotian Deng (deng164 [at] purdue.edu), Yuanjie Li (yuanjiel [at] tsinghua.edu.cn)"
echo "  Date   : 2020-10-20"
echo "  Rev    : 4.0"
echo "  Usage  : ./install-ubuntu.sh"
echo " "

echo "Upgrading MobileInsight..."
yes | ./uninstall.sh

# Wireshark version to install
ws_ver=3.4.0

# Use local library path
#TODO
PREFIX=/usr/local
MOBILEINSIGHT_PATH=$(pwd)
WIRESHARK_SRC_PATH=${MOBILEINSIGHT_PATH}/wireshark-${ws_ver}

PYTHON=python3
PIP=pip3

echo "Installing dependencies for compiling Wireshark libraries"
# Updated package names for newer Ubuntu versions
sudo apt-get -y install cmake pkg-config wget libglib2.0-dev bison flex libpcap-dev libgcrypt20-dev qtbase5-dev qttools5-dev qtchooser qt5-qmake qtbase5-dev-tools qtmultimedia5-dev libqt5svg5-dev libc-ares-dev libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-2.0-0


echo "Checking Wireshark sources to compile ws_dissector"
if [ ! -d "${WIRESHARK_SRC_PATH}" ]; then
    echo "You do not have source codes for Wireshark version ${ws_ver}, downloading..."

    wget  http://www.mobileinsight.net/wireshark-${ws_ver}-rbc-dissector.tar.xz -O wireshark-${ws_ver}.tar.xz
    # wget https://www.wireshark.org/download/src/all-versions/wireshark-${ws_ver}.tar.xz
    tar -xf wireshark-${ws_ver}.tar.xz
    rm wireshark-${ws_ver}.tar.xz
fi

echo "Configuring Wireshark sources for ws_dissector compilation..."
cd ${WIRESHARK_SRC_PATH}
cmake -DBUILD_wireshark=OFF . > /dev/null 2>&1
if [ $? != 0 ]; then
    echo "Error when executing '${WIRESHARK_SRC_PATH}/cmake --disable-wireshark .'"
    echo "You need to manually fix it before continuation. Exiting with status 3"
    exit 3
fi

echo "Check if proper version of wireshark dynamic library exists in system path..."

# FindWiresharkLibrary=true

# if readelf -d "/usr/local/lib/libwireshark.so" | grep "SONAME" | grep "libwireshark.so.13" ; then
#     echo "Found libwireshark.so.13 being used"
# else
#     echo "Didn't find libwireshark.so.13"
#     FindWiresharkLibrary=false
# fi

# if readelf -d "/usr/local/lib/libwiretap.so" | grep "SONAME" | grep "libwiretap.so.10" ; then
#     echo "Found libwiretap.so.10 being used"
# else
#     echo "Didn't find libwiretap.so.10"
#     FindWiresharkLibrary=false
# fi

# if readelf -d "/usr/local/lib/libwsutil.so" | grep "SONAME" | grep "libwsutil.so.11" ; then
#     echo "Found libwsutil.so.11 being used"
# else
#     echo "Didn't find libwsutil.so.11"
#     FindWiresharkLibrary=false
# fi

# if [ "$FindWiresharkLibrary" = false ] ; then
echo "Compiling wireshark-${ws_ver} from source code, it may take a few minutes..."
make -j $(grep -c ^processor /proc/cpuinfo)
if [ $? != 0 ]; then
    echo "Error when compiling wireshark-${ws_ver} from source code'."
    echo "You need to manually fix it before continuation. Exiting with status 2"
    exit 2
fi
echo "Installing wireshark-${ws_ver}"
sudo make install > /dev/null 2>&1
if [ $? != 0 ]; then
    echo "Error when installing wireshark-${ws_ver} compiled from source code'."
    echo "You need to manually fix it before continuation. Exiting with status 2"
    exit 2
fi
# fi

echo "Reload ldconfig cache, your password may be required..."
sudo rm /etc/ld.so.cache
sudo ldconfig

echo "Compiling Wireshark dissector for mobileinsight..."
cd ${MOBILEINSIGHT_PATH}/ws_dissector
if [ -e "ws_dissector" ]; then
    rm -f ws_dissector
fi
g++ ws_dissector.cpp packet-aww.cpp -o ws_dissector `pkg-config --libs --cflags glib-2.0` \
    -I"${WIRESHARK_SRC_PATH}" -L"${PREFIX}/lib" -lwireshark -lwsutil -lwiretap
strip ws_dissector

echo "Installing Wireshark dissector to ${PREFIX}/bin"
sudo cp ws_dissector ${PREFIX}/bin/
sudo chmod 755 ${PREFIX}/bin/ws_dissector


echo "Compiling MobileInsight C++ extensions..."
cd ${MOBILEINSIGHT_PATH}
${PYTHON} setup.py build_ext --inplace
if [ $? != 0 ]; then
    echo "Error when compiling MobileInsight C++ extensions."
    echo "You need to manually fix it before continuation. Exiting with status 5"
    exit 5
fi
echo "MobileInsight C++ extensions compiled successfully!"


echo "Installing dependencies for mobileinsight GUI..."

# Update package list
sudo apt-get update

# Install wxPython - try different package names
echo "Installing wxPython..."
if sudo apt-get -y install python3-wxgtk4.0; then
    echo "python3-wxgtk4.0 installed successfully"
elif sudo apt-get -y install python3-wx; then
    echo "python3-wx installed successfully"
else
    echo "Warning: Could not install wxPython via apt. You may need to install it manually."
fi

# Install other Python dependencies via system packages
echo "Installing Python dependencies via system packages..."
sudo apt-get -y install python3-matplotlib python3-serial python3-pip python3-setuptools python3-dev

# Check if system packages worked
python3 -c "import matplotlib, serial" 2>/dev/null

if [ $? = 0 ]; then
    echo "matplotlib and pyserial are successfully installed via system packages!"
else
    echo "Warning: Could not install matplotlib and pyserial via system packages."
    echo "You may need to install them manually or check install script."
fi
# else
#     echo "System packages not available, creating virtual environment..."
    
#     # Create virtual environment if system packages don't work
#     python3 -m venv ~/mobileinsight-env
#     source ~/mobileinsight-env/bin/activate
    
#     # Install via pip in virtual environment
#     pip install matplotlib pyserial
    
#     if [ $? = 0 ]; then
#         echo "matplotlib and pyserial installed in virtual environment!"
#         echo "To use MobileInsight, activate the environment first:"
#         echo "source ~/mobileinsight-env/bin/activate"
#     else
#         echo "Error: Could not install Python dependencies"
#         exit 1
#     fi
# fi

echo "Dependencies installation completed!"

echo "Installing mobileinsight-core..."
cd ${MOBILEINSIGHT_PATH}
echo "Installing mobileinsight-core using sudo, your password may be required..."
sudo ${PYTHON} setup.py build_ext --inplace
sudo ${PYTHON} setup.py install --break-system-packages

echo "Installing GUI for MobileInsight..."
cd ${MOBILEINSIGHT_PATH}
sudo mkdir -p ${PREFIX}/share/mobileinsight/
sudo cp -r gui/* ${PREFIX}/share/mobileinsight/
sudo ln -s ${PREFIX}/share/mobileinsight/mi-gui ${PREFIX}/bin/mi-gui

echo "Testing the MobileInsight offline analysis example."
cd ${MOBILEINSIGHT_PATH}/examples
${PYTHON} offline-analysis-example.py
if [ $? -eq 0 ]; then
    echo "Successfully ran the offline analysis example!"
else
    echo "Failed to run offline analysis example!"
    echo "Exiting with status 4."
    exit 4
fi

echo "Testing MobileInsight GUI (you need to be in a graphic session)..."
mi-gui
if [[ $? == 0 ]] ; then
    echo "Successfully ran MobileInsight GUI!"
    echo "The installation of mobileinsight-core is finished!"
else
    echo "There are issues running MobileInsight GUI, you need to fix them manually"
    echo "The installation of mobileinsight-core is finished!"
fi

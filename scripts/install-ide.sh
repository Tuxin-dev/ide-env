#!/bin/bash
## ****************************************************************************
## @file        install-ide.sh
## @brief       Creation of a C/C++ development environment powered by Eclipse.
##
##              The environment consists of an installation of Eclipse CDT, as
##              well as the addition of multiple plugins useful for C/C++
##              development, and much more.
##
## @author      Tuxin (JPB)
## @version     1.2.0
## @since       Created 05/26/2019 (JPB)
## @since       Modified 02/01/2020 (JPB) - Adds some plugins
## @since       Modified 02/17/2020 (JPB) - Select the plugins installed
##                                          Adds Compilers installation
## @since       Modified 10/27/2020 (JPB) - Adds 'ANSI Escape in Console'
##                                          plugin.
##
## @date        October 27, 2020
##
## ****************************************************************************
#
# Script version
VERSION="1.2.0"
# ------------------- Customizable ---------------------

DEV_USERNAME="Tuxin"
DEV_EMAIL="tuxin@free.fr"

# Selects plugins to install
INSTALL_GITEXTEND=1	# Git Tools
INSTALL_JENKINS=1       # Jenkins integration
INSTALL_CHANGELOG=1     # Changelog management
INSTALL_UML=1           # UML Tools
INSTALL_RUST=1          # Rust Language
INSTALL_GOLANG=1        # Go Language
INSTALL_MCUARM=1        # ARM barebone dev tools
INSTALL_DOXYGEN=1       # Doxygen plugin
INSTALL_CPPCHECK=1      # Cppcheck plugin
INSTALL_THEME=1         # Eclipse Color Theme Plugin
INSTALL_BASH_EDITOR=1   # Bash editor plugin

# Default Directory for Eclipse installation.This
# variable can be overridden by the script's first
# command-line parameter. The last term of the path
# must end with "eclipse".
INSTALL_DIRECTORY="${HOME}/bin/eclipse"

# Default Workspace.This variable can be overridden
# by the script's second command-line parameter.
DEFAULT_WORKSPACE="${HOME}/eclipse-workspace"

# ECLIPSE VARIABLES
ECLIPSE_VERSION="2019-12"
ECLIPSE_REVISION="R"
ECLIPSE_ARCH="linux-gtk-x86_64"
CDT_VERSION="9.10"
# ------------------- End To adapt -----------------

# Read system informations
OS_TYPE=`uname -s`
if [ -e /etc/redhat-release ]; then
    REDHAT_CENTOS=1
elif [ -e /etc/lsb-release ]; then
    DEBIAN=1
fi

# Eclipse repository informations
ECLIPSE_TARBALL="eclipse-cpp-${ECLIPSE_VERSION}-${ECLIPSE_REVISION}-${ECLIPSE_ARCH}.tar.gz"
ASSETS_DIR=".."
ECLIPSE_URL="http://mirror.ibcp.fr/pub/eclipse/technology/epp/downloads/release/${ECLIPSE_VERSION}/${ECLIPSE_REVISION}/${ECLIPSE_TARBALL}"

if [ "$1" != "" ]; then
  INSTALL_DIRECTORY=${1}
  if [ "$2" != "" ]; then
    DEFAULT_WORKSPACE=${2}
  fi
fi

# Functions
help_message () {
  echo ""
  echo "Syntax : ${0} [install_dir] [workspace_name]"
  echo "" 
  exit 1
}

install_plugin () {
  if [ "$1" != "" -a "$2" != "" ]; then
    ${INSTALL_DIRECTORY}/eclipse -noSplash \
                        -application org.eclipse.equinox.p2.director \
                        -repository ${1} -installIU ${2} 2>/dev/null
  fi
}

# Installation 
# ------------
echo "Installing the C/C++ Development Environment"
echo "Version v$VERSION"
echo ""

# Existing installation control
if [ -e "${INSTALL_DIRECTORY}/eclipse" ]; then
    echo "An installation has already been done at ${INSTALL_DIRECTORY}."
    echo "Please delete it before starting a new one."
    exit 1
fi

# Create installation directory
ECLIPSE_PATH=`dirname ${INSTALL_DIRECTORY}`
mkdir -p $ECLIPSE_PATH
if [ ! -d $ECLIPSE_PATH ]; then
    echo "Can not create directory $ECLIPSE_PATH !"
    echo ""
    exit 2
fi

# Install Eclipse CDT
echo "Loading Eclipse CDT ..."
# ----------------------------------------------------------------------
if [ ! -e ${ASSETS_DIR}/${ECLIPSE_TARBALL} ]; then
    curl -o ${ASSETS_DIR}/${ECLIPSE_TARBALL} ${ECLIPSE_URL}
    if [ $? -ne 0 ]; then
        echo "Failed to download ${ECLIPSE_URL}"
        exit 3
    fi
fi
cp ${ASSETS_DIR}/${ECLIPSE_TARBALL} /tmp/eclipse-cdt.tar.gz

echo "Installing packages ..."
# ----------------------------------------------------------------------
if [ $EUID -neq 0 ]; then
    SUDO=sudo
else
    SUDO=
fi

if [ DEBIAN ]; then
    INSTALL_CMD="$SUDO apt-get install -y"
    REMOVE_CMD="$SUDO apt-get remove -y"
elif [ REDHAT_CENTOS ]; then
    INSTALL_CMD="$SUDO yum install"
    REMOVE_CMD="$SUDO yum remove"
fi

echo "Installing Java Runtime Environment"
${INSTALL_CMD} default-jre

echo "Installing C/C++ compiler"
${INSTALL_CMD} binutils-arm-linux-gnueabi binutils-arm-linux-gnueabihf
${INSTALL_CMD} g++-arm-linux-gnueabi g++-arm-linux-gnueabihf
${INSTALL_CMD} g++-multilib-arm-linux-gnueabi g++-multilib-arm-linux-gnueabihf
${INSTALL_CMD} gcc-arm-linux-gnueabi gcc-arm-linux-gnueabihf
${INSTALL_CMD} gcc-multilib-arm-linux-gnueabi gcc-multilib-arm-linux-gnueabihf
${INSTALL_CMD} binutils-arm-none-eabi gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib
${INSTALL_CMD} gdb gdb-multiarch gdbserver

if [ $INSTALL_GITEXTEND = "1" ]; then
    echo "Installing Git tools ..."
    ${INSTALL_CMD} git git-flow git-man git-review gitk
fi
if [ $INSTALL_RUST = "1" ]; then
    echo "Installing Rust compiler"
    dpkg --list 'rustc' >/dev/null 2>&1
    if [ "$?" == "0" ]; then
        ${REMOVE_CMD} rustc
    fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ~/.cargo/bin/rustup component add rls
    ${INSTALL_CMD} rustc rust-gdb libstd-rust-dev cargo
fi
if [ $INSTALL_DOXYGEN = "1" ]; then
    echo "Installing Doxygen ..."
    git clone https://github.com/doxygen/doxygen.git
    cd doxygen
    mkdir build
    cd build
    cmake -G "Unix Makefiles" ..
    make
    $SUDO make install
    cd ../..
    rm -R doxygen
fi

echo "Installing Eclipse ${ECLIPSE_VERSION} with CDT ${CDT_VERSION} ..."
# ----------------------------------------------------------------------
cd $ECLIPSE_PATH
tar xzf /tmp/eclipse-cdt.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to decompress in ${ECLIPSE_PATH}"
    exit 4
fi
rm /tmp/eclipse-cdt.tar.gz

# Change Splash Screen
if [ -e "${ASSETS_DIR}/splash.bmp" ]; then
    mv ${INSTALL_DIRECTORY}/plugins/org.eclipse.platform_*/splash.bmp \
       ${INSTALL_DIRECTORY}/plugins/org.eclipse.platform_*/splash.bmp.bak
    mv ${INSTALL_DIRECTORY}/plugins/org.eclipse.epp.package.common_*/splash.bmp \
       ${INSTALL_DIRECTORY}/plugins/org.eclipse.epp.package.common_*/splash.bmp.bak
    cp ${ASSETS_DIR}/splash.bmp \
       ${INSTALL_DIRECTORY}/plugins/org.eclipse.platform_*/
    cp ${ASSETS_DIR}/splash.bmp \
       ${INSTALL_DIRECTORY}/plugins/org.eclipse.epp.package.common_*/
fi

echo "Installing packages ..."
# ----------------------------------------------------------------------
if [ DEBIAN ]; then
    sudo apt-get install git git-flow git-man git-review gitk
elif [ REDHAT_CENTOS ]; then

fi

echo "Loading plugins ..."
# ----------------------------------------------------------------------
REPO_PLUGINS=http://download.eclipse.org/releases/${ECLIPSE_VERSION}
# ----------------------------------------------------------------------
#REPO_PLUGINS=http://download.eclipse.org/releases/latest

if [ $INSTALL_GITEXTEND == "1" ]; then
    echo "-> gitflow"
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.egit.gitflow.feature.feature.group

    echo "-> mylyn for git"
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.egit.mylyn.feature.group
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.mylyn.git.feature.group
fi

if [ $INSTALL_JENKINS == "1" ]; then
    echo "-> mylyn for jenkins"
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.mylyn.hudson.feature.group
fi

if [ $INSTALL_CHANGELOG == "1" ]; then
    echo "-> Changelog file maintener"
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.linuxtools.changelog.feature.group
fi

if [ $INSTALL_UML == "1" ]; then
    echo "-> Papyrus UML"
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.papyrus.sdk.feature.feature.group
fi

if [ $INSTALL_RUST == "1" ]; then
    echo "-> Corrosion : Rust Edition"
    install_plugin ${REPO_PLUGINS} \
                   org.eclipse.corrosion.feature.feature.group
fi

# ------------------------------------------------------------------------
REPO_PLUGINS=http://download.eclipse.org/tools/cdt/releases/${CDT_VERSION}
# ------------------------------------------------------------------------
# Already included in Eclipse CDT
# echo "-> Arduino C/C++ Tools"
# install_plugin ${REPO_PLUGINS} \
#                org.eclipse.cdt.arduino.feature.group

echo "-> Barre d'exécution pour CDT"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.launchbar.feature.group

# -------------------------------------------------------------
REPO_PLUGINS=http://gnu-mcu-eclipse.netlify.com/v4-neon-updates
# -------------------------------------------------------------
if [ $INSTALL_MCUARM == "1" ]; then
    echo "-> MCU ARM"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.managedbuild.cross.arm.feature.feature.group

    echo "-> CodeRed Debug Perspective for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.codered.feature.feature.group

    echo "-> MCU ARM Documentation"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.doc.user.feature.feature.group

    echo "-> Freescale Project Templates for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.templates.freescale.feature.feature.group

    echo "-> Generic Cortex-M Project Templates for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.templates.cortexm.feature.feature.group

    echo "-> OpenOCD Debugging for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.debug.gdbjtag.openocd.feature.feature.group

    echo "-> Packs for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.packs.feature.feature.group

    echo "-> QEMU Debugging for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.debug.gdbjtag.qemu.feature.feature.group

    echo "-> STM32Fx Project Templates for MCU"
    install_plugin ${REPO_PLUGINS} \
                   ilg.gnumcueclipse.templates.stm.feature.feature.group
fi

# ---------------------------------------
REPO_PLUGINS=http://anb0s.github.io/eclox
# ---------------------------------------
if [ $INSTALL_DOXYGEN == "1" ]; then
    echo "-> Doxygen for Eclipse"
    install_plugin ${REPO_PLUGINS} \
                   org.gna.eclox.feature.feature.group
fi

# ----------------------------------------------------------
REPO_PLUGINS=https://dl.bintray.com/cppcheclipse/p2/updates/
# ----------------------------------------------------------
if [ $INSTALL_CPPCHECK == "1" ]; then
    echo "-> Cppcheck"
    ${INSTALL_CMD}  cppcheck
    install_plugin ${REPO_PLUGINS} \
                   com.googlecode.cppcheclipse.feature.feature.group
fi

# --------------------------------------------------------
REPO_PLUGINS=https://eclipse-color-theme.github.com/update
# --------------------------------------------------------
if [ $INSTALL_THEME == "1" ]; then
    echo "-> Eclipse Color Theme"
    install_plugin ${REPO_PLUGINS} \
                   com.github.eclipsecolortheme.feature.feature.group
fi

# ----------------------------------------------------
REPO_PLUGINS=https://dl.bintray.com/de-jcup/basheditor
# ----------------------------------------------------
if [ $INSTALL_BASH_EDITOR == "1" ]; then
    echo "-> Bash Editor"
    install_plugin ${REPO_PLUGINS} \
                   com.github.eclipsecolortheme.feature.feature.group
fi

# ----------------------------------------------------
REPO_PLUGINS=http://hallvard.github.io/plantuml/
# ----------------------------------------------------
if [ $INSTALL_UML == "1" ]; then
    echo "-> Plant UML"
    install_plugin ${REPO_PLUGINS} \
                   net.sourceforge.plantuml.ecore.feature.feature.group

    install_plugin ${REPO_PLUGINS} \
                   net.sourceforge.plantuml.feature.feature.group

    install_plugin ${REPO_PLUGINS} \
                   net.sourceforge.plantuml.lib.jlatexmath.feature.feature.group

    install_plugin ${REPO_PLUGINS} \
                     net.sourceforge.plantuml.lib.feature.feature.group
fi

# ----------------------------------------------------
REPO_PLUGINS=https://goclipse.github.io/releases/
# ----------------------------------------------------
if [ $INSTALL_GOLANG == "1" ]; then
    echo "-> Go language"
    install_plugin ${REPO_PLUGINS} \
                   goclipse_feature.feature.group
    # Prevents error message "could not start goclipse
    # because java version is 0"
    rm ${INSTALL_DIRECTORY}/plugins/com.googlecode.goclipse.jvmcheck*
fi

# ----------------------------------------------------
REPO_PLUGINS=http://www.mihai-nita.net/eclipse
# ----------------------------------------------------
echo "-> ANSI Escape in Console Plugin"
install_plugin ${REPO_PLUGINS} \
               net.mihai-nita.ansicon.feature.group
install_plugin ${REPO_PLUGINS} \
               net.mihai-nita.externalfilter.feature.group

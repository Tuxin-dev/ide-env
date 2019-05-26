#!/bin/sh
# Default Directory for Eclipse installation.This
# variable can be overridden by the script's first
# command-line parameter.
INSTALL_DIRECTORY="${HOME}/bin/eclipse"

# Default Workspace.This variable can be overridden
# by the script's second command-line parameter.
DEFAULT_WORKSPACE="${HOME}/eclipse-workspace"

ECLIPSE_TARBALL="eclipse-cpp-2019-03-R-linux-gtk-x86_64.tar.gz"
ASSETS_DIR=".."
ECLIPSE_URL="http://mirror.ibcp.fr/pub/eclipse//technology/epp/downloads/release/2019-03/R/${ECLIPSE_TARBALL}"

# Script version
VERSION=1.0.0

if [ "$1" != "" ]; then
  INSTALL_DIRECTORY=${1}
  if [ "$2" != "" ]; then
    DEFAULT_WORKSPACE=${2}
  fi
fi

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

echo "Installing the C/C++ Development Environment"
echo "Version v$VERSION"
echo ""

# Existing installation control
if [ -e "${INSTALL_DIRECTORY}/eclipse" ]; then
    echo "An installation has already been done at ${INSTALL_DIRECTORY}."
    echo "Please delete it before starting a new one."
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
if [ ! -e ${ASSETS_DIR}/${ECLIPSE_TARBALL} ]; then
    curl -o /tmp/eclipse-cdt.tar.gz ${ECLIPSE_URL}
    if [ $? -ne 0 ]; then
        echo "Failed to download ${ECLIPSE_URL}"
        exit 3
    fi
else
    cp ${ASSETS_DIR}/${ECLIPSE_TARBALL} /tmp/eclipse-cdt.tar.gz
fi

echo "Installing Eclipse CDT ..."
cd $ECLIPSE_PATH
tar xzf /tmp/eclipse-cdt.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to decompress in ${ECLIPSE_PATH}"
    exit 4
fi
rm /tmp/eclipse-cdt.tar.gz

echo "Loading plugins ..."
#REPO_PLUGINS=http://download.eclipse.org/releases/2019-03
REPO_PLUGINS=http://download.eclipse.org/releases/latest
echo "-> gitflow"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.egit.gitflow.feature.feature.group
#
echo "-> mylyn for git"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.egit.mylyn.feature.group
install_plugin ${REPO_PLUGINS} \
               org.eclipse.mylyn.git.feature.group

echo "-> mylyn for jenkins"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.mylyn.hudson.feature.group

echo "-> Changelog file maintener"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.linuxtools.changelog.feature.group

echo "-> Papyrus UML"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.papyrus.sdk.feature.feature.group,

REPO_PLUGINS=http://download.eclipse.org/tools/cdt/releases/9.7
# Already included in Eclipse CDT
#echo "-> Arduino C/C++ Tools"
#install_plugin ${REPO_PLUGINS} \
#               org.eclipse.cdt.arduino.feature.group

echo "-> Barre d'exécution pour CDT"
install_plugin ${REPO_PLUGINS} \
               org.eclipse.launchbar.feature.group


REPO_PLUGINS=http://gnu-mcu-eclipse.netlify.com/v4-neon-updates
echo "-> MCU ARM"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.managedbuild.cross.arm.feature.feature.group

echo "-> CodeRed Debug Perspective for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.codered.feature.feature.group

mecho "-> mylyn for jenkins"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.doc.user.feature.feature.group

echo "-> Freescale Project Templates for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.templates.freescale.feature.feature.group

echo "-> Generic Cortex-M Project Templates for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.templates.cortexm.feature.feature.group

echo "-> OpenOCD Debbugging for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.debug.gdbjtag.openocd.feature.feature.group

echo "-> Packs for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.packs.feature.feature.group

echo "-> QEMU Debbugging for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.debug.gdbjtag.qemu.feature.feature.group

echo "-> STM32Fx Project Templates for MCU"
install_plugin ${REPO_PLUGINS} \
               ilg.gnumcueclipse.templates.stm.feature.feature.group

REPO_PLUGINS=http://anb0s.github.io/eclox
echo "-> Doxygen for Eclipse"
install_plugin ${REPO_PLUGINS} \
               org.gna.eclox.feature.feature.group

REPO_PLUGINS=https://dl.bintray.com/cppcheclipse/p2/updates/
echo "-> Cppcheck"
install_plugin ${REPO_PLUGINS} \
               com.googlecode.cppcheclipse.feature.feature.group

# PlantUML
#REPO_PLUGINS=http://hallvard.github.io/plantuml/
#echo "-> PlantUML"
#install_plugin ${REPO_PLUGINS} \
#               net.sourceforge.plantuml.lib


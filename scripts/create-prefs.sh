#!/bin/bash
## ****************************************************************************
## @file        create-prefs.sh
## @brief       Creation of C/C++ style configuration.
##
## @author      Tuxin (JPB)
## @version     1.0.0
## @since       Created 2020-05-24 (JPB)
## 
## @date        May 24, 2020
##
## ****************************************************************************

## XML STYLE FILE
XML_FILE=${1:-"style.xml"}

## ECLIPSE WORKSPACE
WORKSPACE=${2:-"${HOME}/eclipse-workspace"}

CORE_PREFS_FILE="${WORKSPACE}/.metadata/.plugins/org.eclipse.core.runtime/.settings/org.eclipse.cdt.core.prefs"
UI_PREFS_FILE="${WORKSPACE}/.metadata/.plugins/org.eclipse.core.runtime/.settings/org.eclipse.cdt.ui.prefs"

# Extract style name from file path
STYLE_NAME=`basename ${XML_FILE} .xml`
UI_PREFS=""

## ****************************************************************************
## @file        process_line()
## @brief       Process a text line from XML file .
##
## @author      Tuxin (JPB)
## @version     1.0.0
## @since       Created 2020-05-24 (JPB)
## 
## @date        May 24, 2020
##
## ****************************************************************************
process_line () {
    line=${1}
# Detect version from '<profiles version="1">'
    if [[ ${line:1} == profiles* ]]; then
        PROFILE_VERSION="${line:19:1}"
        echo "eclipse.preferences.version=${PROFILE_VERSION}" >> ${CORE_PREFS_FILE}
# Detect settings from '<setting id="...." value="...."/>'
    elif [[ ${line:1} == setting* ]]; then
        IFS='"' read -r -a array <<< "$line"
        echo "${array[1]}=${array[3]}" >> ${CORE_PREFS_FILE}
        UI_PREFS="${UI_PREFS}        <setting id\=\"${array[1]}\" value\=\"${array[3]}\"/>\\n"
    fi
}

# Delete old preferences file
rm -f ${CORE_PREFS_FILE}

# Read XML File line by line
while IFS= read -r line
do
    process_line "$line"
done < "$XML_FILE"

sort -o ${CORE_PREFS_FILE} ${CORE_PREFS_FILE}

# Modify UI Preferences
echo "formatter_profile=_${STYLE_NAME}" >> ${UI_PREFS_FILE}
echo "formatter_settings_version=${PROFILE_VERSION}" >> ${UI_PREFS_FILE}
echo "org.eclipse.cdt.ui.formatterprofiles=<?xml version\=\"1.0\" encoding\=\"UTF-8\" standalone\=\"no\"?>\\n<profiles version\="1">\\n    <profile kind\=\"CodeFormatterProfile\" name\=\"${STYLE_NAME}\" version\=\"${PROFILE_VERSION}\">\\n${UI_PREFS}" >> ${UI_PREFS_FILE}
echo "org.eclipse.cdt.ui.formatterprofiles.version=${PROFILE_VERSION}"





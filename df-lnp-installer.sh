#!/bin/sh

VERSION=0.0.1
echo "Dwarf Fortress LNP Linux Installer"
echo "Version: $VERSION"

# Function declarations.
exit_with_error () {
   echo "df-lnp-installer.sh: $1 Exiting."
   exit 1
}


# TODO
# If arg == version, output version.
# Check for df-lnp-installer requirements like wget and sha1sum.
# Check for DF OS requirements.

# Set up the downloads folder if it doesn't already exist.
DOWNLOAD_FOLDER="./downloads/"
mkdir -p $DOWNLOAD_FOLDER

# -nc is "no clobber" for not overwriting files we already have.
# --directory-prefix drops the files into the download folder.
WGET_OPTIONS="-nc --directory-prefix=$DOWNLOAD_FOLDER"
DFFI_WGET_OPTIONS="$WGET_OPTIONS --content-disposition"

# Download official DF.
DF_FOR_LINUX="http://www.bay12games.com/dwarves/df_34_11_linux.tar.bz2"
wget $WGET_OPTIONS $DF_FOR_LINUX

# Download latest DFHack with soundsense.
DFHACK="http://github.com/peterix/dfhack/archive/0.34.11-r3.tar.gz"
wget $WGET_OPTIONS $DFHACK

# Download Falconne's DF Hack Plugins
FALCONNE_PLUGINS="http://dffd.wimbli.com/download.php?id=7248&f=Utility_Plugins_v0.35-Windows-0.34.11.r3.zip.zip"
wget $DFFI_WGET_OPTIONS $FALCONNE_PLUGINS

# Download latest LNP GUI.
LNP_LINUX_SNAPSHOT="http://drone.io/bitbucket.org/Dricus/lazy-newbpack/files/target/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"
wget $WGET_OPTIONS $LNP_LINUX_SNAPSHOT

# TODO
# Download each graphics pack.

# Check for file validity.
sha1sum -c sha1sums

# Quit if one or more of the files fails its checksum.
if [ "$?" != "0" ]; then
  exit_with_error "One or more file failed its checksum."
fi

# TODO
# Unzip DF.
# Unzip DF_Hack on top of df_linux/
# Unzip DF Hack plugins to df_linux/hack/plugins/
# Unzip LNP.
# Drop graphics packs into LNP/Graphics/
# Drop custom lnp.yaml into LNP/.


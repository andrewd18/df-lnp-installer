#!/bin/sh

VERSION=0.0.1
echo "Dwarf Fortress LNP Linux Installer"
echo "Version: $VERSION"

# Function declarations.
checksum_all () {
  # Check for file validity.
  sha1sum -c sha1sums
  
  # Quit if one or more of the files fails its checksum.
  if [ "$?" != "0" ]; then
	exit_with_error "One or more file failed its checksum."
  fi
}

exit_with_error () {
  echo "df-lnp-installer.sh: $1 Exiting."
  exit 1
}

download_all () {
  # Set up the downloads folder if it doesn't already exist.
  mkdir -p $DOWNLOAD_DIR

  # -nc is "no clobber" for not overwriting files we already have.
  # --directory-prefix drops the files into the download folder.
  # --content-disposition asks DFFI for the actual name of the file, not the php link.
  #   Sadly, simply asking for the filename counts as a "download" so this script will be
  #   inflating people's DFFI download counts. Oh well.
  WGET_OPTIONS="-nc --directory-prefix=$DOWNLOAD_DIR"
  DFFI_WGET_OPTIONS="$WGET_OPTIONS --content-disposition"

  # Download official DF.
  DF_FOR_LINUX="http://www.bay12games.com/dwarves/df_34_11_linux.tar.bz2"
  wget $WGET_OPTIONS $DF_FOR_LINUX

  # Download latest DFHack.
  DFHACK="http://dethware.org/dfhack/download/dfhack-0.34.11-r3-Linux.tar.gz"
  wget $WGET_OPTIONS $DFHACK

  # Download Falconne's DF Hack Plugins
  FALCONNE_PLUGINS="http://dffd.wimbli.com/download.php?id=7248&f=Utility_Plugins_v0.35-Windows-0.34.11.r3.zip.zip"
  wget $DFFI_WGET_OPTIONS $FALCONNE_PLUGINS

  # Download SoundSense.
  SOUNDSENSE_APP="http://df.zweistein.cz/soundsense/soundSense_42_186.zip"
  wget $WGET_OPTIONS $SOUNDSENSE_APP

  # Download latest LNP GUI.
  LNP_LINUX_SNAPSHOT="http://drone.io/bitbucket.org/Dricus/lazy-newbpack/files/target/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"
  wget $WGET_OPTIONS $LNP_LINUX_SNAPSHOT

  # TODO
  # Download each graphics pack.
}

ask_for_preferred_install_dir () {
  echo ""
  echo -n "Where should Dwarf Fortress be installed? [$INSTALL_DIR]: "
  
  # Get the user's preferred installation location.
  read PREFERRED_DIR
  
  # If the user entered a preferred directory, use that,
  # otherwise use the install directory.
  if [ -n "$PREFERRED_DIR" ]; then
	# Use sed and custom ; delimeter to replace the first instance of ~ with the user's home directory.
	INSTALL_DIR=$(echo "$PREFERRED_DIR" | sed "s;~;$HOME;")
  fi
}

create_install_dir () {
  mkdir -p "$INSTALL_DIR"
  
  # Quit if we couldn't make the install directory.
  if [ "$?" != "0" ]; then
	exit_with_error "You probably do not have write permission to $INSTALL_DIR."
  fi
  
  local LS_OUTPUT="$(ls -A "$INSTALL_DIR")"
  
  # Verify it's empty.
  if [ -n "$LS_OUTPUT" ]; then
	exit_with_error "Cannot install. $INSTALL_DIR must be empty."
  fi
}

install_lnp () {
  local LNP_TARBALL="$DOWNLOAD_DIR/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"
  
  # Extract to the installation directory.
  tar --directory "$INSTALL_DIR" -xjvf "$LNP_TARBALL"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Untarring LNP failed."
  fi
}

install_vanilla_df () {
  local VANILLA_DF_TARBALL="$DOWNLOAD_DIR/df_34_11_linux.tar.bz2"
  
  # Extract to the installation directory.
  tar --directory "$INSTALL_DIR" -xjvf "$VANILLA_DF_TARBALL"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Untarring Vanilla DF failed."
  fi
}

install_dfhack () {
  local DF_HACK_TARBALL="$DOWNLOAD_DIR/dfhack-0.34.11-r3-Linux.tar.gz"
  
  # Extract to the installation/df_linux directory.
  tar --directory "$INSTALL_DIR/df_linux" -xzvf "$DF_HACK_TARBALL"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Untarring Vanilla DF failed."
  fi
}

install_falconne_dfhack_plugins () {
  local FALCONNE_PLUGINS_ZIP="$DOWNLOAD_DIR/Utility_Plugins_v0.35-Windows-0.34.11.r3.zip.zip"
  
  mkdir -p "falconne_unzip"
  
  unzip -d falconne_unzip $FALCONNE_PLUGINS_ZIP
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Falconne UI plugins failed."
  fi
  
  local PLUGINS_DIR="$INSTALL_DIR/df_linux/hack/plugins/"
  
  # Copy all files from Linux/ directory to DF Hack Plugins dir.
  cp falconne_unzip/Linux/*.so "${PLUGINS_DIR}"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Falconne UI plugins failed."
  fi
  
  rm -rf "./falconne_unzip"
}

install_all () {
  if [ -z "$INSTALL_DIR" ]; then
	exit_with_error "Script failure. INSTALL_DIR undefined."
  fi
  
  # Install in dependency-fulfilling order.
  install_lnp
  install_vanilla_df
  install_dfhack
  install_falconne_dfhack_plugins
}

##############
# "Main"
##############

# TODO
# If arg == version, output version.
# Check for df-lnp-installer requirements like wget and sha1sum.
# Check for DF OS requirements.

# Globals.
INSTALL_DIR="$HOME/bin/Dwarf Fortress"
DOWNLOAD_DIR="./downloads"

# Download all the things!
# download_all

# Checksum all the things!
checksum_all

ask_for_preferred_install_dir
create_install_dir
install_all

# TODO
# Extract SoundSense
# Drop graphics packs into LNP/Graphics/
# Drop custom lnp.yaml into LNP/.


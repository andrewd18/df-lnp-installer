#!/bin/sh

# Function declarations.
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

checksum_all () {
  # Check for file validity.
  sha1sum -c sha1sums
  
  # Quit if one or more of the files fails its checksum.
  if [ "$?" != "0" ]; then
	exit_with_error "One or more file failed its checksum."
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

download_all () {
  if [ -z "$DOWNLOAD_DIR" ]; then
	exit_with_error "Script failure. DOWNLOAD_DIR undefined."
  fi
  
  # Set up the downloads folder if it doesn't already exist.
  mkdir -p "$DOWNLOAD_DIR"

  # -nc is "no clobber" for not overwriting files we already have.
  # --directory-prefix drops the files into the download folder.
  # --content-disposition asks DFFI for the actual name of the file, not the php link.
  #   Sadly, simply asking for the filename counts as a "download" so this script will be
  #   inflating people's DFFI download counts. Oh well.
  local WGET_OPTIONS="-nc --directory-prefix=$DOWNLOAD_DIR"
  local DFFI_WGET_OPTIONS="$WGET_OPTIONS --content-disposition"
  
  # NOTE
  # Don't wrap $WGET_OPTIONS in quotes; wget doesn't like it.

  # Download official DF.
  local DF_FOR_LINUX="http://www.bay12games.com/dwarves/df_34_11_linux.tar.bz2"
  wget $WGET_OPTIONS "$DF_FOR_LINUX"

  # Download latest DFHack.
  local DFHACK="http://dethware.org/dfhack/download/dfhack-0.34.11-r3-Linux.tar.gz"
  wget $WGET_OPTIONS "$DFHACK"

  # Download Falconne's DF Hack Plugins
  local FALCONNE_PLUGINS="http://dffd.wimbli.com/download.php?id=7248&f=Utility_Plugins_v0.35-Windows-0.34.11.r3.zip.zip"
  wget $DFFI_WGET_OPTIONS "$FALCONNE_PLUGINS"

  # Download SoundSense.
  local SOUNDSENSE_APP="http://df.zweistein.cz/soundsense/soundSense_42_186.zip"
  wget $WGET_OPTIONS "$SOUNDSENSE_APP"

  # Download latest LNP GUI.
  local LNP_LINUX_SNAPSHOT="http://drone.io/bitbucket.org/Dricus/lazy-newbpack/files/target/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"
  wget $WGET_OPTIONS "$LNP_LINUX_SNAPSHOT"
  
  # GRAPHICS PACKS
  # Download Phoebus.
  local PHOEBUS_GFX_PACK="http://dffd.wimbli.com/download.php?id=2430&f=Phoebus_34_11v01.zip"
  wget $DFFI_WGET_OPTIONS "$PHOEBUS_GFX_PACK"
  
  # Download CLA.
  local CLA_GFX_PACK="http://dffd.wimbli.com/download.php?id=5945&f=CLA_graphic_set_v15-STANDALONE.rar"
  wget $DFFI_WGET_OPTIONS "$CLA_GFX_PACK"
  
  # Download Ironhand16.
  local IRONHAND_GFX_PACK="http://dffd.wimbli.com/download.php?id=7362&f=Ironhand16+upgrade+0.73.4.zip"
  wget $DFFI_WGET_OPTIONS "$IRONHAND_GFX_PACK"
  
  # Download Mayday
  local MAYDAY_GFX_PACK="http://dffd.wimbli.com/download.php?id=7025&f=Mayday+34.11.zip"
  wget $DFFI_WGET_OPTIONS "$MAYDAY_GFX_PACK"
  
  # Download Obsidian
  local OBSIDIAN_GFX_PACK="http://dffd.wimbli.com/download.php?id=7728&f=%5B16x16%5D+Obsidian+%28v.0.8%29.zip"
  wget $DFFI_WGET_OPTIONS "$OBSIDIAN_GFX_PACK"
  
  # Download Spacefox
  local SPACEFOX_GFX_PACK="http://dffd.wimbli.com/download.php?id=7867&f=%5B16x16%5D+Spacefox+34.11v1.0.zip"
  wget $DFFI_WGET_OPTIONS "$SPACEFOX_GFX_PACK"
}

exit_with_error () {
  echo "df-lnp-installer.sh: $1 Exiting."
  exit 1
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
  
  install_phoebus_gfx_pack
  install_cla_graphics_pack
  install_ironhand_gfx_pack
  install_mayday_gfx_pack
  install_obsidian_gfx_pack
  install_spacefox_gfx_pack
  install_vanilla_df_gfx_pack
  install_jolly_bastion_gfx_pack
  
  install_soundsense_app
  
  # TODO
  # Make a decision about downloading/installing soundsense audio.
  # Drop custom lnp.yaml into LNP/.
}

install_cla_graphics_pack () {
  local CLA_GFX_RAR="$DOWNLOAD_DIR/CLA_graphic_set_v15-STANDALONE.rar"
  local GFX_FOLDER="$INSTALL_DIR/LNP/graphics"
  
  unrar x "$CLA_GFX_RAR" "$GFX_FOLDER"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unraring CLA graphics pack failed."
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
  local FALCONNE_TEMP_FOLDER="./falconne_unzip"
  mkdir -p "$FALCONNE_TEMP_FOLDER"
  
  unzip -d "$FALCONNE_TEMP_FOLDER" "$FALCONNE_PLUGINS_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Falconne UI plugins failed."
  fi
  
  local PLUGINS_DIR="$INSTALL_DIR/df_linux/hack/plugins/"
  
  # Copy all files from Linux/ directory to DF Hack Plugins dir.
  cp falconne_unzip/Linux/*.so "$PLUGINS_DIR"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Falconne UI plugins failed."
  fi
  
  rm -r "$FALCONNE_TEMP_FOLDER"
}

install_ironhand_gfx_pack () {
  local IRONHAND_ZIP="$DOWNLOAD_DIR/Ironhand16 upgrade 0.73.4.zip"
  local IRONHAND_TEMP_FOLDER="./ironhand_unzip"
  local GFX_FOLDER="$INSTALL_DIR/LNP/graphics/Ironhand"
  
  mkdir -p "$IRONHAND_TEMP_FOLDER"
  
  mkdir -p "$GFX_FOLDER"
  
  unzip -d "$IRONHAND_TEMP_FOLDER" "$IRONHAND_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Ironhand graphics pack failed."
  fi
  
  # Copy data and raw folders to GFX dir.
  cp -r "$IRONHAND_TEMP_FOLDER/Dwarf Fortress/data" "$GFX_FOLDER"
  cp -r "$IRONHAND_TEMP_FOLDER/Dwarf Fortress/raw" "$GFX_FOLDER"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Ironhand graphics pack failed."
  fi
  
  rm -r "$IRONHAND_TEMP_FOLDER"
}

install_jolly_bastion_gfx_pack () {
  local JOLLY_BASTION_ZIP="$DOWNLOAD_DIR/JollyBastion34-10v5.zip"
  local JOLLY_BASTION_TEMP_FOLDER="./jolly_bastion_unzip"
  
  local JB_NINE_BY_TWELVE_GFX_FOLDER="$INSTALL_DIR/LNP/graphics/JollyBastion9x12"
  local JB_TWELVE_BY_TWELVE_GFX_FOLDER="$INSTALL_DIR/LNP/graphics/JollyBastion12x12"
  
  mkdir -p "$JB_NINE_BY_TWELVE_GFX_FOLDER"
  mkdir -p "$JB_TWELVE_BY_TWELVE_GFX_FOLDER"
  
  unzip -d "$JOLLY_BASTION_TEMP_FOLDER" "$JOLLY_BASTION_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Jolly Bastion graphics pack failed."
  fi
  
  cp -r "$JOLLY_BASTION_TEMP_FOLDER/JollyBastion34-10v5/9x12 (recommended)/data" "$JB_NINE_BY_TWELVE_GFX_FOLDER"
  cp -r "$JOLLY_BASTION_TEMP_FOLDER/JollyBastion34-10v5/9x12 (recommended)/raw" "$JB_NINE_BY_TWELVE_GFX_FOLDER"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Jolly Bastion 9x12 graphics pack failed."
  fi
  
  cp -r "$JOLLY_BASTION_TEMP_FOLDER/JollyBastion34-10v5/12x12/data" "$JB_TWELVE_BY_TWELVE_GFX_FOLDER"
  cp -r "$JOLLY_BASTION_TEMP_FOLDER/JollyBastion34-10v5/12x12/raw" "$JB_TWELVE_BY_TWELVE_GFX_FOLDER"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Jolly Bastion 12x12 graphics pack failed."
  fi
  
  rm -r "$JOLLY_BASTION_TEMP_FOLDER"
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

install_mayday_gfx_pack () {
  local MAYDAY_ZIP="$DOWNLOAD_DIR/Mayday 34.11.zip"
  local GFX_FOLDER="$INSTALL_DIR/LNP/graphics"
  
  unzip -d "$GFX_FOLDER" "$MAYDAY_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Mayday graphics pack failed."
  fi
}

install_obsidian_gfx_pack () {
  local OBSIDIAN_ZIP="$DOWNLOAD_DIR/[16x16] Obsidian (v.0.8).zip"
  local GFX_FOLDER="$INSTALL_DIR/LNP/graphics"
  
  unzip -d "$GFX_FOLDER" "$OBSIDIAN_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Obsidian graphics pack failed."
  fi
}

install_phoebus_gfx_pack () {
  local PHOEBUS_GFX_PACK="$DOWNLOAD_DIR/Phoebus_34_11v01.zip"
  local PHOEBUS_FOLDER="$INSTALL_DIR/LNP/graphics/Phoebus_34_11v01"
  
  mkdir -p "$PHOEBUS_FOLDER"
  
  unzip -d "$PHOEBUS_FOLDER" "$PHOEBUS_GFX_PACK"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Phoebus graphics pack failed."
  fi
}

install_soundsense_app () {
  local SOUNDSENSE_ZIP="$DOWNLOAD_DIR/soundSense_42_186.zip"
  local UTILITIES_FOLDER="$INSTALL_DIR/LNP/utilities"
  
  unzip -d "$UTILITIES_FOLDER" "$SOUNDSENSE_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping SoundSense application failed."
  fi
}

install_spacefox_gfx_pack () {
  local SPACEFOX_ZIP="$DOWNLOAD_DIR/[16x16] Spacefox 34.11v1.0.zip"
  local GFX_FOLDER="$INSTALL_DIR/LNP/graphics"
  
  unzip -d "$GFX_FOLDER" "$SPACEFOX_ZIP"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Spacefox graphics pack failed."
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

install_vanilla_df_gfx_pack () {
  local DATA_FOLDER="$INSTALL_DIR/df_linux/data"
  local RAW_FOLDER="$INSTALL_DIR/df_linux/raw"
  
  local GFX_FOLDER="$INSTALL_DIR/LNP/graphics/ASCII Default"
  
  mkdir -p "$GFX_FOLDER"
  
  # Copy the data and raw folders from the vanilla df install location
  # Put them in $GFX_FOLDER
  cp -r "$DATA_FOLDER" "$GFX_FOLDER"
  cp -r "$RAW_FOLDER" "$GFX_FOLDER"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Vanilla DF graphics pack failed."
  fi
}

print_usage () {
  echo "Usage: df-lnp-installer.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "--skip-download  # Install using the existing contents of the ./downloads folder."
  echo "--version, -v    # Print the df-lnp-installer version."
  echo "--help, --usage  # Print this message."
}

print_version () {
  echo "Dwarf Fortress LNP Linux Installer"
  echo "Version: $VERSION"
}

##############
# "Main"
##############

# Globals.
VERSION=0.1.0
INSTALL_DIR="$HOME/bin/Dwarf Fortress"
DOWNLOAD_DIR="./downloads"
SKIP_DOWNLOAD=0

# TODO
# Check for df-lnp-installer requirements like wget and sha1sum.
# Check for DF OS requirements like libSDL and Java.

# If the user passed in arguments, parse them, otherwise assume "do everything". 
if [ -n "$1" ]; then
  while [ "$1" ]; do
	case "$1" in
	  '--skip-download') SKIP_DOWNLOAD=1 ;;
	  '--version'|'-v') print_version; exit 0 ;;
	  '--help'|'--usage') print_usage; exit 0 ;;
	  *) echo "Unknown argument: $1"; print_usage; exit 1 ;;
	esac
	
	# Shift arguments left, dropping off $1.
	# Make $1 = $2, $2 = $3, etc.
	shift
  done
fi

ask_for_preferred_install_dir
create_install_dir

# Download all the things!
if [ "$SKIP_DOWNLOAD" = "0" ]; then
  download_all
fi

# Checksum all the things!
checksum_all

# Install all the things!
install_all

# Strike the earth!
echo ""
echo "Installation successful!"
echo "Run $INSTALL_DIR/startlnp to run the Lazy Newb Pack."

exit 0

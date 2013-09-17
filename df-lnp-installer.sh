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

backup_save_files () {
  local SAVE_DIR="$INSTALL_DIR/df_linux/data/save"
  local BACKUPS_DIR="./save_backups"
  
  # Check to see if they even have save files.
  if [ -d "$SAVE_DIR" ]; then
	mkdir -p "$BACKUPS_DIR"
	
	cp -r "$SAVE_DIR" "$BACKUPS_DIR"
	
	# Quit if backing up failed.
	if [ "$?" != "0" ]; then
	  exit_with_error "Backing up saved games failed."
	fi
  fi
}

build_dwarf_therapist () {
  if [ -z "$DOWNLOAD_DIR" ]; then
	exit_with_error "Script failure. DOWNLOAD_DIR undefined."
  fi

  local DWARF_THERAPIST_HG_DIR="$DOWNLOAD_DIR/dwarftherapist"
  
  # Create the makefile.
  qmake "$DWARF_THERAPIST_HG_DIR" -o "$DWARF_THERAPIST_HG_DIR/Makefile"
  
  # Build from the Makefile.
  make -C "$DWARF_THERAPIST_HG_DIR"
  
  # Quit if building failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Compiling Dwarf Therapist failed."
  fi
}

check_dependencies () {
  echo "Checking for dependencies..."
  
  local MISSING_DEPS=""
  
  # file
  if [ -z "$(which file)" ]; then
	MISSING_DEPS="${MISSING_DEPS}file "
  fi
  
  # WGET
  if [ -z "$(which wget)" ]; then
	MISSING_DEPS="${MISSING_DEPS}wget "
  fi
  
  # sha1sum
  if [ -z "$(which wget)" ]; then
	MISSING_DEPS="${MISSING_DEPS}sha1sum "
  fi
  
  # Tar
  if [ -z "$(which tar)" ]; then
	MISSING_DEPS="${MISSING_DEPS}tar "
  fi
  
  # Unzip
  if [ -z "$(which unzip)" ]; then
	MISSING_DEPS="${MISSING_DEPS}unzip "
  fi
  
  # Unrar
  if [ -z "$(which unrar)" ]; then
	MISSING_DEPS="${MISSING_DEPS}unrar "
  fi
  
  # Patch
  if [ -z "$(which patch)" ]; then
	MISSING_DEPS="${MISSING_DEPS}patch "
  fi
  
  # Mercurial (required for DwarfTherapist)
  if [ -z "$(which hg)" ]; then
	MISSING_DEPS="${MISSING_DEPS}hg "
  fi
  
  # qmake (required for DwarfTherapist)
  if [ -z "$(which hg)" ]; then
	MISSING_DEPS="${MISSING_DEPS}qmake "
  fi
  
  # make (required for DwarfTherapist)
  if [ -z "$(which make)" ]; then
	MISSING_DEPS="${MISSING_DEPS}make "
  fi
  
  # Check for QT Libraries (required for Dwarf Therapist)
  if [ -z "$(find /usr/lib -name libQtCore.so)" ]; then
	MISSING_DEPS="${MISSING_DEPS}libQtCore "
  fi
  
  if [ -z "$(find /usr/lib -name libQtGui.so)" ]; then
	MISSING_DEPS="${MISSING_DEPS}libQtGui "
  fi
  
  if [ -z "$(find /usr/lib -name libQtNetwork.so)" ]; then
	MISSING_DEPS="${MISSING_DEPS}libQtNetwork "
  fi
  
  if [ -z "$(find /usr/lib -name libQtScript.so)" ]; then
	MISSING_DEPS="${MISSING_DEPS}libQtScript "
  fi
  
  # java runtime environment (required for LNP)
  if [ -z "$(which java)" ]; then
	MISSING_DEPS="${MISSING_DEPS}java "
  fi
  
  # Check for libSDL base; must be 32-bit.
  local LIBSDL_BASE_SO="$(find /usr/lib -name libSDL-1.2.so.0)"
  local LIBSDL_FILTER_32_BIT="$(file -L $LIBSDL_BASE_SO | grep "32-bit")"
  
  if [ -z "$LIBSDL_FILTER_32_BIT" ]; then
	MISSING_DEPS="${MISSING_DEPS}libSDL-1.2_(32-bit) "
  fi
  
  # Check for libSDL image; must be 32-bit.
  local LIBSDL_IMAGE_SO="$(find /usr/lib -name libSDL_image-1.2.so.0)"
  local LIBSDL_IMAGE_FILTER_32_BIT="$(file -L $LIBSDL_IMAGE_SO | grep "32-bit")"
  
  if [ -z "$LIBSDL_IMAGE_FILTER_32_BIT" ]; then
	MISSING_DEPS="${MISSING_DEPS}libSDL_image-1.2_(32-bit) "
  fi
  
  # Check for libSDL ttf; must be 32-bit.
  local LIBSDL_TTF_SO="$(find /usr/lib -name libSDL_ttf-2.0.so.0)"
  local LIBSDL_TTF_FILTER_32_BIT="$(file -L $LIBSDL_TTF_SO | grep "32-bit")"
  
  if [ -z "$LIBSDL_TTF_FILTER_32_BIT" ]; then
	MISSING_DEPS="${MISSING_DEPS}libSDL_ttf-2.0_(32-bit) "
  fi
  
  # Check for OpenAL; must be 32-bit.
  local OPENAL_SO="$(find /usr/lib -name libopenal.so.1)"
  local OPENAL_SO_FILTER_32_BIT="$(file -L $OPENAL_SO | grep "32-bit")"
  
  if [ -z "$OPENAL_SO_FILTER_32_BIT" ]; then
	MISSING_DEPS="${MISSING_DEPS}libOpenAL_1_(32-bit) "
  fi
  
  # Check for libGLU; must be 32-bit.
  local LIBGLU_SO="$(find /usr/lib -name libGLU.so.1)"
  local LIBGLU_SO_FILTER_32_BIT="$(file -L $LIBGLU_SO | grep "32-bit")"
  
  if [ -z "$LIBGLU_SO_FILTER_32_BIT" ]; then
	MISSING_DEPS="${MISSING_DEPS}libGLU_(32-bit) "
  fi
  
  # Check for libgtk-x11; must be 32-bit.
  local LIBGTK_SO="$(find /usr/lib -name libgtk-x11-2.0.so.0)"
  local LIBGTK_SO_FILTER_32_BIT="$(file -L $LIBGTK_SO | grep "32-bit")"
  
  if [ -z "$LIBGTK_SO_FILTER_32_BIT" ]; then
	MISSING_DEPS="${MISSING_DEPS}libGTK-x11_(32-bit) "
  fi
  
  ######
  # Error if the $MISSING_DEPS string contains a value (aka there are missing dependencies).
  ######
  if [ -n "$MISSING_DEPS" ]; then
	exit_with_error "Your computer is missing the following programs or libraries: $MISSING_DEPS. Install them using your distribution's package manager or use --skip-deps to override."
  fi
}

check_install_dir_is_empty () {
  local LS_OUTPUT="$(ls -A "$INSTALL_DIR")"
  
  # Verify it's empty.
  if [ -n "$LS_OUTPUT" ]; then
	exit_with_error "Cannot install. $INSTALL_DIR must be an empty or nonexistant folder. If this is an existing DF installation, use --upgrade."
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
}

delete_install_dir () {
  rm -r "$INSTALL_DIR"
  
  # Quit if we couldn't make the install directory.
  if [ "$?" != "0" ]; then
	exit_with_error "You probably do not have write permission to $INSTALL_DIR."
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
  
  # Download JollyBastion
  local JOLLY_BASTION_GFX_PACK="http://www.alexanderocias.com/jollybastion/JollyBastion34-10v5.zip"
  wget $WGET_OPTIONS "$JOLLY_BASTION_GFX_PACK"
  
  # Download Mayday
  local MAYDAY_GFX_PACK="http://dffd.wimbli.com/download.php?id=7025&f=Mayday+34.11.zip"
  wget $DFFI_WGET_OPTIONS "$MAYDAY_GFX_PACK"
  
  # Download Obsidian
  local OBSIDIAN_GFX_PACK="http://dffd.wimbli.com/download.php?id=7728&f=%5B16x16%5D+Obsidian+%28v.0.8%29.zip"
  wget $DFFI_WGET_OPTIONS "$OBSIDIAN_GFX_PACK"
  
  # Download Spacefox
  local SPACEFOX_GFX_PACK="http://dffd.wimbli.com/download.php?id=7867&f=%5B16x16%5D+Spacefox+34.11v1.0.zip"
  wget $DFFI_WGET_OPTIONS "$SPACEFOX_GFX_PACK"
  
  # Download Splintermind Attributes HG repo
  download_dwarf_therapist
}

download_dwarf_therapist () {
  local DWARF_THERAPIST_HG_DIR="$DOWNLOAD_DIR/dwarftherapist"
  
  if [ -d "$DWARF_THERAPIST_HG_DIR" ]; then
	hg update --cwd "$DWARF_THERAPIST_HG_DIR"
  else
	hg clone https://dwarftherapist.googlecode.com/hg/ "$DWARF_THERAPIST_HG_DIR"
  fi
  
  # Quit if downloading failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Cloning / updating Dwarf Therapist HG repository failed."
  fi
}

exit_with_error () {
  echo "df-lnp-installer.sh: $1 Exiting."
  exit 1
}

fix_phoebus_missing_mouse_png () {
  # Resolves GitHub issue #6.
  local PHOEBUS_FOLDER="$INSTALL_DIR/LNP/graphics/[16x16] Phoebus 34.11v01"
  local VANILLA_GFX_FOLDER="$INSTALL_DIR/LNP/graphics/ASCII Default"
  
  cp "$VANILLA_GFX_FOLDER/data/art/mouse.png" "$PHOEBUS_FOLDER/data/art/mouse.png"
  
  if [ "$?" != "0" ]; then
	exit_with_error "Applying Phoebus Missing Mouse patch failed."
  fi
}

install_all () {
  if [ -z "$INSTALL_DIR" ]; then
	exit_with_error "Script failure. INSTALL_DIR undefined."
  fi
  
  # Install in dependency-fulfilling order.
  install_lnp
  install_lnp_yaml
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
  
  fix_phoebus_missing_mouse_png
  
  install_soundsense_app
  
  build_dwarf_therapist
  install_dwarf_therapist
  
  # TODO
  # Make a decision about downloading/installing soundsense audio.
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

install_dwarf_therapist () {
  if [ -z "$DOWNLOAD_DIR" ]; then
	exit_with_error "Script failure. DOWNLOAD_DIR undefined."
  fi
  
  if [ -z "$INSTALL_DIR" ]; then
	exit_with_error "Script failure. INSTALL_DIR undefined."
  fi

  local DWARF_THERAPIST_HG_DIR="$DOWNLOAD_DIR/dwarftherapist"
  local RELEASE_DIR="$DWARF_THERAPIST_HG_DIR/bin/release"
  
  local UTILITIES_FOLDER="$INSTALL_DIR/LNP/utilities"
  
  mkdir -p "$UTILITIES_FOLDER/dwarf_therapist"
  
  # Copy app.
  cp "$RELEASE_DIR/DwarfTherapist" "$UTILITIES_FOLDER/dwarf_therapist/"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Dwarf Therapist app failed."
  fi
  
  # Create log file.
  mkdir -p "$UTILITIES_FOLDER/dwarf_therapist/log"
  touch "$UTILITIES_FOLDER/dwarf_therapist/log/run.log"
  
  # Copy etc files.
  cp -r "$DWARF_THERAPIST_HG_DIR/etc" "$UTILITIES_FOLDER/dwarf_therapist/"
  
  # Quit if copying failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying Dwarf Therapist ancillary files failed."
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

install_lnp_yaml () {
  local LNP_YAML_FILE="./lnp.yaml"
  local LNP_DIR="$INSTALL_DIR/LNP"
  
  install --mode=644 "$LNP_YAML_FILE" "$LNP_DIR"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Copying LNP Yaml file failed."
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
  local PHOEBUS_UNZIP="./phoebus_unzip"
  local PHOEBUS_FOLDER="$INSTALL_DIR/LNP/graphics/[16x16] Phoebus 34.11v01"
  local PHOEBUS_LNP_PATCH_DIR="./patches/phoebus_gfx"
  
  mkdir -p "$PHOEBUS_FOLDER"
  
  unzip -d "$PHOEBUS_UNZIP" "$PHOEBUS_GFX_PACK"
  
  # Quit if extracting failed.
  if [ "$?" != "0" ]; then
	exit_with_error "Unzipping Phoebus graphics pack failed."
  fi
  
  # Install Art
  mkdir -p "$PHOEBUS_FOLDER/data/art"
  cp "$PHOEBUS_UNZIP/data/art/"* "$PHOEBUS_FOLDER/data/art/"
  
  if [ "$?" != "0" ]; then
	exit_with_error "Installing Phoebus art failed."
  fi
  
  # Install init
  mkdir -p "$PHOEBUS_FOLDER/data/init"
  cp "$PHOEBUS_UNZIP/data/init/phoebus_nott/"* "$PHOEBUS_FOLDER/data/init/"
  
  if [ "$?" != "0" ]; then
	exit_with_error "Installing Phoebus init failed."
  fi
  
  # Apply LNP patches.
  patch -d "$PHOEBUS_FOLDER/data/init/" < "patches/phoebus_gfx/init_lnp_defaults.patch"
  patch -d "$PHOEBUS_FOLDER/data/init/" < "patches/phoebus_gfx/dinit_lnp_defaults.patch"
  
  if [ "$?" != "0" ]; then
	exit_with_error "Applying Phoebus LNP patches failed."
  fi
  
  # Install raws
  mkdir -p "$PHOEBUS_FOLDER/raw"
  cp -r "$PHOEBUS_UNZIP/raw/graphics" "$PHOEBUS_FOLDER/raw"
  cp -r "$PHOEBUS_UNZIP/raw/objects" "$PHOEBUS_FOLDER/raw"
  
  if [ "$?" != "0" ]; then
	exit_with_error "Installing Phoebus raws failed."
  fi
  
  rm -r "$PHOEBUS_UNZIP"
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
  echo "--skip-deps      # Install without checking for dependencies."
  echo "--upgrade, -u    # Upgrade an existing DF installation."
  echo "--version, -v    # Print the df-lnp-installer version."
  echo "--help, --usage  # Print this message."
}

print_version () {
  echo "Dwarf Fortress LNP Linux Installer"
  echo "Version: $VERSION"
}

restore_save_files () {
  local DATA_DIR="$INSTALL_DIR/df_linux/data"
  local BACKUPS_DIR="./save_backups"
  
  # Restore if a save folder exists in $BACKUPS_DIR
  if [ -d "$BACKUPS_DIR/save" ]; then
	mv "$BACKUPS_DIR/save" "$DATA_DIR"
	
	# Quit if restoring failed.
	if [ "$?" != "0" ]; then
	  exit_with_error "Restoring saved games failed."
	fi
  fi
  
  # Delete the backups dir.
  rmdir --ignore-fail-on-non-empty "$BACKUPS_DIR"
}

##############
# "Main"
##############

# Globals.
VERSION="0.1.4+dev"
INSTALL_DIR="$HOME/bin/Dwarf Fortress"
DOWNLOAD_DIR="./downloads"
SKIP_DOWNLOAD=0
SKIP_DEPS=0
UPGRADE=0

# If the user passed in arguments, parse them, otherwise assume "do everything". 
if [ -n "$1" ]; then
  while [ "$1" ]; do
	case "$1" in
	  '--skip-download') SKIP_DOWNLOAD=1 ;;
	  '--skip-deps') SKIP_DEPS=1 ;;
	  '--upgrade'|'-u') UPGRADE=1 ;;
	  '--version'|'-v') print_version; exit 0 ;;
	  '--help'|'--usage') print_usage; exit 0 ;;
	  *) echo "Unknown argument: $1"; print_usage; exit 1 ;;
	esac
	
	# Shift arguments left, dropping off $1.
	# Make $1 = $2, $2 = $3, etc.
	shift
  done
fi

if [ "$SKIP_DEPS" = "0" ]; then
  check_dependencies
fi

ask_for_preferred_install_dir

# If we are upgrading, backup the save files (if any) and then wipe the slate clean.
if [ "$UPGRADE" = "1" ]; then
  backup_save_files
  delete_install_dir
fi

create_install_dir
check_install_dir_is_empty

# Download all the things!
if [ "$SKIP_DOWNLOAD" = "0" ]; then
  download_all
fi

# Checksum all the things!
checksum_all

# Install all the things!
install_all

# If we upgraded, restore the save files (if any).
if [ "$UPGRADE" = "1" ]; then
  restore_save_files
fi

# Strike the earth!
echo ""
echo "Installation successful!"
echo "Run $INSTALL_DIR/startlnp to run the Lazy Newb Pack."

exit 0

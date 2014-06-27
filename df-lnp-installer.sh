#!/bin/sh

# Function declarations.
ask_for_preferred_install_dir () {
	# Suggest either the default INSTALL_DIR or a known installation location, as set in config file.
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

backup_df_directory () {
	if [ -z "$INSTALL_DIR" ]; then
		exit_with_error "Script failure: INSTALL_DIR not defined."
	fi

	mkdir -p "$BACKUP_DIR"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do.

		exit_with_error "Creating $BACKUP_DIR failed."
	fi

	# Copy the old install to the backup directory.
	cp -r "$INSTALL_DIR" "$BACKUP_DIR"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		rm -r "$BACKUP_DIR"

		exit_with_error "Backing up old DF installation failed."
	fi
}

build_dwarf_therapist () {
	if [ -z "$DOWNLOAD_DIR" ]; then
		exit_with_error "Script failure. DOWNLOAD_DIR undefined."
	fi

	local DWARF_THERAPIST_HG_DIR="$DOWNLOAD_DIR/dwarftherapist"

	# Choose the good qmake version depending of the Qt version used
	if [ "$USE_QT5" = "1" ]; then
		QMAKE=$(find_qmake_qt5)
	else
		QMAKE=$(find_qmake_qt4)
	fi

	# qmake-qt5 requires that the working directory is the same as the 
	# hg source directory. Change directories into that location.
	cd "$DWARF_THERAPIST_HG_DIR"

	# Create the makefile.
	$QMAKE

	# Quit if qmake failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do; that's qmake's job.
		
		exit_with_error "Compiling Dwarf Therapist failed. See QMake output above for details."
	fi

	# Build from the new Makefile.
	make

	# Quit if building failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do; that's Make's job.
		
		exit_with_error "Compiling Dwarf Therapist failed. See Make output above for details."
	fi
	
	# Back up to the previously used working directory (which should be the df-lnp-installer dir).
	cd -
}

build_dwarf_fortress_unfunck () {
	if [ -z "$DOWNLOAD_DIR" ]; then
		exit_with_error "Script failure. DOWNLOAD_DIR undefined."
	fi

	local DF_UNFUNCK_DIR="$DOWNLOAD_DIR/df_unfunck"

        make -C "$DF_UNFUNCK_DIR"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do; that's Make's job.

		exit_with_error "Compiling dwarf_fortress_unfunck failed. See Make output above for details."
	fi
}

# One-off bugfixes that either require multiple packages to be installed first
# or have other non-trivial consequences.
bugfix_all () {
	fix_cla_missing_mouse_png
	fix_jolly_bastion_missing_graphics_dir
	fix_jolly_bastion_missing_mouse_png
	fix_phoebus_missing_mouse_png
	fix_phoebus_gfx_font_ttf_name
	fix_obsidian_gfx_font_ttf_name
	fix_soundsense_missing_gamelog
	fix_vanilla_df_openal_issue
	fix_vanilla_df_ancient_libstdcpp
	fix_vanilla_df_lnp_settings_not_applied_by_default
}

find_python2 () {
	for name in "python" "python2"; do
		# If the executable exists...
		# and its -V output is "Python 2.x.x"...
		# then return that executable name.
		if [ -n "$(which $name)" ] && [ "$($name -V 2<&1 | cut -d' ' -f 2 | cut -d . -f 1)" = "2" ]; then
			echo $name
			break
		fi
	done
}

find_qmake_qt4 () {
	for name in "qmake" "qmake-qt4"; do
		# If the executable exists...
		# and its -query QT_VERSION output is "4"...
		# then return that executable name.
		if [ -n "$(which $name 2> /dev/null)" ] && [ "$($name -query QT_VERSION | cut -d . -f 1)" = "4" ]; then
			echo $name
			break
		fi
	done
}

find_qmake_qt5 () {
	for name in "qmake" "qmake-qt5"; do
		# If the executable exists...
		# and its -query QT_VERSION output is "5"...
		# then return that executable name.
		if [ -n "$(which $name)" ] && [ "$($name -query QT_VERSION | cut -d . -f 1)" = "5" ]; then
			#echo $name
			echo "qmake-qt5"
			break
		fi
	done
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
	if [ -z "$(which sha1sum)" ]; then
		MISSING_DEPS="${MISSING_DEPS}sha1sum "
	fi

	# sed
	if [ -z "$(which sed)" ]; then
		MISSING_DEPS="${MISSING_DEPS}sed "
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

	# xterm for LNP
	if [ -z "$(which xterm)" ]; then
		MISSING_DEPS="${MISSING_DEPS}xterm "
	fi

	# Mercurial (required for DwarfTherapist)
	if [ -z "$(which hg)" ]; then
		MISSING_DEPS="${MISSING_DEPS}hg "
	fi

	# make (required for DwarfTherapist)
	if [ -z "$(which make)" ]; then
		MISSING_DEPS="${MISSING_DEPS}make "
	fi

	# g++ (required for DwarfTherapist)
	if [ -z "$(which g++)" ]; then
		MISSING_DEPS="${MISSING_DEPS}g++ "
	fi

	# gcc (required for DwarfTherapist)
	if [ -z "$(which gcc)" ]; then
		MISSING_DEPS="${MISSING_DEPS}gcc "
	fi

	# Check for QT Libraries (required for Dwarf Therapist)
	
	# First Qt5 libraries.
	if [ -z "$(which qtchooser)" ]; then
		MISSING_DEPS_QT5="${MISSING_DEPS_QT5}qtchooser "
	fi

	if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQt5Core.so')" ]; then
		MISSING_DEPS_QT5="${MISSING_DEPS_QT5}libQt5Core "
	fi

	if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQt5Gui.so')" ]; then
		MISSING_DEPS_QT5="${MISSING_DEPS_QT5}libQt5Gui "
	fi

	if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQt5Script.so')" ]; then
		MISSING_DEPS_QT5="${MISSING_DEPS_QT5}libQt5Script "
	fi

	# qmake (required for DwarfTherapist)
	if [ -z "$(find_qmake_qt5)" ]; then
		MISSING_DEPS_QT5="${MISSING_DEPS_QT5}qmake_qt5 "
	fi

	# If Qt5 libraries are missing, check Qt4
	if [ -n "$MISSING_DEPS_QT5" ]; then
		if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQtCore.so')" ]; then
			MISSING_DEPS="${MISSING_DEPS}libQtCore "
		fi

		if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQtGui.so')" ]; then
			MISSING_DEPS="${MISSING_DEPS}libQtGui "
		fi

		if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQtNetwork.so')" ]; then
			MISSING_DEPS="${MISSING_DEPS}libQtNetwork "
		fi

		if [ -z "$(/sbin/ldconfig -p | grep -P '^\tlibQtScript.so')" ]; then
			MISSING_DEPS="${MISSING_DEPS}libQtScript "
		fi

		# qmake (required for DwarfTherapist)
		if [ -z "$(find_qmake_qt4)" ]; then
			MISSING_DEPS="${MISSING_DEPS}qmake_qt4 "
		fi
	fi

	# java runtime environment (required for LNP, Chromafort, and DF Announcement Filter)
	if [ -z "$(which java)" ]; then
		MISSING_DEPS="${MISSING_DEPS}java "
	fi

	# Check for libSDL base; must be 32-bit.
	local LIBSDL_BASE_SO="$(/sbin/ldconfig -p | grep -P '^\tlibSDL-1.2.so.0' | sed 's/[^>]*> //')"
	local LIBSDL_32_BIT_FILENAME="$(file -L $LIBSDL_BASE_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$LIBSDL_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libSDL-1.2_(32-bit) "
	fi

	# Check for libSDL image; must be 32-bit.
	local LIBSDL_IMAGE_SO="$(/sbin/ldconfig -p | grep -P '^\tlibSDL_image-1.2.so.0' | sed 's/[^>]*> //')"
	local LIBSDL_IMAGE_32_BIT_FILENAME="$(file -L $LIBSDL_IMAGE_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$LIBSDL_IMAGE_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libSDL_image-1.2_(32-bit) "
	fi

	# Check for libSDL ttf; must be 32-bit.
	local LIBSDL_TTF_SO="$(/sbin/ldconfig -p | grep -P '^\tlibSDL_ttf-2.0.so.0' | sed 's/[^>]*> //')"
	local LIBSDL_TTF_32_BIT_FILENAME="$(file -L $LIBSDL_TTF_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$LIBSDL_TTF_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libSDL_ttf-2.0_(32-bit) "
	fi

	# Check for OpenAL; must be 32-bit.
	local OPENAL_SO="$(/sbin/ldconfig -p | grep -P '^\tlibopenal.so.1' | sed 's/^[>]*> //')"
	local OPENAL_SO_32_BIT_FILENAME="$(file -L $OPENAL_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$OPENAL_SO_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libOpenAL_1_(32-bit) "
	fi

	# Check for libGLU; must be 32-bit.
	local LIBGLU_SO="$(/sbin/ldconfig -p | grep -P '^\tlibGLU.so.1' | sed 's/^[>]*> //')"
	local LIBGLU_SO_32_BIT_FILENAME="$(file -L $LIBGLU_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$LIBGLU_SO_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libGLU_(32-bit) "
	fi

	# Check for libgtk-x11; must be 32-bit.
	local LIBGTK_SO="$(/sbin/ldconfig -p | grep -P '^\tlibgtk-x11-2.0.so.0' | sed 's/^[>]*> //')"
	local LIBGTK_SO_32_BIT_FILENAME="$(file -L $LIBGTK_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$LIBGTK_SO_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libGTK-x11_(32-bit) "
	fi

	# Check for libjpeg62; must be 32-bit (required for Stonesense).
	local LIBJPEG62_SO="$(/sbin/ldconfig -p | grep -P '^\tlibjpeg.so.62' | sed 's/^[>]*> //')"
	local LIBJPEG62_SO_32_BIT_FILENAME="$(file -L $LIBJPEG62_SO | grep "32-bit" | cut -d: -f1)"

	if [ -z "$LIBJPEG62_SO_32_BIT_FILENAME" ]; then
		MISSING_DEPS="${MISSING_DEPS}libJPEG62_(32-bit) "
	fi

	# python2 (required for Quickfort)
	if [ -z "$(find_python2)" ]; then
		MISSING_DEPS="${MISSING_DEPS}python2.x "
	fi

	# git (required for Quickfort)
	if [ -z "$(which git)" ]; then
		MISSING_DEPS="${MISSING_DEPS}git "
	fi


	######
	# Warning if MISSING_DEPS_QT5 are missing (if Qt5 libraries are missing).
	######
	if [ -n "$MISSING_DEPS_QT5" ]; then
		echo ""
		echo "Your computer is missing the following Qt5 development programs and libraries required for the latest version of Dwarf Therapist:"
		echo "\t$MISSING_DEPS_QT5"
		echo ""
		echo "If you want to use the latest version of Dwarf Therapist, please install these missing libraries."
		echo "Continuing with older, Qt4 version of Dwarf Therapist.,,"

		USE_QT5=0
	else
		# We can use Qt5
		USE_QT5=1
	fi
	
	######
	# Error if the $MISSING_DEPS string contains a value (aka there are missing dependencies).
	######
	if [ -n "$MISSING_DEPS" ]; then
		# Clean up after ourself.
		# Nothing to do.

		exit_with_error "Your computer is missing the following programs or libraries: $MISSING_DEPS. Install them using your distribution's package manager or use --skip-deps to override."
	fi
}

check_libpng_version () {
        # Check for libpng version 1.5; must be 32 bit.
	local LIBPNG15_SO="$(/sbin/ldconfig -p | grep -P '^\tlibpng15.so' | sed 's/^[>]*> //')"
        # Don't print the errors (if the file doesn't exist)
	local LIBPNG15_SO_32_BIT="$(file -L $LIBPNG15_SO 2> /dev/null | grep "32-bit" | cut -d: -f1)"

        # If libpng15 is not installed (for example if libpng16 is used), we have to recompile the libgraphics of DF.
	if [ -z "$LIBPNG15_SO_32_BIT" ]; then
		USE_FREE_LIBS=1
	fi

}

check_install_dir_is_empty () {
	local LS_OUTPUT="$(ls -A "$INSTALL_DIR")"

	# Verify it's empty.
	if [ -n "$LS_OUTPUT" ]; then
		# Clean up after ourself.
		# Nothing to do.

		exit_with_error "Cannot install. $INSTALL_DIR must be an empty or nonexistant folder. If this is an existing DF installation, use --upgrade."
	fi
}

check_install_dir_contains_df_install () {
	if [ ! -d "$INSTALL_DIR/df_linux" ]; then
		exit_with_error "Cannot upgrade. $INSTALL_DIR does not contain a df_linux folder."
	fi

	if [ ! -d "$INSTALL_DIR/LNP" ]; then
		exit_with_error "Cannot upgrade. $INSTALL_DIR does not contain an LNP folder."
	fi
}

check_ptrace_protection () {
	local PTRACE_PROTECTION_FILE="/proc/sys/kernel/yama/ptrace_scope"

	# Determine if the kernel has ptrace protection compiled in.
	if [ -e $PTRACE_PROTECTION_FILE ]; then
		local PTRACE_PROTECTION="$(cat $PTRACE_PROTECTION_FILE)"
	else
		local PTRACE_PROTECTION="0"
	fi

	if [ "$PTRACE_PROTECTION" = "1" ]; then
		echo ""
		echo "Your system has ptrace protection enabled. DwarfTherapist will not operate properly."
		echo "After installation has completed, run:"
		echo "sudo setcap cap_sys_ptrace=ep $INSTALL_DIR/LNP/utilities/dwarf_therapist/DwarfTherapist"
		echo ""
		echo "See https://github.com/andrewd18/df-lnp-installer/wiki/Dwarf-Therapist-Cannot-Connect-to-Dwarf-Fortress for more information."
	fi
}

checksum_all () {
	# Check for file validity.
	sha1sum -c sha1sums

	# Quit if one or more of the files fails its checksum.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do.
		exit_with_error "One or more file failed its checksum. Delete the erroring file from the ./downloads directory and try again."
	fi
}

copy_dest_dir_to_install_dir () {
	if [ -z "$DEST_DIR" ]; then
		exit_with_error "Script failure. DEST_DIR not defined."
	fi

	if [ -z "$INSTALL_DIR" ]; then
		exit_with_error "Script failure. INSTALL_DIR not defined."
	fi

	echo "Copying files from $DEST_DIR to $INSTALL_DIR."

	# Make the $INSTALL_DIR if it doesn't exist.
	mkdir -p "$INSTALL_DIR"

	# Perform the copy.
	cp -r "$DEST_DIR/"* "$INSTALL_DIR"

	if [ "$?" != "0" ]; then
		# Multi-line equivalent of exit_with_error.

		echo ""
		echo "Woah, something went wrong while copying $DEST_DIR to $INSTALL_DIR."
		echo ""
		echo "It's likely that $INSTALL_DIR is now a giant mess. You will need to clean this up manually."

		if [ "$UPGRADE" = "1" ]; then
			echo "Your working DF install was backed up to $BACKUP_DIR."
		fi

		exit 1
	fi
}

create_backup_dir () {
	mkdir -p "$BACKUP_DIR"
}

create_download_dir () {
	mkdir -p "$DOWNLOAD_DIR"
}

create_dest_dir () {
	mkdir -p "$DEST_DIR"
}

create_df_lnp_desktop_file () {
	local LAUNCHER_DIR="$HOME/.local/share/applications"
	local LAUNCHER_FILENAME="dwarf_fortress_lazy_newb_pack.desktop"
	local LAUNCHER_FULL_PATH="$LAUNCHER_DIR/$LAUNCHER_FILENAME"

	local STARTLNP="$INSTALL_DIR/startlnp"
	local LOGO="$INSTALL_DIR/DF_LNP_Logo_128.png"

	# Delete any existing, out of date launcher.
	if [ -e "$LAUNCHER_FULL_PATH" ]; then
		rm "$LAUNCHER_FULL_PATH"
	fi

	# Create the launcher directory if it doesn't exist.
	mkdir -p "$LAUNCHER_DIR"

	# Install the unedited launcher file.
	# Assume the desktop (KDE, Gnome, etc.) follows freedesktop.org guidelines
	# and does not require a separate program (like kbuildsyscoca4) to detect a
	# new desktop file.
	install --mode=644 "$LAUNCHER_FILENAME" "$LAUNCHER_DIR/"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Let the install command handle the error cleanup here.

		exit_with_error "Installing DF LNP menu item failed."
	fi

	# Edit the dwarf_fortress_lazy_newb_pack.desktop file and replace the exec and icon lines.
	sed -i "s;Exec=path_to_startlnp;Exec=$STARTLNP;g" "$LAUNCHER_FULL_PATH"
	sed -i "s;Icon=path_to_icon;Icon=$LOGO;g" "$LAUNCHER_FULL_PATH"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		rm "$LAUNCHER_FULL_PATH"

		exit_with_error "Updating DF LNP menu item paths failed."
	fi
}

delete_backup_dir () {
	rm -r "$BACKUP_DIR"
}

delete_download_dir () {
	rm -r "$DOWNLOAD_DIR"
}

delete_dest_dir () {
	rm -r "$DEST_DIR"
}

download_all () {
	if [ -z "$DOWNLOAD_DIR" ]; then
		exit_with_error "Script failure. DOWNLOAD_DIR undefined."
	fi

	# Apps and utilities
	download_file "http://www.bay12games.com/dwarves/df_34_11_linux.tar.bz2"
	download_file "http://dethware.org/dfhack/download/dfhack-0.34.11-r3-Linux.tar.gz"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7248&f=Utility_Plugins_v0.44-Windows-0.34.11.r3.zip.zip"
	download_file "http://df.zweistein.cz/soundsense/soundSense_42_186.zip"
	download_file "http://drone.io/bitbucket.org/Dricus/lazy-newbpack/files/target/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=2182&f=Chromafort.zip"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7905&f=DFAnnouncementFilter.zip"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7889&f=Dwarf+Therapist.pdf"
    download_dffi_file "http://dffd.wimbli.com/download.php?id=8185&f=blueprints.zip"

	# Graphics packs.
	download_dffi_file "http://dffd.wimbli.com/download.php?id=2430&f=Phoebus_34_11v01.zip"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=5945&f=CLA_graphic_set_v15-STANDALONE.rar"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7362&f=Ironhand16+upgrade+0.73.4.zip"
	download_file "http://www.alexanderocias.com/jollybastion/JollyBastion34-10v5.zip"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7025&f=Mayday+34.11.zip"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7728&f=%5B16x16%5D+Obsidian+%28v.0.8%29.zip"
	download_dffi_file "http://dffd.wimbli.com/download.php?id=7867&f=%5B16x16%5D+Spacefox+34.11v1.0.zip"

	# Special cases.

	# Download Splintermind Attributes HG repo
	download_dwarf_therapist

	# Download quickfort repo.
	download_quickfort

        if [ "$USE_FREE_LIBS" = "1" ]; then
                download_dwarf_fortress_unfunck
        fi
}

download_dffi_file () {
	if [ -z "$1" ]; then
		exit_with_error "Script failure. download_dffi_file requires a URL argument."
	fi

	# If the user passed in --override-user-agent, then use a recent Mozilla browser UA string.
	# See https://developer.mozilla.org/en-US/docs/Gecko_user_agent_string_reference
	# Otherwise fall back to wget default by using a blank value.
	if [ "$OVERRIDE_USER_AGENT" = "1" ]; then
		local USER_AGENT_STRING="-U Mozilla/5.0"
	fi

	# -nc is "no clobber" for not overwriting files we already have.
	# --directory-prefix drops the files into the download folder.
	# --content-disposition asks DFFI for the actual name of the file, not the php link.
	#   Sadly, simply asking for the filename counts as a "download" so this script will be
	#   inflating people's DFFI download counts. Oh well.
	local WGET_OPTIONS="-nc --directory-prefix=$DOWNLOAD_DIR --content-disposition $USER_AGENT_STRING"

	# NOTE: When calling wget, don't wrap $WGET_OPTIONS in quotes; wget doesn't like it.

	wget $WGET_OPTIONS "$1"

	# Quit if downloading failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do; wget will recover.

		exit_with_error "Downloading $1 failed. Consider using --override-user-agent."
	fi
}

download_file () {
	if [ -z "$1" ]; then
		exit_with_error "Script failure. download_file requires a URL argument."
	fi

	# If the user passed in --override-user-agent, then use a recent Mozilla browser UA string.
	# See https://developer.mozilla.org/en-US/docs/Gecko_user_agent_string_reference
	# Otherwise fall back to wget default by using a blank value.
	if [ "$OVERRIDE_USER_AGENT" = "1" ]; then
		local USER_AGENT_STRING="-U Mozilla/5.0"
	fi

	# -nc is "no clobber" for not overwriting files we already have.
	# --directory-prefix drops the files into the download folder.
	local WGET_OPTIONS="-nc --directory-prefix=$DOWNLOAD_DIR $USER_AGENT_STRING"

	# NOTE: When calling wget, don't wrap $WGET_OPTIONS in quotes; wget doesn't like it.

	wget $WGET_OPTIONS "$1"

	# Quit if downloading failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do; wget will recover.

		exit_with_error "Downloading $1 failed. Consider using --override-user-agent."
	fi
}

download_dwarf_therapist () {
	if [ "$USE_QT5" = "0" ]; then
		# If the user doesn't want the Qt5 version of DwarfTherapist,
		# use the old version from the hg repository

		local DWARF_THERAPIST_HG_DIR="$DOWNLOAD_DIR/dwarftherapist"
		local SPLINTERMIND_REPO_URL="https://code.google.com/r/splintermind-attributes/"

		# WORKAROUND:
		# Force a checkout of revision 20.5 because 20.6 uses Qt5.
		# Resolves issue #23.
		local REV_20_5="4ef8173a7a94"

		# Check for and fix the issue I had in 0.2.0 where I used the wrong upstream URL.
		# Get the current upstream url. If the directory doesn't exist the var will contain "".
		local CURRENT_UPSTREAM_URL="$(hg paths --cwd $DWARF_THERAPIST_HG_DIR | grep default | cut -d" " -f3)"

		if [ "$CURRENT_UPSTREAM_URL" != "$SPLINTERMIND_REPO_URL" ]; then
			# Inform the user (assuming they're paying attention)
			echo "Dwarf Therapist repo is missing or has wrong upstream URL; recloning."

			# Bomb the directory, if it even existed in the first place.
			if [ -d "$DWARF_THERAPIST_HG_DIR" ]; then
				rm -r "$DWARF_THERAPIST_HG_DIR"
			fi

			# Reclone.
			hg clone -r "$REV_20_5" "$SPLINTERMIND_REPO_URL" "$DWARF_THERAPIST_HG_DIR"
		else
			# URL is good; just get the latest changes.
			hg update -r "$REV_20_5" --cwd "$DWARF_THERAPIST_HG_DIR"
		fi

	else
		# If the latest version can be used, use the new git repository
		
		local DWARF_THERAPIST_DIR="$DOWNLOAD_DIR/dwarftherapist"
		local SPLINTERMIND_REPO_URL="https://github.com/splintermind/Dwarf-Therapist"

		if [ -d "$DWARF_THERAPIST_DIR" ]; then
			(cd "$DWARF_THERAPIST_DIR" && git pull)
		else
			mkdir -p "$DWARF_THERAPIST_DIR"
			git clone "$SPLINTERMIND_REPO_URL" "$DWARF_THERAPIST_DIR"
		fi




	fi


	# Quit if downloading failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Nothing to do; that's hg's job.

		exit_with_error "Cloning / updating Dwarf Therapist HG repository failed."
	fi
}

download_dwarf_fortress_unfunck () {
	local DF_UNFUNCK_DIR="$DOWNLOAD_DIR/df_unfunck"
	local DF_UNFUNCK_REPO_URL="https://github.com/svenstaro/dwarf_fortress_unfuck"

	if [ -d "$DF_UNFUNCK_DIR" ]; then
		# This needs to be one unified command or else git doesn't know where the working directory is.
		( cd "$DF_UNFUNCK_DIR" && git pull )
	else
		mkdir -p "$DF_UNFUNCK_DIR"
		git clone "$DF_UNFUNCK_REPO_URL" "$DF_UNFUNCK_DIR"

	fi
}

download_quickfort () {
	local QUICKFORT_DIR="$DOWNLOAD_DIR/quickfort"
	local QUICKFORT_REPO_URL="https://github.com/joelpt/quickfort.git"

	if [ -d "$QUICKFORT_DIR" ]; then
		# This needs to be one unified command or else git doesn't know where the working directory is.
		( cd "$QUICKFORT_DIR" && git pull )
	else
		mkdir -p "$QUICKFORT_DIR"
		git clone "$QUICKFORT_REPO_URL" "$QUICKFORT_DIR"
	fi
}

exit_with_error () {
	echo ""
	echo "df-lnp-installer.sh: $1 Exiting."

	exit 1
}

fix_cla_missing_mouse_png () {
	local CLA_FOLDER="$DEST_DIR/LNP/graphics/[16x16] CLA v15"
	local VANILLA_GFX_FOLDER="$DEST_DIR/LNP/graphics/[16x16] ASCII Default 0.34.11"

	cp "$VANILLA_GFX_FOLDER/data/art/mouse.png" "$CLA_FOLDER/data/art/mouse.png"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$CLA_FOLDER/data/art/mouse.png" ]; then
			rm "$CLA_FOLDER/data/art/mouse.png"
		fi

		exit_with_error "Applying CLA Missing Mouse patch failed."
	fi
}

fix_jolly_bastion_missing_graphics_dir () {
	local JB_FOLDER="$DEST_DIR/LNP/graphics/[12x12] Jolly Bastion 34.10v5"

	mkdir -p "$JB_FOLDER/raw/graphics"
}

fix_jolly_bastion_missing_mouse_png () {
	local JB_FOLDER="$DEST_DIR/LNP/graphics/[12x12] Jolly Bastion 34.10v5"
	local VANILLA_GFX_FOLDER="$DEST_DIR/LNP/graphics/[16x16] ASCII Default 0.34.11"

	cp "$VANILLA_GFX_FOLDER/data/art/mouse.png" "$JB_FOLDER/data/art/mouse.png"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$JB_FOLDER/data/art/mouse.png" ]; then
			rm "$JB_FOLDER/data/art/mouse.png"
		fi

		exit_with_error "Applying Jolly Bastion Missing Mouse patch failed."
	fi
}

fix_obsidian_gfx_font_ttf_name () {
	local OBSIDIAN_FOLDER="$DEST_DIR/LNP/graphics/[16x16] Obsidian 0.8a"
	
	if [ -e "$OBSIDIAN_FOLDER/data/art/font.TTF" ]; then
		mv "$OBSIDIAN_FOLDER/data/art/font.TTF" "$OBSIDIAN_FOLDER/data/art/font.ttf"
	fi
}

fix_phoebus_missing_mouse_png () {
	# Resolves GitHub issue #6.
	local PHOEBUS_FOLDER="$DEST_DIR/LNP/graphics/[16x16] Phoebus 34.11v01"
	local VANILLA_GFX_FOLDER="$DEST_DIR/LNP/graphics/[16x16] ASCII Default 0.34.11"

	cp "$VANILLA_GFX_FOLDER/data/art/mouse.png" "$PHOEBUS_FOLDER/data/art/mouse.png"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$PHOEBUS_FOLDER/data/art/mouse.png" ]; then
			rm "$PHOEBUS_FOLDER/data/art/mouse.png"
		fi

		exit_with_error "Applying Phoebus Missing Mouse patch failed."
	fi
}

fix_phoebus_gfx_font_ttf_name () {
	local PHOEBUS_FOLDER="$DEST_DIR/LNP/graphics/[16x16] Phoebus 34.11v01"
	
	if [ -e "$PHOEBUS_FOLDER/data/art/font.TTF" ]; then
		mv "$PHOEBUS_FOLDER/data/art/font.TTF" "$PHOEBUS_FOLDER/data/art/font.ttf"
	fi
}

fix_soundsense_missing_gamelog () {
	# SoundSense comes preconfigured to expect gamelog.txt to be in ../
	# however this is not the case for the LNP.
	#
	# This modifies the configuration.xml file so users don't get an annoying
	# pop-up on start looking for gamelog.txt.
	#
	# NOTE: gamelog.txt doesn't exist until DF creates it, and due to LNP start order,
	# DF often starts after soundsense does. So instead of reworking the LNP start order,
	# I just manually create a blank one using touch.

	local GAMELOG_FILE_TMP="$DEST_DIR/df_linux/gamelog.txt"
	local GAMELOG_FILE_INSTALLED="$INSTALL_DIR/df_linux/gamelog.txt"

	# Create the gamelog.txt file.
	touch "$GAMELOG_FILE_TMP"

	# Get the XML configuration file.
	local SS_CONFIG_FILE="$DEST_DIR/LNP/utilities/soundsense/configuration.xml"
	local FIND_LINE_WITH="\<gamelog"
	local TEXT_TO_REPLACE="path=\"../gamelog.txt\""
	local REPLACE_WITH="path=\"$GAMELOG_FILE_INSTALLED\""

	# substitute "foo" with "bar" ONLY for lines which contain "baz"
	# sed '/baz/s/foo/bar/g'
	# NOTE: Like in ask_for_preferred_install_dir, use custom ; delimeter so as not to
	# screw up sed with file paths.
	sed -ibak "/$FIND_LINE_WITH/s;$TEXT_TO_REPLACE;$REPLACE_WITH;g" "$SS_CONFIG_FILE"

	# Quit if replacement failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# TODO: Install a clean configuration.xml file from the downloads folder?

		exit_with_error "Modifying soundsense configuration.xml file failed."
	fi
}

fix_vanilla_df_openal_issue () {
	# See http://dwarffortresswiki.org/index.php/DF2012:Installation

	# The filename variables will be empty strings if no file exists.
	# Otherwise they will contain the filename of the associated 32-bit library.
	local OPENAL_SO="$(/sbin/ldconfig -p | grep -P '^\tlibopenal.so.1')"
	local OPENAL_SO_32_BIT_FILENAME="$(file -L $OPENAL_SO | grep "32-bit" | cut -d: -f1)"

	local LIBSNDFILE_SO="$(/sbin/ldconfig -p | grep -P '^\tlibsndfile.so.1')"
	local LIBSNDFILE_SO_32_BIT_FILENAME="$(file -L $LIBSNDFILE_SO | grep "32-bit" | cut -d: -f1)"

	local VANILLA_DF_LIBS_DIR="$DEST_DIR/df_linux/libs"

	# If the file given by the filename string exists, link it.
	if [ -e "$OPENAL_SO_32_BIT_FILENAME" ]; then
		ln -s "$OPENAL_SO_32_BIT_FILENAME" "$VANILLA_DF_LIBS_DIR/libopenal.so"
	fi

	if [ -e "$LIBSNDFILE_SO_32_BIT_FILENAME" ]; then
		ln -s "$LIBSNDFILE_SO_32_BIT_FILENAME" "$VANILLA_DF_LIBS_DIR/libsndfile.so"
	fi
}

fix_vanilla_df_ancient_libstdcpp () {
	# There are cases, particularly on newer distros (see Arch Linux), where libstdc++ 3.4 isn't available.
	# This function simply renames the static libstdc++ included with DF to .old,
	# thus forcing DF to use the system library.

	local VANILLA_DF_LIBS_DIR="$DEST_DIR/df_linux/libs"

	# If the file given by the filename string exists and is a normal file (not a symlink), rename it.
	if [ -f "$VANILLA_DF_LIBS_DIR/libstdc++.so" ]; then
		mv "$VANILLA_DF_LIBS_DIR/libstdc++.so.6" "$VANILLA_DF_LIBS_DIR/libstdc++.so.6.old"
	fi
}

fix_vanilla_df_lnp_settings_not_applied_by_default () {
	# The df-lnp-installer will set up the appropriate "[16x16] ASCII Default" folder
	# in $INSTALL_DIR/LNP/graphics/ but the LNP settings don't get applied to the df_linux/data folder
	# until the user clicks LNP -> Graphics Tab -> ASCII Default -> Install Graphics.
	#
	# This method "fixes" that by applying the expected LNP settings to the df_linux folder right from the get-go.

	local LNP_PATCH_DIR="./patches/ascii_default_gfx"
	local DF_FOLDER="$DEST_DIR/df_linux"

	patch -d "$DF_FOLDER/data/init/" < "$LNP_PATCH_DIR/init_lnp_defaults.patch"
	patch -d "$DF_FOLDER/data/init/" < "$LNP_PATCH_DIR/dinit_lnp_defaults.patch"
}

install_all () {
	if [ -z "$DEST_DIR" ]; then
		exit_with_error "Script failure. DEST_DIR undefined."
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

	install_soundsense_app

	build_dwarf_therapist
	install_dwarf_therapist

	install_quickfort
	install_chromafort
	install_df_announcement_filter

	# Must come after install_vanilla_df
	install_lnp_embark_profiles

        # Idem
        if [ "$USE_FREE_LIBS" = "1" ]; then
                build_dwarf_fortress_unfunck
                install_dwarf_fortress_unfunck
        fi

	install_df_lnp_logo
}

install_chromafort () {
	local CHROMAFORT_ZIP="$DOWNLOAD_DIR/Chromafort.zip"
	local CHROMAFORT_TEMP_FOLDER="./chromafort_unzip"
	mkdir -p "$CHROMAFORT_TEMP_FOLDER"

	unzip -d "$CHROMAFORT_TEMP_FOLDER" "$CHROMAFORT_ZIP"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$CHROMAFORT_TEMP_FOLDER" ]; then
			rm -r "$CHROMAFORT_TEMP_FOLDER"
		fi

		exit_with_error "Unzipping Chromafort failed."
	fi

	local UTILITIES_FOLDER="$DEST_DIR/LNP/utilities"

	mkdir -p "$UTILITIES_FOLDER/chromafort"

	# Copy program and all documentation.
	cp "$CHROMAFORT_TEMP_FOLDER/Chromafort/"* "$UTILITIES_FOLDER/chromafort/"

	# Quit if copying failed.
	if [ "$?" != "0" ]; then
		exit_with_error "Installing Chromafort failed."
	fi

	rm -r "$CHROMAFORT_TEMP_FOLDER"
}

install_cla_graphics_pack () {
	local GFX_PACK="$DOWNLOAD_DIR/CLA_graphic_set_v15-STANDALONE.rar"
	local GFX_PREFIX="CLA"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] CLA v15"
	local LNP_PATCH_DIR="./patches/cla_gfx"

	install_gfx_pack "$GFX_PACK" "$GFX_PREFIX" "$INSTALL_GFX_DIR" "$LNP_PATCH_DIR"
}

install_df_announcement_filter () {
	local DFAF_ZIP="$DOWNLOAD_DIR/DFAnnouncementFilter.zip"
	local DFAF_TEMP_FOLDER="./df_announcement_filter_unzip"
	mkdir -p "$DFAF_TEMP_FOLDER"

	unzip -d "$DFAF_TEMP_FOLDER" "$DFAF_ZIP"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$DFAF_TEMP_FOLDER" ]; then
			rm -r "$DFAF_TEMP_FOLDER"
		fi

		exit_with_error "Unzipping DF Announcement Filter failed."
	fi

	local UTILITIES_FOLDER="$DEST_DIR/LNP/utilities"

	mkdir -p "$UTILITIES_FOLDER/df_announcement_filter"

	# Copy program and all documentation.
	cp "$DFAF_TEMP_FOLDER/"* "$UTILITIES_FOLDER/df_announcement_filter/"

	# Quit if copying failed.
	if [ "$?" != "0" ]; then
		exit_with_error "Installing DF Announcement Filter failed."
	fi

	rm -r "$DFAF_TEMP_FOLDER"
}

install_df_lnp_logo () {
	local LOGO="./DF_LNP_Logo_128.png"

	install --mode=644 "$LOGO" "$DEST_DIR/"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Let the install command handle the error cleanup here.

		exit_with_error "Installing DF LNP Logo failed."
	fi
}

install_dfhack () {
	local DF_HACK_TARBALL="$DOWNLOAD_DIR/dfhack-0.34.11-r3-Linux.tar.gz"

	# Extract to the installation/df_linux directory.
	tar --directory "$DEST_DIR/df_linux" -xzvf "$DF_HACK_TARBALL"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		# Remove folders.
		if [ -d "$DEST_DIR/df_linux/hack" ]; then
			rm -r "$DEST_DIR/df_linux/hack"
		fi

		if [ -d "$DEST_DIR/df_linux/stonesense" ]; then
			rm -r "$DEST_DIR/df_linux/stonesense"
		fi

		# Remove executables.
		if [ -e "$DEST_DIR/df_linux/dfhack" ]; then
			rm "$DEST_DIR/df_linux/dfhack"
		fi

		if [ -e "$DEST_DIR/df_linux/dfhack-run" ]; then
			rm "$DEST_DIR/df_linux/dfhack-run"
		fi

		if [ -e "$DEST_DIR/df_linux/dfhack-init.example" ]; then
			rm "$DEST_DIR/df_linux/dfhack-init.example"
		fi

		exit_with_error "Untarring DF Hack failed."
	fi
}

install_dwarf_therapist () {
	if [ -z "$DOWNLOAD_DIR" ]; then
		exit_with_error "Script failure. DOWNLOAD_DIR undefined."
	fi

	if [ -z "$DEST_DIR" ]; then
		exit_with_error "Script failure. DEST_DIR undefined."
	fi

	local DWARF_THERAPIST_HG_DIR="$DOWNLOAD_DIR/dwarftherapist"
	local RELEASE_DIR="$DWARF_THERAPIST_HG_DIR/bin/release"

	local UTILITIES_FOLDER="$DEST_DIR/LNP/utilities"

	mkdir -p "$UTILITIES_FOLDER/dwarf_therapist"

	# Copy app.
	cp "$RELEASE_DIR/DwarfTherapist" "$UTILITIES_FOLDER/dwarf_therapist/"

	# Quit if copying failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$UTILITIES_FOLDER/dwarf_therapist/" ]; then
			rm -r "$UTILITIES_FOLDER/dwarf_therapist/"
		fi

		exit_with_error "Copying Dwarf Therapist app failed."
	fi

	# Create log file.
	mkdir -p "$UTILITIES_FOLDER/dwarf_therapist/log"
	touch "$UTILITIES_FOLDER/dwarf_therapist/log/run.log"

	# Copy etc files.
	cp -r "$DWARF_THERAPIST_HG_DIR/etc" "$UTILITIES_FOLDER/dwarf_therapist/"

	# Quit if copying failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$UTILITIES_FOLDER/dwarf_therapist/" ]; then
			rm -r "$UTILITIES_FOLDER/dwarf_therapist/"
		fi

		exit_with_error "Copying Dwarf Therapist ancillary files failed."
	fi

	# Copy the manual.
	local MANUAL="$DOWNLOAD_DIR/Dwarf Therapist.pdf"
	cp "$MANUAL" "$UTILITIES_FOLDER/dwarf_therapist/"
}

install_dwarf_fortress_unfunck () {
	if [ -z "$DOWNLOAD_DIR" ]; then
		exit_with_error "Script failure. DOWNLOAD_DIR undefined."
	fi

	if [ -z "$DEST_DIR" ]; then
		exit_with_error "Script failure. DEST_DIR undefined."
	fi

	local DF_UNFUNCK_DIR="$DOWNLOAD_DIR/df_unfunck"
        
        local LIBS_DIR="$DEST_DIR/df_linux/libs/"

        # Copy libgraphics.so
        echo "Installing libgraphics.so"
        cp "$DF_UNFUNCK_DIR/libs/libgraphics.so" "$LIBS_DIR/libgraphics.so"

	# Quit if copying failed.
	if [ "$?" != "0" ]; then
		exit_with_error "Replacing libgraphics.so failed."
	fi

        rm "$LIBS_DIR/libstdc++.so.6"

	# Quit if deleting failed.
	if [ "$?" != "0" ]; then
		exit_with_error "Deleting libgraphics.so failed."
	fi


}

install_quickfort () {
    if [ -z "$DOWNLOAD_DIR" ]; then
        exit_with_error "Script failure. DOWNLOAD_DIR undefined."
    fi

    if [ -z "$DEST_DIR" ]; then
        exit_with_error "Script failure. DEST_DIR undefined."
    fi

    local QF_BLUEPRINTS_ZIP="$DOWNLOAD_DIR/blueprints.zip"
    local QF_BLUEPRINTS_TEMP_FOLDER="./blueprints_unzip"
    local QF_BLUEPRINTS_DIR="$DEST_DIR/df_linux/blueprints"
    local QFCONVERT_DIR="$DOWNLOAD_DIR/quickfort/qfconvert"
    local UTILITIES_FOLDER="$DEST_DIR/LNP/utilities"

    unzip -d "$QF_BLUEPRINTS_TEMP_FOLDER" "$QF_BLUEPRINTS_ZIP"
    # Quit if extracting failed.
    if [ "$?" != "0" ]; then
        # Clean up after ourself.
        if [ -e "$QF_BLUEPRINTS_TEMP_FOLDER" ]; then
            rm -r "$QF_BLUEPRINTS_TEMP_FOLDER"
        fi

        exit_with_error "Unzipping Quickfort blueprints failed."
    fi

    mkdir -p "$QF_BLUEPRINTS_DIR"
    cp -nufr "$QF_BLUEPRINTS_TEMP_FOLDER/Community Quickfort Blueprints v2.1/"* "$QF_BLUEPRINTS_DIR"

    # Quit if copying failed.
    if [ "$?" != "0" ]; then
        # We don't want to delete the user's custom blueprints,
        # so we leave df_linux/blueprints alone

        exit_with_error "Copying quickfort blueprints failed."
    fi

    mkdir -p "$UTILITIES_FOLDER/qfconvert"

    # Copy files.
    cp -r "$QFCONVERT_DIR/"* "$UTILITIES_FOLDER/qfconvert/"

    # Quit if copying failed.
    if [ "$?" != "0" ]; then
        # Clean up after ourself.
        if [ -e "$UTILITIES_FOLDER/qfconvert/" ]; then
            rm -r "$UTILITIES_FOLDER/qfconvert/"
        fi

        exit_with_error "Copying qfconvert scripts failed."
    fi

    rm -rf "$QF_BLUEPRINTS_TEMP_FOLDER"
}

install_falconne_dfhack_plugins () {
	local FALCONNE_PLUGINS_ZIP="$DOWNLOAD_DIR/Utility_Plugins_v0.44-Windows-0.34.11.r3.zip.zip"
	local FALCONNE_TEMP_FOLDER="./falconne_unzip"
	mkdir -p "$FALCONNE_TEMP_FOLDER"

	unzip -d "$FALCONNE_TEMP_FOLDER" "$FALCONNE_PLUGINS_ZIP"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$FALCONNE_TEMP_FOLDER" ]; then
			rm -r "$FALCONNE_TEMP_FOLDER"
		fi

		exit_with_error "Unzipping Falconne UI plugins failed."
	fi

	local PLUGINS_DIR="$DEST_DIR/df_linux/hack/plugins/"

	# Copy all files from Linux/ directory to DF Hack Plugins dir.
	cp "$FALCONNE_TEMP_FOLDER/Linux/"*.so "$PLUGINS_DIR"

	# Quit if copying failed.
	if [ "$?" != "0" ]; then
		# These are going to be a lot of work to clean up individually
		# so as not to remove all of dfhack plugins. So instead I will rely on
		# dfhack complaining if it can't load a file that got corrupted.

		exit_with_error "Copying Falconne UI plugins failed."
	fi

	rm -r "$FALCONNE_TEMP_FOLDER"
}

install_gfx_pack () {
	local GFX_PACK="$1"
	local GFX_PREFIX="$2"
	local INSTALL_GFX_DIR="$3"
	local PATCH_DIR="$4"

	local TEMP_UNZIP_DIR="./gfx_unzip"

	mkdir -p "$TEMP_UNZIP_DIR"

	# Run the graphics pack mimetype.
	local MIMETYPE="$(file -b --mime-type "$GFX_PACK")"

	# Run the appropriate extraction app.
	case "$MIMETYPE" in
		'application/zip') unzip -d "$TEMP_UNZIP_DIR" "$GFX_PACK" ;;
		'application/x-rar') unrar x "$GFX_PACK" "$TEMP_UNZIP_DIR" ;;
		*) exit_with_error "install_gfx_pack: unknown mimetype $MIMETYPE for $GFX_PACK" ;;
	esac


	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		exit_with_error "Unzipping "$GFX_PACK" failed."
	fi

	# Install Art
	mkdir -p "$INSTALL_GFX_DIR/data/art"
	cp "$TEMP_UNZIP_DIR/$GFX_PREFIX/data/art/"* "$INSTALL_GFX_DIR/data/art/"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Installing $INSTALL_GFX_DIR/data/art failed."
	fi

	# Install init
	mkdir -p "$INSTALL_GFX_DIR/data/init"
	cp "$TEMP_UNZIP_DIR/$GFX_PREFIX/data/init/"* "$INSTALL_GFX_DIR/data/init/"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Installing $INSTALL_GFX_DIR/data/init failed."
	fi

	# Apply LNP patches.
	patch -d "$INSTALL_GFX_DIR/data/init/" < "$LNP_PATCH_DIR/init_lnp_defaults.patch"
	patch -d "$INSTALL_GFX_DIR/data/init/" < "$LNP_PATCH_DIR/dinit_lnp_defaults.patch"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Applying $LNP_PATCH_DIR patches failed."
	fi

	# Install raws
	mkdir -p "$INSTALL_GFX_DIR/raw"

	if [ -d "$TEMP_UNZIP_DIR/$GFX_PREFIX/raw/graphics" ]; then
		cp -r "$TEMP_UNZIP_DIR/$GFX_PREFIX/raw/graphics" "$INSTALL_GFX_DIR/raw"
	fi

	if [ -d "$TEMP_UNZIP_DIR/$GFX_PREFIX/raw/objects" ]; then
		cp -r "$TEMP_UNZIP_DIR/$GFX_PREFIX/raw/objects" "$INSTALL_GFX_DIR/raw"
	fi

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Installing $INSTALL_GFX_DIR raws failed."
	fi

	rm -r "$TEMP_UNZIP_DIR"
}

install_ironhand_gfx_pack () {
	local GFX_PACK="$DOWNLOAD_DIR/Ironhand16 upgrade 0.73.4.zip"
	local GFX_PREFIX="Dwarf Fortress"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] Ironhand 0.73.4"
	local LNP_PATCH_DIR="./patches/ironhand_gfx"

	install_gfx_pack "$GFX_PACK" "$GFX_PREFIX" "$INSTALL_GFX_DIR" "$LNP_PATCH_DIR"
}

install_jolly_bastion_gfx_pack () {
	local GFX_PACK="$DOWNLOAD_DIR/JollyBastion34-10v5.zip"
	local GFX_PREFIX="JollyBastion34-10v5/12x12"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[12x12] Jolly Bastion 34.10v5"
	local LNP_PATCH_DIR="./patches/jolly_bastion_gfx"

	install_gfx_pack "$GFX_PACK" "$GFX_PREFIX" "$INSTALL_GFX_DIR" "$LNP_PATCH_DIR"
}

install_lnp () {
	local LNP_TARBALL="$DOWNLOAD_DIR/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"

	# Extract to the installation directory.
	tar --directory "$DEST_DIR" -xjvf "$LNP_TARBALL"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$DEST_DIR/LNP" ]; then
			rm -r "$DEST_DIR/LNP"
		fi

		exit_with_error "Untarring LNP failed."
	fi
}

install_lnp_embark_profiles () {
	local EMBARK_PROFILES="./embark_profiles.txt"
	local DF_INIT_DIR="$DEST_DIR/df_linux/data/init"

	install --mode=644 "$EMBARK_PROFILES" "$DF_INIT_DIR"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Let the install command handle the error cleanup here.

		exit_with_error "Copying LNP Embark Profiles failed."
	fi
}

install_lnp_yaml () {
	local LNP_YAML_FILE="./lnp.yaml"
	local LNP_DIR="$DEST_DIR/LNP"

	install --mode=644 "$LNP_YAML_FILE" "$LNP_DIR"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Let the install command handle the error cleanup here.

		exit_with_error "Copying LNP Yaml file failed."
	fi
}

install_mayday_gfx_pack () {
	local GFX_PACK="$DOWNLOAD_DIR/Mayday 34.11.zip"
	local GFX_PREFIX="Mayday"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] Mayday 0.34.11"
	local LNP_PATCH_DIR="./patches/mayday_gfx"

	install_gfx_pack "$GFX_PACK" "$GFX_PREFIX" "$INSTALL_GFX_DIR" "$LNP_PATCH_DIR"
}

install_obsidian_gfx_pack () {
	local GFX_PACK="$DOWNLOAD_DIR/[16x16] Obsidian (v.0.8).zip"
	local GFX_PREFIX="[16x16] Obsidian"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] Obsidian 0.8a"
	local LNP_PATCH_DIR="./patches/obsidian_gfx"

	install_gfx_pack "$GFX_PACK" "$GFX_PREFIX" "$INSTALL_GFX_DIR" "$LNP_PATCH_DIR"
}

install_phoebus_gfx_pack () {
	# NOTE: Cannot use install_gfx_pack method because Phoebus data/init/ folder is packed weird.
	local GFX_PACK="$DOWNLOAD_DIR/Phoebus_34_11v01.zip"
	local TEMP_UNZIP_DIR="./phoebus_unzip"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] Phoebus 34.11v01"
	local LNP_PATCH_DIR="./patches/phoebus_gfx"

	mkdir -p "$TEMP_UNZIP_DIR"
	unzip -d "$TEMP_UNZIP_DIR" "$GFX_PACK"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

	exit_with_error "Unzipping Phoebus graphics pack failed."
	fi

	# Install Art
	mkdir -p "$INSTALL_GFX_DIR/data/art"
	cp "$TEMP_UNZIP_DIR/data/art/"* "$INSTALL_GFX_DIR/data/art/"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Installing Phoebus art failed."
	fi

	# Install init
	mkdir -p "$INSTALL_GFX_DIR/data/init"
	cp "$TEMP_UNZIP_DIR/data/init/phoebus_nott/"* "$INSTALL_GFX_DIR/data/init/"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

	exit_with_error "Installing Phoebus init failed."
	fi

	# Install Art
	mkdir -p "$INSTALL_GFX_DIR/data/art"
	cp "$TEMP_UNZIP_DIR/data/art/"* "$INSTALL_GFX_DIR/data/art/"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

	exit_with_error "Installing Phoebus art failed."
	fi

	# Install init
	mkdir -p "$INSTALL_GFX_DIR/data/init"
	cp "$TEMP_UNZIP_DIR/data/init/phoebus_nott/"* "$INSTALL_GFX_DIR/data/init/"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

	exit_with_error "Installing Phoebus init failed."
	fi

	# Apply LNP patches.
	patch -d "$INSTALL_GFX_DIR/data/init/" < "$LNP_PATCH_DIR/init_lnp_defaults.patch"
	patch -d "$INSTALL_GFX_DIR/data/init/" < "$LNP_PATCH_DIR/dinit_lnp_defaults.patch"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

	exit_with_error "Applying Phoebus LNP patches failed."
	fi

	# Install raws
	mkdir -p "$INSTALL_GFX_DIR/raw"
	cp -r "$TEMP_UNZIP_DIR/raw/graphics" "$INSTALL_GFX_DIR/raw"
	cp -r "$TEMP_UNZIP_DIR/raw/objects" "$INSTALL_GFX_DIR/raw"

	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$TEMP_UNZIP_DIR" ]; then
			rm -r "$TEMP_UNZIP_DIR"
		fi

		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

	exit_with_error "Installing Phoebus raws failed."
	fi

	rm -r "$TEMP_UNZIP_DIR"
}

install_soundsense_app () {
	local SOUNDSENSE_ZIP="$DOWNLOAD_DIR/soundSense_42_186.zip"
	local UTILITIES_FOLDER="$DEST_DIR/LNP/utilities"

	unzip -d "$UTILITIES_FOLDER" "$SOUNDSENSE_ZIP"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		# Clean up after ourself.
		if [ -e "$UTILITIES_FOLDER/soundsense" ]; then
			rm -r "$UTILITIES_FOLDER/soundsense"
		fi

		exit_with_error "Unzipping SoundSense application failed."
	fi

	# Replace SoundSense shell script with a duplicate that uses Unix line endings.
	# sed didn't work for some reason; using tr. :/
	tr -d '\015' <"$UTILITIES_FOLDER/soundsense/soundSense.sh" >"$UTILITIES_FOLDER/soundsense/soundsense_unix.sh"
	rm "$UTILITIES_FOLDER/soundsense/soundSense.sh"
	mv "$UTILITIES_FOLDER/soundsense/soundsense_unix.sh" "$UTILITIES_FOLDER/soundsense/soundSense.sh"

	# Make soundSense shell script executable.
	chmod +x "$UTILITIES_FOLDER/soundsense/soundSense.sh"
}

install_spacefox_gfx_pack () {
	local GFX_PACK="$DOWNLOAD_DIR/[16x16] Spacefox 34.11v1.0.zip"
	local GFX_PREFIX="[16x16] Spacefox 34.11v1.0"
	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] Spacefox 34.11v1.0"
	local LNP_PATCH_DIR="./patches/spacefox_gfx"

	install_gfx_pack "$GFX_PACK" "$GFX_PREFIX" "$INSTALL_GFX_DIR" "$LNP_PATCH_DIR"
}

install_vanilla_df () {
	local VANILLA_DF_TARBALL="$DOWNLOAD_DIR/df_34_11_linux.tar.bz2"

	# Extract to the installation directory.
	tar --directory "$DEST_DIR" -xjvf "$VANILLA_DF_TARBALL"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		if [ -d "$DEST_DIR/df_linux" ]; then
			rm -r "$DEST_DIR/df_linux"
		fi

		exit_with_error "Untarring Vanilla DF failed."
	fi
}

install_vanilla_df_gfx_pack () {
	# NOTE: Cannot use install_gfx_pack because ascii default graphics aren't in a standalone .zip or .rar.
	local DATA_FOLDER="$DEST_DIR/df_linux/data"
	local RAW_FOLDER="$DEST_DIR/df_linux/raw"

	local INSTALL_GFX_DIR="$DEST_DIR/LNP/graphics/[16x16] ASCII Default 0.34.11"
	local LNP_PATCH_DIR="./patches/ascii_default_gfx"

	mkdir -p "$INSTALL_GFX_DIR"

	# Copy the data and raw folders from the vanilla df install location
	# Put them in $INSTALL_GFX_DIR
	cp -r "$DATA_FOLDER" "$INSTALL_GFX_DIR"
	cp -r "$RAW_FOLDER" "$INSTALL_GFX_DIR"

	# Quit if extracting failed.
	if [ "$?" != "0" ]; then
		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Copying Vanilla DF graphics pack failed."
	fi

	# Apply LNP patches.
	patch -d "$INSTALL_GFX_DIR/data/init/" < "$LNP_PATCH_DIR/init_lnp_defaults.patch"
	patch -d "$INSTALL_GFX_DIR/data/init/" < "$LNP_PATCH_DIR/dinit_lnp_defaults.patch"

	# Quit if patching failed.
	if [ "$?" != "0" ]; then
		if [ -e "$INSTALL_GFX_DIR" ]; then
			rm -r "$INSTALL_GFX_DIR"
		fi

		exit_with_error "Applying Vanilla DF graphics patches failed."
	fi
}

print_usage () {
	echo "Usage: df-lnp-installer.sh [OPTIONS]"
	echo ""
	echo "Options:"
	echo "--override-user-agent  # Download files as Mozilla user agent, not Wget user agent. Useful if you get 403 errors."
	echo "--skip-download        # Install using the existing contents of the ./downloads folder."
	echo "--skip-deps            # Install without checking for dependencies."
	echo "--skip-sha             # Install without checking file checksums."
	echo "--upgrade, -u          # Upgrade an existing DF installation."
	echo "--use-free-libs        # Force to use free graphic libs to solve \"Not found\" errors of DF."
	echo "--version, -v          # Print the df-lnp-installer version."
	echo "--help, --usage        # Print this message."
}

print_version () {
	echo "Dwarf Fortress LNP Linux Installer"
	echo "Version: $VERSION"
}

read_config_file_or_set_defaults () {
	# Source the variables from the config file into this script, if the conf file exists and is readable.
	#
	# Use "." instead of "source", as apparently "source" is a bashism.
	# You know, because using a period is so much clearer. Thanks, POSIX. <_<
	if [ -r "$INSTALLER_CONFIG_FILE" ]; then
		. "$INSTALLER_CONFIG_FILE"
	fi

	# Use defaults if we didn't get a variable from the config file.

	# If the install directory is undefined or the config file points to a
	# directory that no longer exists, use the default.
	if [ -z "$INSTALL_DIR" ] || [ ! -d "$INSTALL_DIR" ]; then
		INSTALL_DIR="$HOME/bin/Dwarf Fortress"
	fi

	if [ -z "$DOWNLOAD_DIR" ]; then
		DOWNLOAD_DIR="./downloads"
	fi

	if [ -z "$BACKUP_DIR" ]; then
		BACKUP_DIR="./df_backup"
	fi

	if [ -z "$DEST_DIR" ]; then
		DEST_DIR="./dest_dir"
	fi
}

# Should only be called as part of an $UPGRADE.
restore_save_files () {
	local DESTINATION="$INSTALL_DIR/df_linux/data"
	local FOLDER_NAME="$(basename $INSTALL_DIR)"

	local SOURCE="$BACKUP_DIR/$FOLDER_NAME/df_linux/data/save"

	# If it exists...
	# Copy the save files from the backup location to the install location.
	if [ -d "$SOURCE" ]; then
		cp -r "$SOURCE" "$DESTINATION"

		# Quit if restoring failed.
		if [ "$?" != "0" ]; then
			exit_with_error "Restoring saved games failed."
		fi
	else
		echo "No saved games found. Skipping save game restore."
	fi
}

restore_soundsense_packs () {
	local DESTINATION="$INSTALL_DIR/LNP/utilities/soundsense/"
	local FOLDER_NAME="$(basename $INSTALL_DIR)"

	local SOURCE="$BACKUP_DIR/$FOLDER_NAME/LNP/utilities/soundsense/packs"

	if [ -d "$SOURCE" ]; then
		# Copy the save files from the backup location to the install location.
		cp -r "$SOURCE" "$DESTINATION"

		# Quit if restoring failed.
		if [ "$?" != "0" ]; then
			exit_with_error "Restoring soundsense audio packs failed."
		fi
	else
		echo "No soundsense packs found. Skipping soundsense restore."
	fi
}

save_config_file () {
	# Bomb the existing config file, if any.
	if [ -e "$INSTALLER_CONFIG_FILE" ]; then
		rm "$INSTALLER_CONFIG_FILE"
	fi

	# Create folder structure.
	mkdir -p "$INSTALLER_CONFIG_DIR"

	# Create an empty config file.
	touch "$INSTALLER_CONFIG_FILE"

	# Append each var we want to save to the file.
	echo "INSTALL_DIR=\"$INSTALL_DIR\"" >> "$INSTALLER_CONFIG_FILE"
	echo "DOWNLOAD_DIR=\"$DOWNLOAD_DIR\"" >> "$INSTALLER_CONFIG_FILE"
	echo "BACKUP_DIR=\"$BACKUP_DIR\"" >> "$INSTALLER_CONFIG_FILE"
	echo "DEST_DIR=\"$DEST_DIR\"" >> "$INSTALLER_CONFIG_FILE"
}

##############
# "Main"
##############

# Globals.
VERSION="0.5.5"

# XDG_CONFIG_HOME is supposed to be defined as part of the freedesktop.org spec
# but not all distros support it. Define it as $HOME/.config/ if it doesn't already exist.
if [ -z "$XDG_CONFIG_HOME" ]; then
	XDG_CONFIG_HOME="$HOME/.config"
fi

INSTALLER_CONFIG_DIR="$XDG_CONFIG_HOME/df-lnp-installer"
INSTALLER_CONFIG_FILE="$INSTALLER_CONFIG_DIR/df_lnp_installer.conf"

read_config_file_or_set_defaults

# Globals that shouldn't be persisted in the config file but
# rather are dependant on script arguments.
OVERRIDE_USER_AGENT=0
SKIP_DOWNLOAD=0
SKIP_DEPS=0
SKIP_SHA=0
UPGRADE=0
USE_FREE_LIBS=0

# If the user passed in arguments, parse them, otherwise assume "do everything".
if [ -n "$1" ]; then
	while [ "$1" ]; do
		case "$1" in
			'--override-user-agent') OVERRIDE_USER_AGENT=1 ;;
			'--skip-download') SKIP_DOWNLOAD=1 ;;
			'--skip-deps') SKIP_DEPS=1 ;;
			'--skip-sha') SKIP_SHA=1 ;;
			'--upgrade'|'-u') UPGRADE=1 ;;
                        '--use-free-libs') USE_FREE_LIBS=1 ;;
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

check_libpng_version

ask_for_preferred_install_dir

# Check the preferred location for validity.
if [ "$UPGRADE" = "1" ]; then
	check_install_dir_contains_df_install
else
	check_install_dir_is_empty
fi

# Delete temporary destination directory if necessary.
if [ -d "$DEST_DIR" ]; then
	delete_dest_dir
fi

# Create our temporary destination directory.
create_dest_dir

# Make sure the download directory exists.
create_download_dir

# Download all the things!
if [ "$SKIP_DOWNLOAD" = "0" ]; then
	download_all
fi

# Checksum all the things!
if [ "$SKIP_SHA" = "0" ]; then
	checksum_all
fi

# Install everything to the $DEST_DIR.
install_all

# Apply all the bug fixes!
bugfix_all

#
# $DEST_DIR should now contain a working DF install.
#

# If we are upgrading, backup their df install.
if [ "$UPGRADE" = "1" ]; then
	backup_df_directory
fi

copy_dest_dir_to_install_dir
create_df_lnp_desktop_file


# If we upgraded, restore the save files (if any).
if [ "$UPGRADE" = "1" ]; then
	restore_save_files
	restore_soundsense_packs

	# We've now restored everything we need to.
	# We can delete the old install. Whew!
	delete_backup_dir
fi

# Check to see if ptrace is enabled, and complain if it is.
check_ptrace_protection

# Successful install! Clean up after ourselves.
delete_dest_dir
save_config_file

# Strike the earth!
echo ""
echo "Installation successful!"
echo "Run $INSTALL_DIR/startlnp to run the Lazy Newb Pack."

exit 0

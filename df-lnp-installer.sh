#!/bin/sh

# -nc is "no clobber" for not overwriting files we already have.
WGET_OPTIONS='-nc'

VERSION=0.0.1
echo 'Dwarf Fortress LNP Linux Installer'
echo 'Version:' $VERSION

# Everyone loves pseudocode!
#

# TODO
# If arg == version, output version.
# Check for df-lnp-installer requirements like wget and sha1sum.
# Check for DF OS requirements.

# Download official DF.
DF_FOR_LINUX="http://www.bay12games.com/dwarves/df_34_11_linux.tar.bz2"
wget $WGET_OPTIONS $DF_FOR_LINUX

# Download latest DFHack with soundsense.
DFHACK="http://github.com/peterix/dfhack/archive/0.34.11-r3.tar.gz"
wget $WGET_OPTIONS $DFHACK

# Download latest LNP GUI.
LNP_LINUX_SNAPSHOT="http://drone.io/bitbucket.org/Dricus/lazy-newbpack/files/target/lazy-newbpack-linux-0.5.3-SNAPSHOT-20130822-1652.tar.bz2"
wget $WGET_OPTIONS $LNP_LINUX_SNAPSHOT

# TODO
# Download each graphics pack.

# Check for file validity.
sha1sum -c sha1sums

# TODO
# Unzip DF.
# Unzip DF_Hack on top of df_linux/
# Unzip DF Hack plugins to df_linux/hack/plugins/
# Unzip LNP.
# Drop graphics packs into LNP/Graphics/
# Drop custom lnp.yaml into LNP/.


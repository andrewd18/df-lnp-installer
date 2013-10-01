Overview
========

df-lnp-installer is a shell script that installs the Dwarf Fortress Lazy Newb Pack. It downloads and builds a DF installation from available source code and binaries.

Included Mods
-------------

* Lazy Newb Pack for Linux 0.5.3-SNAPSHOT-20130822
* DF Hack 0.34.11-r3
* Falconne's DFHack UI Plugins v0.36
* SoundSense r42 (app only)
* Dwarf Therapist (splintermind, pulled and built from source)
* Tilesets
  - [12x12] Jolly Bastion 34.10v5
  - [16x16] ASCII Default 0.34.11
  - [16x16] CLA v15
  - [16x16] Ironhand 0.73.4
  - [16x16] Mayday 0.34.11
  - [16x16] Obsidian 0.8a
  - [16x16] Phoebus 34.11v01
  - [16x16] Spacefox 34.11v1.0


System Requirements
===================

* A Java runtime environment for the LNP GUI.
* SDL 1.2, 32-bit
* LibGLU 1, 32-bit
* LibGTK 2.0, 32-bit
* OpenAL 1.2, 32-bit
* LibJPEG 6.2, 32-bit
* Git
* Mercurial (hg)
* Qt4 Development Libraries including qmake
* The following fairly standard Linux utilities:
  - wget
  - sha1sum
  - sed
  - tar
  - unzip
  - unrar
  - make
  - g++
  - gcc
  - xterm

The df-lnp-installer script will automatically check your system for the required libraries.

The Debian (and possibly Ubuntu) command to install these dependencies is: 
```
sudo apt-get install default-jre libsdl1.2debian:i386 libsdl-image1.2:i386 libsdl-ttf2.0-0:i386 libglu1-mesa:i386 libgtk2.0-0:i386 libopenal1:i386 libjpeg62:i386 git mercurial libqt4-dev qt4-qmake wget coreutils tar unzip unrar make g++ gcc patch xterm sed
```

Usage
=====

```
Usage: df-lnp-installer.sh [OPTIONS]

Options:
--skip-download  # Install using the existing contents of the ./downloads folder.
--skip-deps      # Install without checking for dependencies.
--skip-sha       # Install without checking file checksums.
--upgrade, -u    # Upgrade an existing DF installation.
--version, -v    # Print the df-lnp-installer version.
--help, --usage  # Print this message.
```

Full Installation
=================

1. Clone the git repository with `git clone https://github.com/andrewd18/df-lnp-installer.git`
2. Run `./df-lnp-installer.sh` and follow the prompts.
3. Once DF is installed, enter the DF folder and run ./startlnp.
4. Start the SoundSense r42 utility from the Utilities tab.
5. Click the "Pack Update" tab.
6. Click "Start Automatic Update".
7. Get a Dwarven Ale; it's going to be a while.
8. Once finished, close SoundSense, and muck about with LNP as normal.

Upgrading an Existing Installation
==================================

1. Update your git repository with `git pull`
2. Run `./df-lnp-installer.sh --upgrade`. When asked, enter the directory you already installed DF into.
3. Your save files and soundsense audio packs will be saved. If something goes wrong, the whole install will be reverted.

Common Issues
=============
See [the WIKI](https://github.com/andrewd18/df-lnp-installer/wiki).

Tested On
=========

* Debian 7 "Wheezy", stable, using Dash (default) shell.
* Debian 7 "Jessie/Sid", testing, using Dash (default) shell.

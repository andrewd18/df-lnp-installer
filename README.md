Overview
========

Included Mods
-------------

* Lazy Newb Pack for Linux 0.5.3-SNAPSHOT-20130822
* DF Hack 0.34.11-r3
* Falconne's DFHack UI Plugins v0.35
* SoundSense r42
* Tilesets
  - [08x12] ASCII Default 0.34.11
  - [16x16] CLA v15
  - [16x16] Mayday 0.34.11
  - [16x20] Shizzle 1.3
  - [12x12] Jolly Bastion 34.10v5
  - [16x16] Ironhand 0.73.3
  - [16x16] Phoebus 34.11v01


Feature Status
==============

Stuff that works:
-----------------

 * The Lazy Newb Pack UI runs.
 * You can change tilesets.
 * You can update savegames with new tilesets.
 * DF Hack
 * SoundSense plays audio.

Stuff that didn't work for me but might work for you:
-----------------------------------------------------

 * The LNP UI doesn't want to open the Utilities, Graphics, etc. folders.
 * Dwarf Fortress keeps complaining about missing 32-bit OpenAL libraries though I have them installed.
 * SoundSense doesn't allow me to change or mute its sound level.


System Requirements
===================

* A Java runtime environment for the LNP GUI.


Full Installation
=================

1. Run ./df-lnp-installer.sh and follow the prompts.
2. Once DF is installed, enter the DF folder and run ./startlnp.
3. Start the SoundSense r42 utility from the Utilities tab.
4. Point SoundSense at the df_linux/gamelog.txt file.
5. Click the "Pack Update" tab.
6. Click "Start Automatic Update".
7. Get a Dwarven Ale; it's going to be a while.
8. Once finished, close SoundSense, and muck about with LNP as normal.

Tested On
=========

* Debian 7 "Wheezy", stable, using Dash (default) shell.
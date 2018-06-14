# arch-on-hetzner
script that installs arch linux on hetzner server

Gennerally it also should work on other servers with similar setup.

As for hetzner ender rescue (64bit) mode with given password and restart server. 

After that download script to /tmp with

wget -P /tmp https://raw.githubusercontent.com/tendermonster/arch-on-hetzner/master/install.sh

and start with with bash install.sh 

(SCRIPE NEED TO BE EXEDUTEN WITH BASH, because sh is a syslink to dash whitch this script is not compatible)

DO NOT RUN THIS SCRIPT WITHOUT READING IT! It might need some adjustements

TODO: It seems that after running chroot it created another shell so fallowing commands cannot execute. Need to find a workaround for this

# arch-on-hetzner

script that installs arch linux on hetzner server

tested on debian 8.10 (rescue) and arch linux (4.16.13-2)

My setup:
* efi, gtp, raid1

Gennerally it also should work on other servers with similar setup.

How to:

Before running this script adjust it to your needs.

1) Enter linux rescue (64bit) mode and restart server. 

2) Login via shh to your server with given password

3) Download script to /tmp

* wget -P /tmp https://raw.githubusercontent.com/tendermonster/arch-on-hetzner/master/install.sh

4) Do bash /tmp/install.sh 

If you have any suggestions or ideas on how to improve this script let me know :)

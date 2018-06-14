#!/bin/bash

#inseption #2
arch-chroot /mnt

#hostname
touch /etc/hostname
hostnamectl set-hostname $HOSTNAME

#timezone
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#set locale
sed -i '/^#de_DE\|^#en_US/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.utf8" > /etc/locale.conf

# Keyboard if needed
# echo "KEYMAP=de-latin1" > /etc/vconsole.conf

# install mdadm and config write RAID config file
pacman -S --noconfirm mdadm
mdadm --detail --scan >> /etc/mdadm.conf

# Add mdadm_udev hook
sed -i '/^HOOK/s/\(filesystems\)/mdadm_udev \1/' mkinitcpio.conf
mkinitcpio -p linux

#GRUB2
pacman -S --noconfirm grub

#set root to (/boot)
echo -e 'insmod mdraid\nset root=(md1)' >> /etc/grub.d/40_custom

#install grub and generate config
grub-install --target=i386-pc --recheck --debug /dev/sda && grub-install --target=i386-pc --recheck --debug /dev/sdb 
grub-mkconfig -o /boot/grub/grub.cfg

#enable dhcp (check if dhcp service exist and what is the name of it)
#by the time of writing this can change so make sure to check if overall everything is consistant
#check service with systemctl list-unit-files
systemctl enable dhcpcd.service

#load your network card module on boot just in case
#be aware that yours can be different!
echo 'e1000e' > /etc/modules-load.d/intel.conf

#install ssh
pacman -S --noconfirm openssh
systemctl enable sshd

#from this point on you need to setup some users to login via ssh. 
#be aware that you cannot login with root via ssh as it is disabled by default
#also change root password to something
passwd
useradd -m -g users -G wheel -s /bin/bash tendermonster
passwd tendermonster

exit

#Congrats you just installed arch linux on hetzner's server
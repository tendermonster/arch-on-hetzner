#!/bin/bash

#inception

#setup pacman-key
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

#mount partitions
mount /dev/md2 /mnt
mkdir /mnt/{boot,home,var}
mount /dev/md1 /mnt/boot		
mount /dev/md3 /mnt/var
mount /dev/md5 /mnt/home

#have no idea why u need to do this.. debian specific 
mkdir /run/shm

#populate /mnt with base system
pacstrap /mnt base

#generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#inseption #2
arch-chroot /mnt /bin/bash -c "wget -P /tmp https://raw.githubusercontent.com/tendermonster/arch-on-hetzner/master/inception_two.sh; bash /tmp/inception_two.sh"

exit
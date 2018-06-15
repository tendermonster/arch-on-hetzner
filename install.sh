#!/bin/bash
#This is a script i used to successfully install arch linux on an server from hetzner

#umount
umount /dev/md*

#stop raid devices
mdadm --stop /dev/md*

#zero superblocks
#this will delete all data on both hdd's 
mdadm --zero-superblock /dev/sd*

#get number of partitions
partnum=$(sgdisk -p /dev/sda | awk 'END{print $1}')

#delete all partitions
if [ "partnum" != "Number" ]; then
	for ((i=1; i<=$partnum; i++));
	do
	sgdisk -d $i /dev/sda
	done
fi

#setup partitions as u like. 
#in this example i will use my setup but you are welcome to use other partitioning scheme
# depends what you are using. I you have bios mode and gtp sectored hdd's like i am you'll need bios partition
sgdisk -n 1:$(sgdisk -F /dev/sda):+2M /dev/sda 
#this will be bios partition later
#if you dont need bios partition just comment it out and start with /boot partiton
sgdisk -n 2:$(sgdisk -f /dev/sda):+550M /dev/sda	#/boot
sgdisk -n 3:$(sgdisk -f /dev/sda):+30G /dev/sda		#/
sgdisk -n 4:$(sgdisk -f /dev/sda):+10G /dev/sda		#/var
sgdisk -n 5:$(sgdisk -f /dev/sda):+2G /dev/sda		#swap
sgdisk -n 6:$(sgdisk -f /dev/sda):+15G /dev/sda		#/home
sgdisk -n 7:$(sgdisk -f /dev/sda) /dev/sda			#LVM Partition

#set partiton type
#you can check partiton types with sgdisk -L
sgdisk -t 1:ef02 /dev/sda	#BIOS boot partition
sgdisk -t 2:ef00 /dev/sda	#EFI System
sgdisk -t 3:8300 /dev/sda	#linux filesystem
sgdisk -t 4:8300 /dev/sda	#linux filesystem
sgdisk -t 5:8200 /dev/sda	#linux swap
sgdisk -t 6:8300 /dev/sda	#linux filesystem
sgdisk -t 7:8e00 /dev/sda	#Linux LVM

# copy partition table to /dev/sdb
sgdisk --backup=table /dev/sda
sgdisk --load-backup=table /dev/sdb

#RAID 1 setup
yes | mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]1
yes | mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sd[ab]2
yes | mdadm --create /dev/md2 --level=1 --raid-devices=2 /dev/sd[ab]3
yes | mdadm --create /dev/md3 --level=1 --raid-devices=2 /dev/sd[ab]4
yes | mdadm --create /dev/md4 --level=1 --raid-devices=2 /dev/sd[ab]5
yes | mdadm --create /dev/md5 --level=1 --raid-devices=2 /dev/sd[ab]6
yes | mdadm --create /dev/md6 --level=1 --raid-devices=2 /dev/sd[ab]7

#add current raid config to mdadm.conf
mdadm --detail --scan >> /etc/mdadm.conf

#format partitions
yes | mkfs.ext2 /dev/md0
yes | mkfs.ext2 /dev/md1
yes | mkfs.ext4 /dev/md2
yes | mkfs.ext4 /dev/md3
yes | mkfs.ext4 /dev/md4
yes | mkfs.ext4 /dev/md5
yes | mkfs.ext4 /dev/md6

# INSTALLING BASE SYSTEM

#download and unpack bootstrap
mount /dev/md6 /mnt
wget -P /mnt http://ftp.uni-bayreuth.de/linux/archlinux/iso/2018.06.01/archlinux-bootstrap-2018.06.01-x86_64.tar.gz 
echo "extracting archlinux-bootstrap"
tar xzf /mnt/archlinux-bootstrap-2018.06.01-x86_64.tar.gz -C /mnt

#http://ftp.uni-bayreuth.de/linux/archlinux/iso/2018.06.01/archlinux-bootstrap-2018.06.01-x86_64.tar.gz.sig

#entropy for pacman-key
apt-get install haveged
haveged -w 1024

#setup an mirror. You can adopt this like as your needs please 
sed -i '/ftp.uni-bayreuth.de/s/^#//' /mnt/root.x86_64/etc/pacman.d/mirrorlist

#inseption
/mnt/root.x86_64/bin/arch-chroot /mnt/root.x86_64 /bin/bash -c "curl -o /tmp/inception.sh https://raw.githubusercontent.com/tendermonster/arch-on-hetzner/master/inception.sh; bash /tmp/inception.sh"

#exit
#exit
#reboot
#umount 









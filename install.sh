#This is a script i used to successfully install arch linux on an server from hetzner

#!/bin/bash -x

#Change this to hostname you like otherwise default will be used
HOSTNAME=$HOSTNAME #<-- here

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

for ((i=1; i<=$partnum; i++));
do
	sgdisk -d $partition /dev/sda
done

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

mdadm --create /dev/md0 --level=1 --raid-devices=2 -f /dev/sd[ab]1
mdadm --create /dev/md1 --level=1 --raid-devices=2 -f /dev/sd[ab]2
mdadm --create /dev/md2 --level=1 --raid-devices=2 -f /dev/sd[ab]3
mdadm --create /dev/md3 --level=1 --raid-devices=2 -f /dev/sd[ab]4
mdadm --create /dev/md4 --level=1 --raid-devices=2 -f /dev/sd[ab]5
mdadm --create /dev/md5 --level=1 --raid-devices=2 -f /dev/sd[ab]6
mdadm --create /dev/md6 --level=1 --raid-devices=2 -f /dev/sd[ab]7

#add current raid config to mdadm.conf

mdadm --details --scan >> /etc/mdadm.conf

#format partitions

mkfs.ext2 /dev/md0
mkfs.ext2 /dev/md1
mkfs.ext4 /dev/md2
mkfs.ext4 /dev/md3
mkfs.ext4 /dev/md4
mkfs.ext4 /dev/md5
mkfs.ext4 /dev/md6

# INSTALLING BASE SYSTEM

#download and unpack bootstrap
mount /dev/md6 /mnt
wget -P /mnt http://ftp.uni-bayreuth.de/linux/archlinux/iso/2018.06.01/archlinux-bootstrap-2018.06.01-x86_64.tar.gz 
tar xzvf /mnt/archlinux-bootstrap-2018.06.01-x86_64.tar.gz -C /mnt

#entropy for pacman-key
apt-get install haveged
haveged -w 1024

#setup an mirror. You can adopt this like as your needs please 

sed -i '/ftp.uni-bayreuth.de/s/^#//' /mnt/root.x86_64/etc/pacman.d/mirrorlist

#inseption

/mnt/root.x86_64/bin/arch-chroot /mnt/root.x86_64

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
#passwd
# useradd -m -g users -G wheel -s /bin/bash username
# passwd username

#Congrats you just installed arch linux on hetzner's server

#exit
#exit
#reboot
#umount 









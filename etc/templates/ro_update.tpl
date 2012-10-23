#!/bin/bash
################################################################################
# get the bundle
################################################################################
export http_proxy=http://10.100.0.6:3128
BUNDLE_HASH='~BHASH~'
MODULE_HASH='~MHASH~'
wget --no-check-certificate -O /tmp/kernel-bundle-~KERNEL~-net5501.tgz https://stash.eftdomain.net/~DATETIME~/kernel_bundles/kernel-bundle-~KERNEL~-net5501.tgz

EXIT=1;
################################################################################
# install the files into /boot
################################################################################
if [ "$(sha1sum /tmp/kernel-bundle-~KERNEL~-net5501.tgz | awk '{print $1}')" == "${BUNDLE_HASH}" ]; then 
    mount | grep "/dev/sda1 on /boot" || mount /dev/sda1 /boot
    mount | grep "/dev/sda1 on /boot"
    if [ $? -eq 0 ]; then
        (
          cd /boot; 
          tar xvzf /tmp/kernel-bundle-~KERNEL~-net5501.tgz vmlinuz-~KERNEL~-net5501 && \
          tar xvzf /tmp/kernel-bundle-~KERNEL~-net5501.tgz initrd.img-~KERNEL~-net5501 && \
          tar xvzf /tmp/kernel-bundle-~KERNEL~-net5501.tgz System.map-~KERNEL~-net5501 && \
          tar xvzf /tmp/kernel-bundle-~KERNEL~-net5501.tgz config-~KERNEL~-net5501
        )
        EXIT=$?
    fi
fi
if [ ! ${EXIT} -eq 0 ]; then exit 1; fi

################################################################################
# install lib/modules/
################################################################################
mount -o remount,rw /ro
cd /ro/lib/modules; tar xvzf /tmp/kernel-bundle-~KERNEL~-net5501.tgz modules-~KERNEL~-net5501
if [ "$(sha1sum modules-~KERNEL~-net5501| awk '{print $1}')" == "${MODULE_HASH}" ]; then
    (cd /ro/lib/modules; tar xvzf modules-~KERNEL~-net5501)
    EXIT=$?
fi
mount -o remount,ro /ro
if [ ! ${EXIT} -eq 0 ]; then exit 1; fi

################################################################################
# install grub.cfg only if everything else exited 0
################################################################################
cat<<EOF > /boot/grub/grub.cfg
# 19200 8n1
#serial --unit=0 --speed=19200 --word=8 --parity=no --stop=1
set timeout=0
set default=0
menuentry "soekris ro-root on cryptoloop ~KERNEL~ aufs" {
        set root=(hd0,1)
        linux /vmlinuz-~KERNEL~-net5501 root=/dev/mapper/crypt_dev_sda2 ro console=ttyS0,19200n8
        initrd /initrd.img-~KERNEL~-net5501
}
menuentry "soekris ro-root on cryptoloop" {
        set root=(hd0,1)
        linux /vmlinuz-2.6.32-net5501 root=/dev/mapper/crypt_dev_sda2 ro console=ttyS0,19200n8
        initrd /initrd.img-2.6.32-net5501
}
EOF

################################################################################
# clean up
################################################################################
mount | grep "/dev/sda1 on /boot" && umount /boot
rm /tmp/kernel-bundle-~KERNEL~-net5501.tgz

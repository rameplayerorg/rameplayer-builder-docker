# Alpine ARM build
#
# You probably need QEMU for running this.
# In Ubuntu: sudo apt install qemu-user-static
#
# Run this container with -v /usr/bin/qemu-arm-static:/usr/bin/qemu-arm-static

FROM rameplayerorg/armbuild-alpine
MAINTAINER Tuomas Jaakola <tuomas.jaakola@iki.fi>

# dtc is compiled according to this script:
# https://raw.githubusercontent.com/RobertCNelson/tools/master/pkgs/dtc.sh
ADD dtc /usr/local/bin/

# Provide modified repositories list
ADD repositories /etc/apk/

# Provide qemu-arm-static so we can use it in RUN instructions
# Binary is from Ubuntu 16.10 package 'qemu-user-static'
ADD qemu-arm-static /usr/bin/

# Create builder user rame without password
RUN ["/usr/bin/qemu-arm-static", "/usr/sbin/adduser", "rame", "-D"]

# Install required alpine packages
RUN ["/usr/bin/qemu-arm-static", "/sbin/apk", "--update", "add", \
    "alpine-sdk", \
    "cmake", \
    "fakeroot", \
    "fbida-fbi", \
    "git", \
    "imagemagick", \
    "kmod", \
    "linux-headers"]

# Add user to abuild group
RUN ["/usr/bin/qemu-arm-static", "/usr/sbin/addgroup", "rame", "abuild"]

# Fix buggy mess in /etc/passwd
RUN ["/usr/bin/qemu-arm-static", "/bin/sed", "-i", "-e", "s/:in\\/nologin/:\\/bin\\/ash/g", "/etc/passwd"]

# Grant user sudo rights
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "echo 'rame ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"]

# Generate alpine build keys for rame user
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'abuild-keygen -a -i'"]

# Clone building repo
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'cd && git clone https://github.com/rameplayerorg/rameplayer-alpine.git'"]

# Create symbolic link for build.sh
RUN ["/usr/bin/qemu-arm-static", "/bin/ln", "-s", "/home/rame/rameplayer-alpine/rame.modules", "/etc/mkinitfs/features.d/"]

# Change builder key to rameplayer-keys package
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "rm /home/rame/rameplayer-alpine/ramepkg/rameplayer-keys/*.pub"]
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'cp ~/.abuild/rame-*.rsa.pub ~/rameplayer-alpine/ramepkg/rameplayer-keys/'"]

# Replace generated key file in source line in APKBUILD
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'cd ~/rameplayer-alpine/ramepkg/rameplayer-keys/ ; KEYFILE=`ls rame-*pub` ; sed -i -e s/source=\\.\\*/source=\\\"$KEYFILE\\\"/g APKBUILD'"]

# Refresh checksums in APKBUILD file
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'cd ~/rameplayer-alpine/ramepkg/rameplayer-keys ; abuild -F checksum'"]

# Build rameplayer-keys package
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'cd ~/rameplayer-alpine/ramepkg/rameplayer-keys ; abuild'"]

# Install rameplayer-keys package
RUN ["/usr/bin/qemu-arm-static", "/sbin/apk", "--update", "add", "rameplayer-keys"]

CMD ["/bin/sh"]

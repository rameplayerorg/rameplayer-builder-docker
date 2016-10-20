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

# Clone building repo
RUN ["/usr/bin/qemu-arm-static", "/bin/sh", "-c", "su rame - -c 'cd && git clone https://github.com/rameplayerorg/rameplayer-alpine.git'"]

# Create symbolic link for build.sh
RUN ["/usr/bin/qemu-arm-static", "/bin/ln", "-s", "/home/rame/rameplayer-alpine/rame.modules", "/etc/mkinitfs/features.d/"]

# Environment variables to be used in docker-entrypoint.sh
ENV BUILD_USER rame
ENV KEYS_DIR /home/${BUILD_USER}/.abuild
ENV BUILD_REPO_DIR /home/${BUILD_USER}/rameplayer-alpine
ENV IMAGE_DIR /rame

# Mount points, image will be written to /image, .abuild contains packager keys
VOLUME ["/image", "/home/rame/.abuild"]

# Entrypoint script as guided in
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/entrypoint
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

# open shell by default if no arguments given
CMD ["/bin/ash"]

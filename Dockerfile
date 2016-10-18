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

CMD ["/bin/sh"]

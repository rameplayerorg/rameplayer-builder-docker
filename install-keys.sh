#!/bin/sh

# Installs Alpine packager keys

set -e

# check if alpine packager keys are available
KEYS=`find $KEYS_DIR -name "*.rsa.pub" | wc -l`
if [ $KEYS -gt "1" ]; then
	echo "ERROR: Too many keys found from $KEYS_DIR: $KEYS"
	exit 1
fi
if [ $KEYS == "0" ]; then
	# generate new keys
	chown $BUILD_USER:$BUILD_USER $KEYS_DIR
	echo "Generating new packager keys..."
	su rame - -c "abuild-keygen -a"
fi

echo "Setting permissions for image and packages directory..."
chown $BUILD_USER:$BUILD_USER $IMAGE_DIR
chown $BUILD_USER:$BUILD_USER /home/rame/packages

# install public key
echo "Installing keys to /etc/apk/keys..."
cp $KEYS_DIR/*.rsa.pub /etc/apk/keys

# Run commands as rame user
exec su $BUILD_USER << 'EOF'
	cd $BUILD_REPO_DIR

	echo "Inserting keys to rameplayer-keys package and installing it..."

	# change builder key to rameplayer-keys package
	rm ramepkg/rameplayer-keys/*.pub
	cp ~/.abuild/rame-*.rsa.pub ramepkg/rameplayer-keys

	# edit APKBUILD file: replace generated key file in source line
	cd ramepkg/rameplayer-keys
       	KEYFILE=`ls rame-*pub` ; sed -i -e s/source=\.\*/source=\"$KEYFILE\"/g APKBUILD

	# refresh checksums in APKBUILD file
	abuild -F checksum

	# build rameplayer-keys package
	abuild

	# install rameplayer-keys package
	sudo apk --update add rameplayer-keys
EOF

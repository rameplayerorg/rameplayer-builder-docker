#!/bin/sh

# Gets environment variables from Docker image, see Dockerfile

# Docker entrypoint script as guided in
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/entrypoint

set -e

if [ "$1" = 'build' ]; then
	# check if alpine packager keys are available
	KEYS=`find $KEYS_DIR -name "*.rsa.pub" | wc -l`
	if [ $KEYS -gt "1" ]; then
		echo "ERROR: Too many keys found from $KEYS_DIR: $KEYS"
		exit 1
	fi
	if [ $KEYS == "0" ]; then
		# generate new keys
		chown rame:rame $KEYS_DIR
		echo "Generating new packager keys..."
		su rame - -c "abuild-keygen -a"
	fi

	# install public key
	echo "Installing keys to /etc/apk/keys..."
	cp $KEYS_DIR/*.rsa.pub /etc/apk/keys

	exec su rame << 'EOF'
	# pull newest version from build repo
	cd $BUILD_REPO_DIR
	echo "Updating rameplayer-alpine from GitHub..."
	git pull

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

	echo "Building..."
	cd $BUILD_REPO_DIR
	./build.sh $IMAGE_DIR
EOF

elif [ "$1" = 'keygen' ]; then
	# generate new keys
	chown rame:rame $KEYS_DIR
	exec su rame - -c "abuild-keygen -a"
fi

# just exec anything user gave as argument
exec "$@"

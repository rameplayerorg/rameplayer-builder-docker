#!/bin/sh

# Gets environment variables from Docker image, see Dockerfile

# Docker entrypoint script as guided in
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/entrypoint

set -e

if [ "$1" = 'build' ]; then
	# install Alpine packager keys
	/install-keys.sh

	exec su $BUILD_USER << 'EOF'
	echo "Building..."
	cd $BUILD_REPO_DIR
	./build.sh $IMAGE_DIR
EOF

elif [ "$1" = 'keygen' ]; then
	# generate new keys
	chown $BUILD_USER:$BUILD_USER $KEYS_DIR
	exec su $BUILD_USER - -c "abuild-keygen -a"
fi

# just exec anything user gave as argument
echo "Quick tip:"
echo "# /install-keys.sh"
echo "# su rame"
echo "# cd ~/rameplayer-alpine/"
echo ""
echo "See examples: https://hub.docker.com/r/rameplayerorg/rameplayer-builder/"
exec "$@"

#!/bin/bash

set -e
# Exit on fail

echo "bundle path = $BUNDLE_PATH"
bundle check || bundle install --binstubs="$BUNDLE_BIN"
# Ensure all gems installed. Add binstubs to bin which has been added to PATH in Dockerfile.

echo 'entrypoint'
# Finally call command issued to the docker service
exec "$@"


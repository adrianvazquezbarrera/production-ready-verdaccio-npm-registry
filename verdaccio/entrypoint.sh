#!/bin/sh
set -e
echo "Starting Verdaccio..."
exec node node_modules/verdaccio/bin/verdaccio -c /verdaccio/conf/config.yaml
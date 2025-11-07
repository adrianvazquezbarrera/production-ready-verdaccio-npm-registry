#!/bin/sh
set -e

HTPASSWD_FILE=/verdaccio/conf/htpasswd
rm -f "$HTPASSWD_FILE"

if [ -z "$VERDACCIO_USERS" ]; then
  echo "No VERDACCIO_USERS provided. Using default admin:secret"
  VERDACCIO_USERS="admin:secret"
fi

# Split by comma into a list
for USERPASS in $(echo "$VERDACCIO_USERS" | tr ',' ' '); do
  USER=$(echo "$USERPASS" | cut -d':' -f1)
  PASS=$(echo "$USERPASS" | cut -d':' -f2)

  if [ ! -f "$HTPASSWD_FILE" ]; then
    echo "Creating htpasswd file with user $USER"
    echo "$PASS" | npx --yes htpasswd -cB "$HTPASSWD_FILE" "$USER"
  else
    echo "Adding user $USER"
    echo "$PASS" | npx --yes htpasswd -B "$HTPASSWD_FILE" "$USER"
  fi
done

echo "Starting Verdaccio..."
exec node node_modules/verdaccio/bin/verdaccio -c /verdaccio/conf/config.yaml
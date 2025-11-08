#!/bin/bash

# CI/CD Login Script for Verdaccio
# Usage: NPM_USER=bob NPM_PASS=password NPM_EMAIL=bob@example.com ./ci-login.sh

NPM_USER="${NPM_USER:-bob}"
NPM_PASS="${NPM_PASS:-password2}"
NPM_EMAIL="${NPM_EMAIL:-bob@example.com}"
NPM_REGISTRY_URL="${NPM_REGISTRY_URL:-http://localhost:4873}"
NPM_REGISTRY="${NPM_REGISTRY:-localhost:4873}"

# Create base64 encoded credentials (use -w 0 on Linux, no flag needed on macOS for single line)
AUTH=$(echo -n "$NPM_USER:$NPM_PASS" | base64 | tr -d '\n')

# Write to .npmrc
cat > .npmrc << EOF
registry=$NPM_REGISTRY_URL
//$NPM_REGISTRY/:_auth=$AUTH
//$NPM_REGISTRY/:email=$NPM_EMAIL
EOF

echo "✓ Authentication configured for $NPM_REGISTRY"

# Check for conflicting global .npmrc
if [ -f ~/.npmrc ]; then
  echo "⚠ Warning: Global ~/.npmrc found. This may interfere with authentication."
  echo "  Consider backing it up: mv ~/.npmrc ~/.npmrc.backup"
fi

# Warn user that in order to reach the registry, they may run this command
# at least once: npm adduser --registry=$NPM_REGISTRY_URL
echo "⚠ Note: To ensure connectivity, you may need to run:"
echo "  npm adduser --registry=$NPM_REGISTRY_URL"
echo "  to ensure your client can reach the registry."

npm ping || { echo "✗ Unable to reach registry at $NPM_REGISTRY"; exit 1; }
echo "✓ Registry is reachable"


# Uncomment the following lines to test package installation
# npm install echo-cli || { echo "✗ npm install failed"; exit 1; }
# echo "✓ npm install succeeded"


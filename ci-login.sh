#!/bin/bash

# CI/CD Login Script for Verdaccio
# Usage: NPM_USER=bob NPM_PASS=password NPM_EMAIL=bob@example.com ./ci-login.sh

NPM_USER="${NPM_USER:-bob}"
NPM_PASS="${NPM_PASS:-password2}"
NPM_EMAIL="${NPM_EMAIL:-bob@example.com}"
NPM_REGISTRY="${NPM_REGISTRY:-http://localhost:4873}"

# Create base64 encoded credentials
AUTH=$(echo -n "$NPM_USER:$NPM_PASS" | base64)

# Write to .npmrc
cat > .npmrc << EOF
registry=$NPM_REGISTRY
//localhost:4873/:_auth=$AUTH
//localhost:4873/:email=$NPM_EMAIL
EOF

echo "✓ Authentication configured for $NPM_REGISTRY"

npm ping || { echo "✗ Unable to reach registry at $NPM_REGISTRY"; exit 1; }
echo "✓ Registry is reachable"


# For CI/CD pipelines (GitHub Actions example):

# - name: Authenticate to Verdaccio
#   run: |
#     AUTH=$(echo -n "${{ secrets.NPM_USER }}:${{ secrets.NPM_PASS }}" | base64)
#     cat > ~/.npmrc << EOF
#     registry=http://localhost:4873
#     //localhost:4873/:_auth=$AUTH
#     //localhost:4873/:email=ci@example.com
#     EOF
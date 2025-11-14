#!/bin/bash

NPM_USER="${NPM_USER:? Environment variable NPM_USER is required }"
NPM_PASS="${NPM_PASS:? Environment variable NPM_PASS is required }"
NPM_REGISTRY_URL="${NPM_REGISTRY_URL:-http://localhost/}"
NPM_REGISTRY="${NPM_REGISTRY:-localhost}"

echo "→ Using user: $NPM_USER"
echo "→ Testing package publish to NPM registry at $NPM_REGISTRY_URL"

AUTH=$(echo -n "$NPM_USER:$NPM_PASS" | base64)
CURRENT_DIR=$(pwd)

# Clean any previous temporary directory
rm -rf ./tmp
rm -rf ./verdaccio/verdaccio-storage/@test*

# Create temporary directory for test package
mkdir -p ./tmp/test-npm-package

(
cd ./tmp/test-npm-package || exit 1

# Create a simple package.json
cat > package.json << 'EOF'
{
  "name": "@test/my-test-package",
  "version": "1.0.0",
  "description": "Test package for authentication",
  "main": "index.js",
  "author": "Test User"
}
EOF

# Create a simple index.js file
echo "module.exports = 'Hello from test package';" > index.js


# Attempt to publish WITHOUT credentials (should FAIL with 401)
npm publish --registry $NPM_REGISTRY_URL && { echo "✗ Publish succeeded without credentials, which is unexpected."; exit 1; } || echo "✓ Publish failed without credentials as expected."

# Create .npmrc file with credentials
cat > .npmrc << EOF
registry=$NPM_REGISTRY_URL
//$NPM_REGISTRY/:_auth=$AUTH
EOF

# Attempt to publish WITH credentials (should SUCCEED)
npm publish --registry http://localhost || { echo "✗ Publish failed with credentials, which is unexpected."; exit 1; }

# Verify that the package was published
npm view @test/my-test-package --registry ${NPM_REGISTRY_URL} || { echo "✗ Published package not found."; exit 1; }
)

# Try to install the published package in another temporary directory
mkdir -p ./tmp/test-npm-project

(
cd ./tmp/test-npm-project || exit 1
# Create .npmrc file with credentials
cat > .npmrc << EOF
registry=$NPM_REGISTRY_URL
//$NPM_REGISTRY/:_auth=$AUTH
EOF

# Attempt to install the published package
npm install --save @test/my-test-package --registry ${NPM_REGISTRY_URL} || { echo "✗ Installation of published package failed."; exit 1; }

# Verify that the package was installed correctly
node -e "const pkg = require('./node_modules/@test/my-test-package'); console.log(pkg);"
)

echo "✓ All tests passed successfully."

# Clean up
cd "$CURRENT_DIR" && rm -rf ./tmp
rm -rf ./verdaccio/verdaccio-storage/@test*
exit 0
#!/bin/bash

# Script to download and prepare BoringSSL-GRPC for CocoaPods

BORING_SSL_DIR="$HOME/.cocoapods/repos/boringssl"
BORING_SSL_REPO="https://github.com/google/boringssl.git"

echo "Setting up BoringSSL-GRPC dependency..."

# Check if we already have the repo
if [ ! -d "$BORING_SSL_DIR" ]; then
  echo "Cloning BoringSSL repository with depth=1 to reduce size..."
  git clone --depth=1 "$BORING_SSL_REPO" "$BORING_SSL_DIR"
  if [ $? -ne 0 ]; then
    echo "Failed to clone BoringSSL repository. Trying with a smaller depth..."
    git clone --depth=1 --single-branch --branch=master "$BORING_SSL_REPO" "$BORING_SSL_DIR"
  fi
else
  echo "BoringSSL repository already exists at $BORING_SSL_DIR"
fi

# Create a podspec file for BoringSSL-GRPC
PODSPEC_FILE="$HOME/.cocoapods/repos/boringssl-grpc.podspec.json"
COMMIT=$(cd "$BORING_SSL_DIR" && git rev-parse HEAD)

echo "Creating podspec file for BoringSSL-GRPC..."
cat > "$PODSPEC_FILE" << EOF
{
  "name": "BoringSSL-GRPC",
  "version": "0.0.36",
  "summary": "BoringSSL is a fork of OpenSSL that is designed to meet Google's needs.",
  "description": "BoringSSL is a fork of OpenSSL that is designed to meet Google's needs.",
  "homepage": "https://github.com/google/boringssl",
  "license": {
    "type": "Mixed",
    "file": "LICENSE"
  },
  "authors": "Google",
  "source": {
    "git": "file://$BORING_SSL_DIR",
    "commit": "$COMMIT"
  },
  "platforms": {
    "ios": "10.0"
  },
  "prepare_command": "sed -i '' 's/\\\"include\\\\/openssl\\\\/is_boringssl.h\\\"/\\\"include\\\\/openssl\\\\/is_boringssl.h\\\", \\\"include\\\\/openssl\\\\/is_openssl.h\\\"/' src/include/openssl/boringssl_prefix_symbols.h",
  "source_files": "src/ssl/*.{h,c,cc}",
  "public_header_files": "src/include/openssl/*.h",
  "header_mappings_dir": "src/include",
  "vendored_libraries": "src/crypto/libcrypto.a",
  "libraries": "c++",
  "compiler_flags": "-DOPENSSL_NO_ASM -DBORINGSSL_PREFIX=GRPC"
}
EOF

echo "BoringSSL-GRPC setup completed." 
#!/bin/bash
# Extensions can't handle symlinks so we have to copy files to make everything
# work.
# TODO(jacobr): use "pub deploy" in the future instead of performing a copy.

# Run from the script's directory
cd $( dirname "${BASH_SOURCE[0]}" )
# Bail on non-zero error code
set -e

# Remove old output, if any
if [ -d "output" ]; then
  rm -r output
fi
mkdir output
cp -r ../bin output/
case `uname -s` in
  "Linux")
     rm output/bin/packages
     cp -L -r ../packages output/bin/
  ;;
  "Darwin")
     rm -r output/bin/packages
     cp -r ../packages output/bin/
  ;;
esac

cp -r ../lib output/
cp *.html *.js output/

# Copy the version from our pubspec, replace '+' by '.' to make the version
# number valid for extension manifests:
PUB_VERSION=$(awk '/version: (.*)/ {print$2}' ../pubspec.yaml)
MANIFEST_VERSION=${PUB_VERSION/+/.}
cat manifest.json | \
  sed -e "s/^  \"version\": .*/  \"version\": \"$MANIFEST_VERSION\",/" > \
  output/manifest.json

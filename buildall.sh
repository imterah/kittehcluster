#!/usr/bin/env bash
mkdir meta > /dev/null 2> /dev/null

for FILE in kitteh-node-*/*; do
  FILE_NO_EXTENSION="${FILE/".nix"/""}"

  # Hacky!
  mkdir -p meta/$FILE
  rm -rf meta/$FILE

  sha512sum $FILE > /tmp/kt-clusterbuild_sha512sum

  if [ ! -f "meta/$FILE.sha" ] || ! diff -q "/tmp/kt-clusterbuild_sha512sum" "meta/$FILE.sha" > /dev/null; then
    ./build.sh $FILE_NO_EXTENSION
  else
    echo "Not building '$FILE_NO_EXTENSION'."
  fi

  mv "/tmp/kt-clusterbuild_sha512sum" "meta/$FILE.sha"
done

echo "Done building."
#!/usr/bin/env bash
for FILE in kitteh-node-*/*; do
  FILE_NO_EXTENSION="${FILE/".nix"/""}"

  if [ ! -f "out/$FILE_NO_EXTENSION.vma.zst" ] || git diff --exit-code $FILE; then
    ./build.sh $FILE_NO_EXTENSION
  else
    echo "Not building '$FILE_NO_EXTENSION'."
  fi
done

echo "Done building."
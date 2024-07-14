#!/usr/bin/env bash
KITTEH_NODE_1=192.168.0.20
KITTEH_NODE_2=192.168.0.21

while IFS= read -r LINE; do
  UPLOAD_PATH="/var/lib/vz/dump/$(basename $LINE)"
  echo "Uploading file '$LINE'..."

  if [ "$(dirname $LINE)" = "out/kitteh-node-1" ]; then
    rsync --info=progress2 $LINE root@$KITTEH_NODE_1:$UPLOAD_PATH
  else
    rsync --info=progress2 $LINE root@$KITTEH_NODE_2:$UPLOAD_PATH
  fi

  ESCAPED_LINE=$(printf '%s\n' "$LINE" | sed -e 's/[\/&]/\\&/g')
  sed -i "/$ESCAPED_LINE/d" meta/tagged_for_upload
done < meta/tagged_for_upload

echo "Done."
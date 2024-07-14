#!/usr/bin/env bash
KITTEH_NODE_1=192.168.0.20
KITTEH_NODE_2=192.168.0.21

KITTEH_NODE_1_BASEID=100
KITTEH_NODE_2_BASEID=100

cp meta/tagged_for_upload /tmp/upload_cache

while IFS= read -r LINE; do
  UPLOAD_PATH="/var/lib/vz/dump/vzdump-qemu-$(basename $LINE .vma.zst)-$(date +"%Y_%m_%d-%H_%M_%S").vma.zst"
  echo "Uploading VM dump '$LINE'..."

  if [ "$(dirname $LINE)" = "out/kitteh-node-1" ]; then
    rsync --info=progress2 $LINE root@$KITTEH_NODE_1:$UPLOAD_PATH
  else
    rsync --info=progress2 $LINE root@$KITTEH_NODE_2:$UPLOAD_PATH
  fi

  if [[ "$@" == *"--install"* ]] || [[ "$@" == *"-i"* ]]; then
    echo "Installing VM dump '$LINE'..."

    if [ "$(dirname $LINE)" = "out/kitteh-node-1" ]; then
      ssh -n root@$KITTEH_NODE_1 "qmrestore $UPLOAD_PATH $KITTEH_NODE_1_BASEID --force --unique"
      KITTEH_NODE_1_BASEID=$((KITTEH_NODE_1_BASEID+1))
    else
      ssh -n root@$KITTEH_NODE_2 "qmrestore $UPLOAD_PATH $KITTEH_NODE_2_BASEID --force --unique"
      KITTEH_NODE_2_BASEID=$((KITTEH_NODE_2_BASEID+1))
    fi
  fi

  if [[ "$@" == *"--delete"* ]] || [[ "$@" == *"-d"* ]]; then
    echo "Deleting VM dump '$LINE'..."
    
    if [ "$(dirname $LINE)" = "out/kitteh-node-1" ]; then
      ssh -n root@$KITTEH_NODE_1 "rm -rf $UPLOAD_PATH"
    else
      ssh -n root@$KITTEH_NODE_2 "rm -rf $UPLOAD_PATH"
    fi
  fi

  ESCAPED_LINE=$(printf '%s\n' "$LINE" | sed -e 's/[\/&]/\\&/g')
  sed -i "/$ESCAPED_LINE/d" meta/tagged_for_upload
done < /tmp/upload_cache

echo "Done."
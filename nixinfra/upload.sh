#!/usr/bin/env bash
if [ "$BASE_IP" = "" ]; then
  BASE_IP=192.168.0.20
fi

IP_LAST_OCTET="${BASE_IP##*.}"
IP_MAIN_OCTET="${BASE_IP%.*}"

IP_LAST_OCTET=$((IP_LAST_OCTET-1))

BASE_ID=100

cp meta/tagged_for_upload /tmp/upload_cache

while IFS= read -r LINE; do
  UPLOAD_PATH="/var/lib/vz/dump/vzdump-qemu-$(basename $LINE .vma.zst)-$(date +"%Y_%m_%d-%H_%M_%S").vma.zst"
  echo "Uploading VM dump '$LINE'..."

  CURRENT_NODE="$(dirname $LINE)"
  CURRENT_NODE="${CURRENT_NODE##*-}"
  IP="$IP_MAIN_OCTET.$((IP_LAST_OCTET+CURRENT_NODE))"

  rsync --info=progress2 $LINE root@$IP:$UPLOAD_PATH

  if [[ "$@" == *"--install"* ]] || [[ "$@" == *"-i"* ]]; then
    echo "Installing VM dump '$LINE'..."

    ssh -n root@$IP "qmrestore $UPLOAD_PATH $BASE_ID --force --unique"
    BASE_ID=$((BASE_ID+1))
  fi

  if [[ "$@" == *"--delete"* ]] || [[ "$@" == *"-d"* ]]; then
    echo "Deleting VM dump '$LINE'..."
    ssh -n root@$IP "rm -rf $UPLOAD_PATH"
  fi

  ESCAPED_LINE=$(printf '%s\n' "$LINE" | sed -e 's/[\/&]/\\&/g')
  sed -i "/$ESCAPED_LINE/d" meta/tagged_for_upload
done < /tmp/upload_cache

echo "Done."
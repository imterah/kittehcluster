#!/usr/bin/env bash
SERVER_INSTALL_PATH="$1"

HTTP_PORT="$((1024 + $RANDOM % 65535))"
TMPDIR="/tmp/server_http_$HTTP_PORT"

BASE_IPS="$(ip a | grep "inet" | grep "brd" | cut -d "/" -f 1 | cut -d " " -f 6)"

EXT_10_DOT_IPS="$(echo "$BASE_IPS" | grep "10.")"
EXT_192168_IPS="$(echo "$BASE_IPS" | grep "192.168.")"
EXT_172_16_IPS="$(echo "$BASE_IPS" | grep "172.16.")"

EXTERNAL_IP_FULL=$EXT_10_DOT_IPS$'\n'$EXT_192168_IPS$'\n'$EXT_172_16_IPS$'\n'

if [ "$SERVER_INSTALL_PATH" = "" ]; then
  echo "You didn't pass in all the arguments! Usage:"
  echo "  ./install.sh \$INSTALL_KEY"
  exit 1
fi

./merge.py "$SERVER_INSTALL_PATH"

echo "[x] initializing..."
mkdir $TMPDIR

echo "#cloud-config" > $TMPDIR/user-data
cat /tmp/script.yml >> $TMPDIR/user-data

if [ "$(uname)" == "Linux" ]; then
  echo "[x] stopping firewall (Linux)..."
  sudo systemctl stop firewall
fi

touch $TMPDIR/meta-data
touch $TMPDIR/vendor-data

echo "[x] starting HTTP server..."
echo " - Listening on port $HTTP_PORT."
echo " - Add one of these command line options for Ubuntu (guessed local IP):"

while IFS= read -r IP; do
  # I'm too lazy to do root causing of this shit.
  
  if [ "$IP" != "" ]; then
    echo "   - autoinstall \"ds=nocloud-net;s=http://$IP:$HTTP_PORT/\""
  fi
done <<< "$EXTERNAL_IP_FULL"

echo " - Choose the right IP."
echo

SERVE_SCRIPT="$PWD/serve.py"

pushd $TMPDIR > /dev/null

python3 $SERVE_SCRIPT $HTTP_PORT

popd > /dev/null 

echo "[x] running cleanup tasks..."
rm -rf $TMPDIR

if [ "$(uname)" == "Linux" ]; then
  echo "[x] starting firewall (Linux)..."
  sudo systemctl start firewall
fi
#!/usr/bin/env bash
SERVER_INSTALL_PATH="$1"
EXTERN_IP="$2"

HTTP_PORT="$((1024 + $RANDOM % 65535))"
TMPDIR="/tmp/server_http_$HTTP_PORT"

if [ "$SERVER_INSTALL_PATH" == "" ]; then
  echo "You didn't pass in all the arguments! Usage:"
  echo "  ./install.sh \$INSTALL_KEY"
  exit 1
fi

if [ "$EXTERN_IP" == "" ]; then
  BASE_IPS="$(ip a | grep "inet" | grep "brd" | cut -d "/" -f 1 | cut -d " " -f 6)"

  EXT_10_DOT_IP="$(echo "$BASE_IPS" | grep "10." | cut -d $'\n' -f 1)"
  EXT_172_16_IP="$(echo "$BASE_IPS" | grep "172.16." | cut -d $'\n' -f 1)"
  EXT_192168_IP="$(echo "$BASE_IPS" | grep "192.168." | cut -d $'\n' -f 1)"

  if [ "$EXT_10_DOT_IP" != "" ]; then
    EXTERN_IP="$EXT_10_DOT_IP"
  fi

  if [ "$EXT_172_16_IP" != "" ]; then
    EXTERN_IP="$EXT_172_16_IP"
  fi

  if [ "$EXT_192168_IP" != "" ]; then
    EXTERN_IP="$EXT_192168_IP"
  fi
fi

./merge.py "$SERVER_INSTALL_PATH" "http://$EXTERN_IP:$HTTP_PORT/api/installer_update_webhook"

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
echo " - Going to listen on port $HTTP_PORT."
echo " - Unless you believe the install has gone wrong, do NOT manually kill the HTTP server,"
echo " - as it will close on its own."
echo " - Add these command line options to Ubuntu:"
echo "   - autoinstall \"ds=nocloud-net;s=http://$EXTERN_IP:$HTTP_PORT/\""

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
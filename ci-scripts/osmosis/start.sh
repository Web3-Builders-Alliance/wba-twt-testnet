#!/bin/bash
set -o errexit -o nounset -o pipefail
command -v shellcheck >/dev/null && shellcheck "$0"

# Please keep this in sync with the Ports overview in HACKING.md
TENDERMINT_PORT_GUEST="26657"
TENDERMINT_PORT_HOST="26653"

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
# shellcheck source=./env
# shellcheck disable=SC1091
source "$SCRIPT_DIR"/env

# Use a fresh volume for every start
docker volume rm -f osmosis_data
# only pull if we don't have it
(docker images | grep "$REPOSITORY" | grep -q "$VERSION") || docker pull "$REPOSITORY:$VERSION"

echo "starting osmosisd running on http://localhost:$TENDERMINT_PORT_HOST"

docker run --rm \
  -e RELAYER_MNEMONIC="harsh adult scrub stadium solution impulse company agree tomorrow poem dirt innocent coyote slight nice digital scissors cool pact person item moon double wagon" \
  -e PASSWORD=1234567890 \
  --user=root \
  --name "$CONTAINER_NAME" \
  -p "$TENDERMINT_PORT_HOST":"$TENDERMINT_PORT_GUEST" \
  -p "9092":"9090" \
  -p "9093":"9091" \
  --mount type=bind,source="$SCRIPT_DIR/template",target=/template \
  --mount type=volume,source=osmosis_data,target=/root \
  "$REPOSITORY:$VERSION" \
    sh -c 'printf "%s\n" "$RELAYER_MNEMONIC" "$PASSWORD" "$PASSWORD" | osmosisd keys add relayer2 --recover &> null; /opt/run.sh 2>&1 | tee debug-osmosis.log | grep "executed block"'

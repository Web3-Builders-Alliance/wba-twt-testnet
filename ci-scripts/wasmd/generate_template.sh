#!/bin/bash
set -o errexit -o nounset -o pipefail
command -v shellcheck >/dev/null && shellcheck "$0"

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
# shellcheck source=./env
# shellcheck disable=SC1091
source "$SCRIPT_DIR"/env

mkdir -p "$SCRIPT_DIR"/template

export CHAIN_ID=wasmd-1

# The usage of the accounts below is documented in README.md of this directory
docker run --rm \
  -e PASSWORD="1234567890" \
  -e CHAIN_ID \
  --mount type=bind,source="$SCRIPT_DIR/template",target=/root \
  "$REPOSITORY:$VERSION" \
  /opt/setup.sh \
  wasm14qemq0vw6y3gc3u3e0aty2e764u4gs5lndxgyk \
  wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp

cp -ar "$SCRIPT_DIR"/../extra/contracts "$SCRIPT_DIR"/template

sudo chmod -R g+rwx "$SCRIPT_DIR"/template/.wasmd/
sudo chmod -R a+rx "$SCRIPT_DIR"/template/.wasmd/

# The ./template folder is created by the docker daemon's user (root on Linux, current user
# when using Docker Desktop on macOS), let's make it ours if needed
if [ ! -x "$SCRIPT_DIR/template/.wasmd/config/gentx" ]; then
  sudo chown -R "$(id -u):$(id -g)" "$SCRIPT_DIR/template"
fi

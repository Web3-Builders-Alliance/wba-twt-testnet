#!/bin/bash

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
HERMES_CFG="$SCRIPT_DIR/../../../hermes/config.toml"
HERMES="hermes --config $HERMES_CFG"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -ac|--a-contract) a_contract="$2"; shift ;;
        -bc|--b-contract) b_contract="$2"; shift ;;
        -cv|--channel-version) version="$2"; shift ;;
        -c|--a-connection) connection="$2"; shift ;;
        -o|--order) order="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Verify we got contract address on wasm
if [ -z "$a_contract" ]; then echo "[ERROR] Please provide contract address on wasmd" && exit 1; fi

# Verify we got contract address on osmosis
if [ -z "$b_contract" ]; then echo "[ERROR] Please provide contract address on osmosis" && exit 1; fi

# Must provide version
if [ -z "$version" ]; then echo "[ERROR] Please provide version of contracts" && exit 1; fi

# If no connection we try connection-0
if [ -z "$connection" ]; then 
    # get connection
    CONNECTION=$(docker exec -it wasmd \
    wasmd query ibc connection connections --output json | jq '.["connections"][0] | .["id"]' | tr -d '"')
else
    CONNECTION=$connection
fi

# If no order we set it unordered
if [ -z "$order" ]; then order="unordered"; fi

# get a contract port
CONTRACT_A_PORT=$(docker exec -it wasmd \
wasmd query wasm contract $a_contract --output json | jq '.["contract_info"] | .["ibc_port_id"]' | tr -d '"')

# get b contract port
CONTRACT_B_PORT=$(docker exec -it osmosis \
osmosisd query wasm contract $b_contract --output json | jq '.["contract_info"] | .["ibc_port_id"]' | tr -d '"')

$HERMES create channel --a-chain wasmd-1 --a-connection $CONNECTION \
--a-port $CONTRACT_A_PORT \
--b-port $CONTRACT_B_PORT \
--order "$order" --channel-version "$version"
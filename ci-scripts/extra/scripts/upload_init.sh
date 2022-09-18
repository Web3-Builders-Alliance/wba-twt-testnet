#!/bin/bash

PASSWORD=1234567890

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--docker-name) docker="$2"; shift ;;
        -c|--contract-name) contract="$2"; shift ;;
        -w|--wallet) wallet="$2"; shift ;;
        -i|--init-json) init_json="$2"; shift ;;
        -l|--label) label="$2"; shift ;;
        -nd|--no-admin) admin=1; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Verify we got the docker, either wasmd or osmosis
if [ -z "$docker" ]; then echo "[ERROR] Please include docker name [wasmd|osmosis]" && exit 1; fi

# Verify we got the contract name to upload
if [ -z "$contract" ]; then echo "[ERROR] Please include contract name to upload [example.wasm]" && exit 1; fi

# Set default label
if [ -z "$label" ]; then label="testing"; fi

# Verify we have a wallet, either a default wallet, or given by user
if [ -z "$wallet" ]; then
    if [[ "$docker" == *"osmo"* ]]; then
        chain_client="osmosisd"
        chain_id="osmo-testing"
        chain_coin="osmo"
        wallet="osmo1ll3s59aawh0qydpz2q3xmqf6pwzmj24t9ch58c"
    elif [[ "$docker" == *"wasm"* ]]; then
        chain_client="wasmd"
        chain_id="wasmd-1"
        chain_coin="cosm"
        wallet="wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp"
    else 
        echo "[ERROR] Didn't recognized '$docker', please provide a wallet" && exit 1;
    fi
fi

# Set --no-admin or the provided/default wallet
if [ -z "$admin" ]; then 
    admin="--no-admin"
else 
    admin="--admin $wallet"
fi

# Verify we got the init message or set it to empty
if [ -z "$init_json" ]; then init_json="{}"; fi

# Upload the contract to the chain, and get the code id from it.
CODE_ID=$(echo "$PASSWORD" | docker exec -i $docker \
$chain_client tx wasm store /template/contracts/$contract --from $wallet \
--node http://127.0.0.1:26657 --chain-id $chain_id \
--gas-prices 0.1u$chain_coin --gas auto --gas-adjustment 1.3 -b block -y --output json | jq '.["logs"][0] | .["events"][1] | .["attributes"][0].value | tonumber')

# Init the contract and get the contract address from it.
CONTRACT_ADDR=$(echo "$PASSWORD" | docker exec -i $docker \
$chain_client tx wasm init $CODE_ID $init_json --from $wallet $admin \
--label $label --node http://127.0.0.1:26657 --chain-id $chain_id --gas-prices 0.1u$chain_coin --gas auto --gas-adjustment 1.3 -b block -y --output json \
| jq '.["logs"][0] | .["events"][0] | .["attributes"][0].value')

# ech to let us know the details.
echo "Code ID:" $CODE_ID
echo "Contract address:" $CONTRACT_ADDR
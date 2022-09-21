#!/bin/bash

PASSWORD=1234567890

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--docker-name) docker="$2"; shift ;;
        -c|--contract-name) contract="$2"; shift ;;
        -w|--wallet) wallet="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Verify we got the docker, either wasmd or osmosis
if [ -z "$docker" ]; then echo "[ERROR] Please include docker name: -d [wasmd|osmosis]" && exit 1; fi

# Verify we got the contract name to upload
if [ -z "$contract" ]; then echo "[ERROR] Please include contract name to upload: -c [example.wasm]" && exit 1; fi

# Verify we have a wallet, either a default wallet, or given by user
if [[ "$docker" == *"osmo"* ]]; then
    chain_client="osmosisd"
    chain_id="osmo-testing"
    chain_coin="osmo"

    if [ -z "$wallet" ]; then wallet="osmo1ll3s59aawh0qydpz2q3xmqf6pwzmj24t9ch58c"; fi
elif [[ "$docker" == *"wasm"* ]]; then
    chain_client="wasmd"
    chain_id="wasmd-1"
    chain_coin="cosm"

    if [ -z "$wallet" ]; then wallet="wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp"; fi
else 
    echo "[ERROR] Didn't recognized '$docker', please provide a wallet: -w [WALLET]" && exit 1;
fi

# Upload the contract to the chain, and get the code id from it.
CODE_ID=$(echo "$PASSWORD" | docker exec -i $docker \
$chain_client tx wasm store /template/contracts/$contract --from $wallet \
--node http://127.0.0.1:26657 --chain-id $chain_id \
--gas-prices 0.1u$chain_coin --gas auto --gas-adjustment 1.3 -b block -y --output json | jq '.["logs"][0] | .["events"][1] | .["attributes"][0].value | tonumber')

echo $( jq -n \
            --argjson code_id "$CODE_ID" \
            --arg docker "$docker" \
            '{chain: $docker, code_id: $code_id}' )

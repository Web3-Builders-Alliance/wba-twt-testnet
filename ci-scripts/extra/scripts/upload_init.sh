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
if [ -z "$docker" ]; then echo "[ERROR] Please include docker name -d [wasmd|osmosis]" && exit 1; fi

# Verify we got the contract name to upload
if [ -z "$contract" ]; then echo "[ERROR] Please include contract name to upload: -c [example.wasm]" && exit 1; fi

# Set default label
if [ -z "$label" ]; then label="testing"; fi

# Verify we have a wallet, either a default wallet, or given by user
if [[ "$docker" =~ "osmo" ]]; then
    if [ -z "$wallet" ]; then wallet="osmo1ll3s59aawh0qydpz2q3xmqf6pwzmj24t9ch58c"; fi
elif [[ "$docker" =~ "wasm" ]]; then
    if [ -z "$wallet" ]; then wallet="wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp"; fi
else 
    echo "[ERROR] Didn't recognized '$docker', please provide a wallet: -w [WALLET]" && exit 1;
fi

# Set --no-admin or the provided/default wallet
if [ -z "$admin" ]; then 
    admin="--admin $wallet"
    is_admin=""
else 
    admin="--no-admin"
    is_admin="-nd"
fi

# Verify we got the init message or set it to empty
if [ -z "$init_json" ]; then init_json="{}"; fi

# Upload the contract to the chain, and get the code id from it.
CODE_ID=$(./upload.sh -d $docker -c $contract -w $wallet | jq '.["code_id"]')

# Init the contract and get the contract address from it.
CONTRACT_ADDR=$(./init.sh -d $docker -c $CODE_ID -w $wallet -i "$init_json" -l $label $is_admin | jq '.["contract_address"]')

echo $( jq -n \
            --argjson code_id "$CODE_ID" \
            --arg docker "$docker" \
            --argjson contract_addr $CONTRACT_ADDR \
            '{chain: $docker, code_id: $code_id, contract_address: $contract_addr'} )
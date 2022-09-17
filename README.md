# IBC testing chains

## Start chains

There are 2 chains, wasmd and osmosisd for testing, you will need to start both of the chains to test IBC.

### Start wasmd in terminal 1:

```bash
$ cd ./ci-scripts/wasmd/start.sh
```

### Start osmosis in terminal 2:

```bash
$ cd ./ci-scripts/osmosis/start.sh
```

### Close chains.

To shut down the chains, go into the terminal and click `ctrl + z` after that, run the stop script.

```bash
$ cd ./ci-scripts/wasmd/stop.sh
```

```bash
$ cd ./ci-scripts/osmosis/stop.sh
```

NOTE: `ctrl + c` might not stop the process because of the way we run the docker, `ctrl + z` will abort and allow you to run the stop script.  
You should also be able to run the stop script in other terminal.

## Start hermes

To run hermes, the chains already include the relayer wallets for signing txs, but we still need hermes to be able to use them.

### Quick start

This will run the needed commands to validate the chains and the config, set up the keys for the wallets, create connection between the chains and 
run hermes proess.

```bash
$ ./hermes/start.sh
```

### Custom hermes

If you need anything else from hermes, you can always run hermes commands

```bash
$ cd hermes

$ hermes --config config.toml [COMMAND]
```

## Working with the test chains

When you stop a chain, all data are deleted, and a fresh chain will be spawned when you start the chain again.  

### General data

Currently we have 2 chains, wasmd and osmosis, naming is important, so here is the list of things we need to know:

**Docker names**  

```
wasmd = wasmd  
osmosis = osmosis  
```

**Chain ids**  
Those names are important as those names are what you use in hermes.

```
wasmd = wasmd-1  
osmosis = osmo-testing
```

**Relayer wallets**  
Those wallets are automatically added inside the chains when you start them.

```
wasmd = wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp
osmosis = osmo1ll3s59aawh0qydpz2q3xmqf6pwzmj24t9ch58c
```

**Chain rpc**

```
wasmd = http://127.0.0.1:26659
osmosis = http://127.0.0.1:26653
```

### Using docker

Because our chains runs inside a docker, we have to talk with the chains from inside the docker.

* You can talk with the chain from outside the docker, by using the --node and giving the RPC URL of the chain: `wasmd: http://127.0.0.1:26659`

You can enter the docker shell:

```
docker exec -it [CHAIN_NAME] sh

// To exit the shell, type:
exit
```

You can run a single command:

```
docker exec -it [CHAIN_NAME] [COMMAND]
```

And you can run multiple commands:

```
docker exec -it [CHAIN_NAME] sh -c "[COMMAND]; [COMMAND]"
```

### Working with contracts

After our chains started, we can upload contracts from inside the docker.

**Move wasm file inside docker**

To upload the contract you need to move the contract wasm file to the docker.  
You can use `'docker cp'` for that. 

```
docker cp [SRC_PATH] [CONTAINER_ID]:[DEST_PATH] 
```

* To find the `CONTAINER_ID` you can use `'docker ps'` and look for the id of the chain you want, you will need to copy the wasm to each of the chains.
* for `[DEST_PATH]` you can use `/opt/CONTRACT_NAME.wasm`, we will use this in our examples.

After the contracts are moved, you can easily use that `[DEST_PATH]` to upload the contract to the chain.

**Upload contracts to chain**

We will use wasmd, but all examples applied to osmosis as well, just make sure to change your wallets and gas.

To upload the contract, we do it the same way we do it usually, and we use the relayer wallet (its just a wallet that is already added)

```
docker exec -it wasmd \
wasmd tx wasm store /opt/contract.wasm --from wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp \
--node http://127.0.0.1:26657 --chain-id wasmd-1 \
--gas-prices 0.1ucosm --gas auto --gas-adjustment 1.3 -b block -y
```

If successful this will provide you the success response with the code id, it should be sequential, so the first uploaded contract should be 1.

**Initialize ontracts**

```
docker exec -it wasmd \
wasmd tx wasm init 1 '{}' --from wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp --admin wasm1ll3s59aawh0qydpz2q3xmqf6pwzmj24t8l43cp \
--label "testing" --node http://127.0.0.1:26657 --chain-id wasmd-1 --gas-prices 0.1ucosm --gas auto --gas-adjustment 1.3 -b block -y
```

If successful this will provide you with the contract address, make sure you write it down, this is important address for us.

We will use this contract address for our examples: `wasm14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s0phg4d`

**Start channel (enable IBC for our contracts)**

To enable IBC, you need to create a channel between our contracts, for that you need to know the ports of the contracts on both chains.  
Usually it will be `wasm.CONTRACT_ADDR` so for our example, the port should be `wasm.wasm14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s0phg4d`.
and on osmosis it should be `wasm.osmo14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9sq2r9g9`.

Thats because our connection between channels are made from wasm to osmo. (but communication, should go both ways)

Lets verify the port by running the next command for each contract:

```
docker exec -it wasmd \
wasmd query wasm contract wasm14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s0phg4d
```

This should give us the info of this contract, and there you should see the ibc port of this contract.

Hermes already opened the connection between the chains, but now we need to open a channel between our contracts.

```
cd hermes

hermes --config config.toml create channel --a-chain wasmd-1 --a-connection connection-0 \
--a-port wasm.wasm14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s0phg4d \ 
--b-port wasm.osmo14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9sq2r9g9 \
--order unordered --channel-version "ping-1"
```

* The connection name should be connection-0 if you only started 1 connection, if that gives you an error, try to use other connection name connection-1 or connection-2(https://hermes.informal.systems/commands/queries/connection.html)

If went successful, the 2 contracts are connected and can talk with each other over IBC! You done it!

Now you can interact with your contracts and test them.
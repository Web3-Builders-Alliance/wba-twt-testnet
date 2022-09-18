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

Move the .wasm files into the `template/contracts` folder of each chains.

This will place the files inside the docker, in the same path inside the docker, at `/template/contracts/wasm.wasm`.

**Upload and init contracts**

`./upload_init.sh`

We have created a script to make this process easier, see [ci-scripts/extra/scripts/upload_init.sh](ci-scripts/extra/scripts/upload_init.sh)

This script will upload and init the contract on the chain, you will need to run this script once per chain.

`Options:`

```
    -d|--docker-name (required) - docker name of the chain. Ex: wasm | osmosis
    -c|--contract-name (required) - full name of the contract. Ex: (ibc_example.wasm)
    -i|--init-json (optional) - init msg for the contract. Default: "{}"
    -w|--wallet (optional) - wallet that will be used for the process. Default: The relayer wallet
    -l|--label (optional) - label for the contract. Default: "testing"
    -nd|--no-admin (optional) - make contract without an admin. Default: -w|--wallet
```

`Example:`

```
./upload_init.sh -d wasmd -c ibc_example.wasm -i "{owner: "ADDR"}" -w ADDR -l "example" --no-admin
```

**Initialize ontracts**

`./init.sh`

We also created a script to only init a contract, see [ci-scripts/extra/scripts/init.sh](ci-scripts/extra/scripts/init.sh)

`Options:`

```
    -d|--docker-name (required) - docker name of the chain. Ex: wasm | osmosis
->  -c|--code-id (required) - code id of uploaded contract. Ex: (1)
    -i|--init-json (optional) - init msg for the contract. Default: "{}"
    -w|--wallet (optional) - wallet that will be used for the process. Default: The relayer wallet
    -l|--label (optional) - label for the contract. Default: "testing"
    -nd|--no-admin (optional) - make contract without an admin. Default: -w|--wallet
```

`Example:`

```
./init.sh -d wasmd -c 1 -i "{owner: "ADDR"}" -w ADDR -l "example" --no-admin
```

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
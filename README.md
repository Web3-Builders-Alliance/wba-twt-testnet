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

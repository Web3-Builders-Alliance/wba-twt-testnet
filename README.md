# Getting started

Before starting chain, create template files:

```bash
$ generate_template.sh
```

Start and stop chain:
```bash
$ ./ci-scripts/wasmd/start.sh

$ ./ci-scripts/wasmd/stop.sh
```

NOTE: to stop the process, please press `ctrl + z` and run stop.sh script.

# Hermes

To use hermes:

```bash
$ cd hermes

$ hermes --config config.toml [COMMAND]
```

# ToDos

[] setup [ts-relayer](https://github.com/confio/ts-relayer)

[] ibc example: sending from chain a to chain b via ts-relayer
## ERC20 Share Token contract

New ShareToken contract with optimizations.

Legacy [contract](https://github.com/ShareRing/ShareToken/tree/legacy).

## Build

```shell
$ forge build
```

## Test

```shell
$ forge test
```

To see gas report for transfer/TransferFrom function in the new contract:

transfer

```shell
forge test -vv --gas-report --match-path test/ShareToken.t.sol --match-test testMigrateWhenTransferToSelf
```

transferFrom

```shell
forge test -vv --gas-report --match-path test/ShareToken.t.sol --match-test testMigrateWhenTransferFromToSelf
```

To see gas report for transfer/TransferFrom function only in the current contract:

transfer

```shell
forge test -vv --gas-report --match-path test/PrevShareToken.t.sol --match-test testMigrateWhenTransfer
```

transferFrom

```shell
forge test -vv --gas-report --match-path test/PrevShareToken.t.sol --match-test testMigrateWhenTransferFrom
```

## Deploy

See [DEPLOYMENT.md](./docs/DEPLOYMENT.md)

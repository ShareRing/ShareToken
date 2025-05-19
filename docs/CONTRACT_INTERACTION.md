### Environment Variables
Add the following environment variables to your `.env` file:

```shell
 SHARE_TOKEN_ADDRESS=<SHARE TOKEN ADDRESS>
```

### Grant Role

```shell
forge script script/GrantRole.s.sol:GrantRole --rpc-url $RPC_URL --broadcast --account DEPLOYER -vvvv --sig "run(bytes calldata, address)" "<ROLE HASH>" "<ACCOUNT ADDRESS>"
```

### Revoke Role

```shell
forge script script/RevokeRole.s.sol:RevokeRole --rpc-url $RPC_URL --broadcast --account DEPLOYER -vvvv --sig "run(bytes calldata, address)" "<ROLE HASH>" "<ACCOUNT ADDRESS>"
```

### Renounce Role

```shell
forge script script/RenounceRole.s.sol:RenounceRole --rpc-url $RPC_URL --broadcast --account DEPLOYER -vvvv --sig "run(bytes calldata, address)" "<ROLE HASH>" "<ACCOUNT ADDRESS>"
```

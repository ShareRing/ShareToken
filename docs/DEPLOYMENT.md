# Prerequisites

[foundry](https://book.getfoundry.sh/getting-started/installation)'s forge 0.2.0 or later

# Clone the project

```bash
git clone git@github.com:ShareRing/ShareToken.git
git checkout main
```

# Set up env

Create an `.env` file with the following content in the project root directory

```
RPC_URL=
ETHERSCAN_API_KEY=

# Deployment inputs
PREV_SHARE_TOKEN_ADDRESS=
ADMIN_ADDRESS=
PAUSER_ADDRESS= 
MINTER_ADDRESS=

# Pause inputs
SHARE_TOKEN_ADDRESS=
```

Refresh environment

```bash
source .env
```

# Deploy the smart contract
## Deploy
use `DeployMainnet.s.sol:DeployMainnet` to deploy the contract on Mainnet
use `DeploySepolia.s.sol:DeploySepolia` to deploy the contract on Sepolia

```bash
forge script script/DeployMainnet.s.sol:DeployMainnet --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --slow --account DEPLOYER -vvvv
```

## Deploy and pause 
Note that the deployer should be the same as the pauser in this script

```bash
forge script script/DeployAndPause.s.sol:DeployAndPause --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --slow --account DEPLOYER -vvvv
```

# Pause/unpause contract
Update the `SHARE_TOKEN_ADDRESS` with the Share Token address in the `.env` file

Refresh environment
```bash
source .env
```
Run the following command to pause/unpause the contract
```bash
forge script script/Pause.s.sol:Pause --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --slow --account PAUSER -vvvv
forge script script/Unpause.s.sol:Unpause --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --slow --account PAUSER -vvvv

```

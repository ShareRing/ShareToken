# Instruction

## Installation

npm install

## Compile smart contract
npm run build

## Deploy smart contract
* npm run deploy-rinkeby (Rinkeby testnet)
* npm run deploy-ropsten (Ropsten testnet)
* npm run deploy-mainnet (Mainnet testnet)

## Generate presale data
* npm run data

**NOTE**:
* All the below scripts are in the folder "./script"

## Feed presale data
* Need to configure 4 parameters in the file "app/global.js"
* pm2 start script/script_presale_rinkeby.sh (Rinkeby testnet)
* pm2 start script/script_presale_ropsten.sh (Ropsten testnet)
* pm2 start script/script_presale_mainnet.sh (Mainnet)

## Verfication of the transfered presale data
* pm2 start script/script_veri_rinkeby.sh (Rinkeby testnet)
* pm2 start script/script_veri_ropsten.sh (Ropsten testnet)
* pm2 start script/script_veri_mainnet.sh (Mainnet)

## Start ICO
* pm2 start script/script_ico_rinkeby.sh (Rinkeby testnet)
* pm2 start script/script_ico_ropsten.sh (Ropsten testnet)
* pm2 start script/script_ico_mainnet.sh (Mainnet)

## Update ETH/USD rate
* pm2 start script/script_rate_rinkeby.sh (Rinkeby testnet)
* pm2 start script/script_rate_ropsten.sh (Ropsten testnet)
* pm2 start script/script_rate_mainnet.sh (Mainnet)

# MainSale Contracts Testcases

The contracts are tested using [Truffle Framework](http://truffleframework.com/docs/getting_started/) under TestRPC.

## QUICK START

* Please install Truffle using *npm* as described [here](http://truffleframework.com/)
* Install TestRPC or new Ganache as described [here](https://github.com/trufflesuite/ganache-cli)
* Run TestRPC/Ganache as Ethereum network and expose port *8545* under *127.0.0.1* (These should be default options).
* Run `truffle test <test_file>` for each test file. They are located under `test/token` folder.

**NOTE**:

* Please test each file under folder *test/token* seperately. 
   * For example: `truffle test test/token/ShareTokenTest.js`
* Please restart TestRPC/Ganache after certain testruns to update testing accounts' balances and states

## Run test

npm test <test_file>




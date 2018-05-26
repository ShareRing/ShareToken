require("babel-register");
require("babel-polyfill");
require('./app/global').globalize();

var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "become manage bind life remove tiger grief between smile enlist settle message";

const WalletProvider = require("truffle-wallet-provider");
const Wallet = require('ethereumjs-wallet');

var privateKey;
var wallet;

if (global.PRIV_KEY) {
  privateKey = new Buffer(global.PRIV_KEY, "hex");
  wallet = Wallet.fromPrivateKey(privateKey);
}

var gasPrice;
require('./app/utils').getGasPrice().
  then(function(res) {
    gasPrice = res;
    console.log('Gas price: ' + gasPrice);
  }).catch(function(err) {
    console.error(err);
  });

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      // host: "127.0.0.1",
      // port: 8545,
      provider: function() {
          return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 5);
      },
      network_id: "*", // Match any network id
      gas: 4500000
    },
    // ropsten: {
    //   provider: function() {
    //     return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/aJvbn5wE7F3LNgkrlkyR", 0)
    //   },
    //   network_id: 3,
    //   gas: 4500000,
    //   // gas: 4717412,
    //   // gasPrice: 20000000000,
    //   // from: "0x6582ca80677F3AcDFc8AeaabbEd0550B31Ee0F02"
    // },
    ropsten: {
      provider: function() {
        return new WalletProvider(wallet, 'https://ropsten.infura.io/KD0tyiBLlHULRInWEMaJ/')
      },
      network_id: 5,
      gas: 3349432,
      gasPrice: gasPrice
    },
    rinkeby: {
      provider: function() {
        return new WalletProvider(wallet, 'https://rinkeby.infura.io/KD0tyiBLlHULRInWEMaJ/')
      },
      network_id: 5,
      gas: 6900000,
      gasPrice: gasPrice
    },
    mainnet: {
      provider: function() {
        return new WalletProvider(wallet, 'https://mainnet.infura.io/KD0tyiBLlHULRInWEMaJ/')
      },
      network_id: 5,
      gas: 6900000,
      gasPrice: gasPrice
    }
  }
};

/* global require */

const MNEMONIC = process.env.MNEMONIC;
const INFURA_KEY = process.env.INFURA_KEY;

const getInfuraProvider = (() => {
  let providers = {};
  return (mnemonic, uri) => {
    const hash = (`${mnemonic}${uri}`)
        .split('').reduce((a,b)=>{a=((a<<5)-a)+b.charCodeAt(0);return a&a},0)
        .toString();
    return providers[hash]
        ? () => providers[hash]
        : () => {
          if (process.env.TRUFFLE_TEST) throw new Error('Forbidden to use Infura in TRUFFLE_TEST environment');
          const HDWalletProvider = require("@truffle/hdwallet-provider");
          providers[hash] = new HDWalletProvider(mnemonic, uri);
          return providers[hash];
        }
  }
})();

if (process.env.TRUFFLE_TEST) {
  require('babel-register');
  require('babel-polyfill');
}

module.exports = {
  networks: {

    // for 'truffle development'
    truffle: {
      host: "127.0.0.1",
      port: 9545,
      network_id: "*",
    },

    // for Ganache App + 'truffle console --network development'
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
      // from: <address>,        // Account to send txs from (default: accounts[0])
      // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    },

    // Ganache: https://hub.docker.com/r/trufflesuite/ganache-cli
    // docker run -d -p 8545:8545 trufflesuite/ganache-cli:latest
    // development: {
    //   host: "localhost",
    //   port: 8545,
    //   network_id: "*"
    // },

    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8545,         // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01      // <-- Use this low gas price
    },

    ropsten: {
      provider: getInfuraProvider(MNEMONIC, `https://ropsten.infura.io/v3/${INFURA_KEY}`),
      network_id: "3",
      port: 8545,
      gas: 4000000
    },

    rinkeby: {
      provider: getInfuraProvider(MNEMONIC, `https://rinkeby.infura.io/v3/${INFURA_KEY}`),
      network_id: "4",
      port: 8545,
      gas: 4000000
    },

    // rinkeby: {
    //   host: "localhost",
    //   port: 8545,
    //   from:"0x1e09a22f24d8fd302b2028a688658e9b29551969"
    // },

    live: {
      network_id: 1,
      provider: getInfuraProvider(MNEMONIC,`https://mainnet.infura.io/v3/${INFURA_KEY}`),
      gas: 4000000,
      gasPrice: 50000000000
    },

  },
  compilers: {
    solc: {
      version: "0.5.13",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};

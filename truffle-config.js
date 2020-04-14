/* global require */

const getInfuraProvider = require('@vkonst/infura-wallets');

// if (process.env.TRUFFLE_TEST) {
//   require('babel-register');
//   require('babel-polyfill');
// }

module.exports = {
  contracts_directory: "./contracts",  // globs/regexps supported as well
  contracts_build_directory: "./build/contracts",
  migrations_directory: "./migrations",

  networks: {

    // for 'truffle development'
    truffle: {
      host: "127.0.0.1",
      port: 9545,
      network_id: "*",
      gas: 5000000,
    },

    // for Ganache (App or Docker) + 'truffle console --network development'
    // docker run -d -p 8545:8545 trufflesuite/ganache-cli:latest
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gasPrice: 2e+9,            // (default: 100 gwei)
      // from: <address>,        // (default: accounts[0])
      websockets: true           // (default: false)
    },

    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8545,                // must match .solcover.js.
      gas: 0xfffffffffff,        // Use this high gas value
      gasPrice: 0x01             // Use this low gas price
    },

    ropsten: {
      provider: getInfuraProvider('ropsten'),
      network_id: "3",
    },

    rinkeby: {
      provider: getInfuraProvider('rinkeby'),
      network_id: "4",
      // from:"0x1e09a22f24d8fd302b2028a688658e9b29551969"
    },

    goerli: {
      provider: getInfuraProvider('goerli'),
      network_id: "5",
    },

    live: {
      network_id: 1,
      provider: getInfuraProvider('mainnet'),
      gasPrice: 1e+6,            // low to avoid unintentional txs
      // gasPrice: 5e+9
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

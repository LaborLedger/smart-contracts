
module.exports = {
  networks: {

    // for Ganache App + 'truffle console --network development'
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
      // from: <address>,        // Account to send txs from (default: accounts[0])
      // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    },

    // for 'truffle development'
    truffle: {
      host: "127.0.0.1",
      port: 9545,
      network_id: "*",
    },

    // Ganache: https://hub.docker.com/r/trufflesuite/ganache-cli
    // docker run -d -p 8545:8545 trufflesuite/ganache-cli:latest
    // development: {
    //   host: "localhost",
    //   port: 8545,
    //   network_id: "*"
    // },

    rinkeby: {
      host: "localhost",
      port: 8545,
      network_id: "4", // Rinkeby network id
      from:"0x1e09a22f24d8fd302b2028a688658e9b29551969"
    },

    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8545,         // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01      // <-- Use this low gas price
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

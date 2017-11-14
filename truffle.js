module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      host: "localhost",
      port: 8545,
      network_id: "3",
      gas: 500000
    },
    kovan: {
      host: 'localhost',
      port: 8545,
      network_id: '42'
    }
  }
};

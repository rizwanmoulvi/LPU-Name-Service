require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.10",
  networks: {
    mumbai: {
      url: "quick node url", //change this
      accounts: ["private key"], //change this
    }
  }
};
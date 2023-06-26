require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-contract-sizer");
require("hardhat-docgen");

// viaIR: true,
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    phalcon: {
      url: process.env.PHALCON_FORK_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    goerli: {
      url: process.env.ALCHEMY_GOERLI_URL,
      chainId: 5,
      accounts: [process.env.PRIVATE_KEY],
    },
    tbsc: {
      url: process.env.TBSC_URL,
      chainId: 97,
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: process.env.ALCHEMY_SEPOLIA_URL,
      chainId: 11155111,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    // BSC_API_KEY ETHERSCAN_API_KEY
    // apiKey: process.env.ETHERSCAN_API_KEY,
    apiKey: {
      phalcon: process.env.PHALCON_ACCESSS_KEY,
      mainnet: process.env.ETHERSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      bsc: process.env.BSC_API_KEY,
      bscTestnet: process.env.BSC_API_KEY,
    },
    customChains: [
      {
        network: "phalcon",
        chainId: 1,
        urls: {
          apiURL: process.env.PHALCON_FORK_APIURL,
          browserURL: "https://etherscan.io/",
        },
      },
    ],
  },

  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  // docgen: {
  //   path: "./docs",
  //   clear: true,
  //   runOnCompile: true,
  // },
};

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

task("blocknumber", "Prints the current block number").setAction(
  async (taskArgs, hre) => {
    const number = await hre.ethers.provider.getBlockNumber();
    console.log(`The current block number: ${number}`);
  }
);

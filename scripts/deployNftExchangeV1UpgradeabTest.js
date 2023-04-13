// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const NFTExchange = await hre.ethers.getContractFactory(
    "NftExchangeV1UpgradeableTest"
  );
  const nftExchange = await NFTExchange.deploy();

  await nftExchange.deployed();

  console.log(`NFTExchange deployed to ${nftExchange.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/deployNftExchangeV1UpgradeabTest.js --network goerli
// npx hardhat verify --network goerli `contractAddress` `args`
// npx hardhat verify --network goerli 0xFF3a1B8e4116CF41b1ba3E926Ba91dEf776C82C0

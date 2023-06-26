// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const Counter = await hre.ethers.getContractFactory("Counter");
  const lock = await Counter.deploy(100);

  await lock.deployed();

  console.log(`deployed to ${lock.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/deployCounter.js --network goerli
// npx hardhat verify --network goerli 0x57635F4854Ae8B74cEA760E8EF25E30e9755b5c2 100

// npx hardhat run scripts/deployCounter.js --network phalcon
// npx hardhat verify --network phalcon 0xB6D0c44E1590D6fF9D15200f688eeADD9A836958 100

const { ethers } = require("ethers");
require("dotenv").config();

const provider = new ethers.providers.JsonRpcProvider(
  process.env.INFURA_OPTIMISM_SEPOLIA
);

// PRIVATE_KEY_UPCHAIN PRIVATE_KEY
const privateKey = process.env.PRIVATE_KEY;

const wallet = new ethers.Wallet(privateKey, provider);

async function stake(eth_amount, contractAddress) {
  const tx = {
    to: contractAddress,
    value: ethers.utils.parseEther(eth_amount),
    data: "0x9573ddbb000000000000000000000000e7b707c05711db8011fcfcb318411fc0f810a1b1",
  };
  const result = await wallet.sendTransaction(tx);

  console.log(result.hash);
  //   await result.wait();
}

async function main() {
  for (let i = 0; i < 46; i++) {
    console.log(i + 1);
    await stake("0.01", "0x89525bC9bAF75E3a5acC078714A29cab3EDBBe3E");
  }
}
main();

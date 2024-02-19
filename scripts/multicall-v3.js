const { ethers } = require("ethers");
require("dotenv").config();

const abi = require("../json/multicall-v3-abi.json");

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);
  // 交互合约 new ethers.Contract(addressOrName, abi, providerOrSigner);
  let multicall3_address = "0xcA11bde05977b3631167028862bE2a173976CA11";

  console.log("owner:", wallet.address);

  const Multicall3 = new ethers.Contract(multicall3_address, abi, wallet);
  try {
    const blockNumber = await Multicall3.getBlockNumber();
    console.log("blockNumber:", blockNumber.toString());
    const owner = wallet.address;
    const balance = await Multicall3.getEthBalance(owner);
    console.log(`wallet balance:`, ethers.utils.formatEther(balance), "ether");

    const calls = [
      {
        target: "0x400df737a64adDB76d30aa0C391e9196F48f93b4",
        callData: "0x18160ddd",
      },
      {
        target: "0x400df737a64adDB76d30aa0C391e9196F48f93b4",
        callData: "0x95d89b41",
      },
    ];
    console.log(calls);
    // // 发送交易
    // const tx = await Multicall3.aggregate(calls);
    // // 等待链上确认交易
    // await tx.wait();
    // console.log(tx.hash);
  } catch (error) {
    console.log(error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/multicall-v3.js
// node scripts/multicall-v3.js

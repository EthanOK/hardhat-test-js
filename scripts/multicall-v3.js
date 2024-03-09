const { ethers } = require("ethers");
const fs = require("fs");
require("dotenv").config();

const multicall3_abi = require("../json/multicall-v3-abi.json");
const gmcq_abi = require("../json/gmcq_abi.json");

const gmcq_list = require("../json/gmcq_list.json");

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);
  // 交互合约 new ethers.Contract(addressOrName, abi, providerOrSigner);
  let multicall3_address = "0xcA11bde05977b3631167028862bE2a173976CA11";
  // 0x400df737a64adDB76d30aa0C391e9196F48f93b4 0xe99E1D7e52cDD7C692cA86283F6138C13D091545
  let gmcq_address = "0xe99E1D7e52cDD7C692cA86283F6138C13D091545";

  console.log("owner:", wallet.address);

  const Multicall3 = new ethers.Contract(
    multicall3_address,
    multicall3_abi,
    wallet
  );

  const GMCQ = new ethers.Contract(gmcq_address, gmcq_abi, wallet);

  const interface = GMCQ.interface;
  let swapDatas = gmcq_list;
  console.log("array length: ", swapDatas.length);

  let calldatas = [];

  let tokenIds = [];
  for (const data of swapDatas) {
    tokenIds = tokenIds.concat(data.tokenIds);
    let calldata = interface.encodeFunctionData("swap", [
      data.receiver,
      data.tokenIds,
    ]);

    calldatas.push(calldata);
  }

  console.log(
    tokenIds.sort(function (a, b) {
      return a - b;
    })
  );

  try {
    const calls = getParamsOfMulticall(gmcq_address, calldatas);
    // console.log(calls);
    let calldata = Multicall3.interface.encodeFunctionData("aggregate", [
      calls,
    ]);
    console.log(calldata);
    fs.writeFileSync("./calldata.txt", calldata);
    // // 发送交易
    // const tx = await Multicall3.aggregate(calls);
    // // 等待链上确认交易
    // await tx.wait();
    // console.log(tx.hash);
  } catch (error) {
    console.log(error);
  }
}

function getParamsOfMulticall(target, callDatas) {
  let params = [];
  for (const callData of callDatas) {
    params.push({ target, callData });
  }
  return params;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/multicall-v3.js
// node scripts/multicall-v3.js

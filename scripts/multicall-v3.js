const { ethers } = require("ethers");
require("dotenv").config();

const multicall3_abi = require("../json/multicall-v3-abi.json");
const gmcq_abi = require("../json/gmcq_abi.json");

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);
  // 交互合约 new ethers.Contract(addressOrName, abi, providerOrSigner);
  let multicall3_address = "0xcA11bde05977b3631167028862bE2a173976CA11";
  let gmcq_address = "0x400df737a64adDB76d30aa0C391e9196F48f93b4";

  console.log("owner:", wallet.address);

  const Multicall3 = new ethers.Contract(
    multicall3_address,
    multicall3_abi,
    wallet
  );

  const GMCQ = new ethers.Contract(gmcq_address, gmcq_abi, wallet);

  const interface = GMCQ.interface;
  let swapDatas = [
    {
      receiver: "0x0000000000000000000000000000000000000001",
      tokenIds: [29],
    },
    {
      receiver: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
      tokenIds: [27, 28],
    },
  ];

  let calldatas = [];
  for (const data of swapDatas) {
    let tokenIds = data.tokenIds;

    let calldata = interface.encodeFunctionData("swap", [
      data.receiver,
      tokenIds,
    ]);

    calldatas.push(calldata);
  }

  try {
    const calls = getParamsOfMulticall(gmcq_address, calldatas);
    // console.log(calls);
    let calldata = Multicall3.interface.encodeFunctionData("aggregate", [
      calls,
    ]);
    console.log(calldata);
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

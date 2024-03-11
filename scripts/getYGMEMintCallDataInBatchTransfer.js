const { ethers } = require("ethers");
const fs = require("fs");
require("dotenv").config();

const multicall3_abi = require("../json/multicall-v3-abi.json");
const ygme_abi = require("../json/ygme_abi.json");

const ygme_swap_list = require("../json/ygme_swap_list.json");

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);
  // 交互合约 new ethers.Contract(addressOrName, abi, providerOrSigner);
  let multicall3_address = "0xcA11bde05977b3631167028862bE2a173976CA11";
  // goerli: 0x28D1bC817DE02C9f105A6986eF85cB04863C3042 main: 0x1b489201D974D37DDd2FaF6756106a7651914A63
  let ygme_address = "0x28D1bC817DE02C9f105A6986eF85cB04863C3042";

  console.log("owner:", wallet.address);

  const Multicall3 = new ethers.Contract(
    multicall3_address,
    multicall3_abi,
    wallet
  );

  const GMCQ = new ethers.Contract(ygme_address, ygme_abi, wallet);

  const interface = GMCQ.interface;
  let swapDatas = ygme_swap_list;
  console.log("array length: ", swapDatas.length);

  let calldatas = [];

  for (const data of swapDatas) {
    let calldata = interface.encodeFunctionData("swap", [
      data.to,
      data._recommender,
      data.mintNum,
    ]);

    calldatas.push(calldata);
  }

  try {
    const calls = getParamsOfMulticall(ygme_address, calldatas);
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

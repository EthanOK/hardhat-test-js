const { ethers } = require("hardhat");
require("dotenv").config();
const provider = new ethers.providers.JsonRpcProvider(process.env.TBSC_URL);

async function sendTransaction() {
  // const tr = await signer.populateTransaction({
  //   to: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
  //   value: 0,
  //   // data: "0x01",
  // });
  // console.log(tr);
  let tr = {
    to: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
    value: 0,
    from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    type: 2,
    maxFeePerGas: 2500000000,
    maxPriorityFeePerGas: 2500000000,
    nonce: 18001,
    gasLimit: 30000,
    chainId: 97,
    data: "0x018001",
  };

  // 签名一笔交易
  const signedTx = await signer.signTransaction(tr);

  console.log(signedTx);

  // 广播交易
  const tx = await provider.sendTransaction(signedTx);

  await tx.wait();
  // console.log(tx.hash);
}

sendTransaction();

// node scripts/signTx_sendSignature.js

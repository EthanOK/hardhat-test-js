const { ethers } = require("hardhat");
require("dotenv").config();

async function getSignature() {
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY);

  // https://learnblockchain.cn/article/2701
  // personal_sign 后来加入来解决这个问题。
  //该方法在任何签名数据前加上"\x19Ethereum Signed Message:\n"

  // 签名二进制信息
  // https://learnblockchain.cn/docs/ethers.js/api-wallet.html#id14
  // https://learnblockchain.cn/docs/ethers.js/api-utils.html#solidity
  // keccak256(abi.encodePacked(a, b)) == utils.solidityKeccak256(types, values)
  //   let tokenId = 1;
  //   let account = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";
  //   let message = await ethers.utils.solidityKeccak256(
  //     ["uint256", "address"],
  //     [tokenId, account]
  //   );
  //   console.log(`tokenId: ${tokenId}`);
  //   console.log(`account: ${account}`);
  //   console.log("utils.solidityKeccak256(a, b):", message);
  //   console.log("keccak256(abi.encodePacked(a, b)):", message);
  //   // console.log(ethers.utils.arrayify(message));
  //   let binaryData = await ethers.utils.arrayify(message);
  //   // Promise<string> 执行 signMessage 函数 自动为数据加了前缀
  //   const signaturedata = signer.signMessage(binaryData);
  //   // console.log(signature);
  //   signaturedata.then((sign) => {
  //     console.log("sign: " + sign);
  //     // let expanded = ethers.utils.splitSignature(sign);
  //     // console.log(expanded);
  //     let adr = ethers.utils.verifyMessage(binaryData, sign);
  //     console.log("signer address: " + adr);
  //   });

  // 签名文本消息
  let str = "hello";
  let signPromise = signer.signMessage(str);
  signPromise.then((sign) => {
    console.log("sign string: " + sign);
    let adr = ethers.utils.verifyMessage(str, sign);
    console.log("signer address: " + adr);
  });

  // 签名二进制信息
  // The 66 character hex string MUST be converted to a 32-byte array first!
  let hash =
    "0xf6896007477ab25a659f87c4f8c5e3baac32547bf305e77aa57743046e10578b";
  let binaryData_ = ethers.utils.arrayify(hash);

  let signPromise_ = signer.signMessage(binaryData_);
  signPromise_.then((sign) => {
    console.log("sign hex: " + sign);
    let adr = ethers.utils.verifyMessage(binaryData_, sign);
    console.log("signer address: " + adr);
  });
}

getSignature();

// console.log(signature);

// https://goerli.etherscan.io/address/0x6e7f9fccadfd34689a9542534c25475b5ffb7282#code

// node scripts/getSignature.js

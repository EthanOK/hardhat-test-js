const { ethers } = require("ethers");
require("dotenv").config();

const provider = new ethers.providers.JsonRpcProvider(
  process.env.ALCHEMY_MAINNET_URL
);
const privateKey = process.env.PRIVATE_KEY;
const wallet = new ethers.Wallet(privateKey, provider);

async function main() {
  //   const contract = new ethers.Contract();

  wallet.getBalance().then((balance) => {
    console.log("balance:", balance);
  });

  const tx = {
    to: "0x1b489201D974D37DDd2FaF6756106a7651914A63",
    data: "0xdf791e5000000000000000000000000074cd2fc9b69f816b4998c5d26d1ed5fd9769d2a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016",
  };

  const gas = await wallet.estimateGas(tx);

  console.log(gas);
}

main();

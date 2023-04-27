const { ethers } = require("ethers");
require("dotenv").config();

const provider = new ethers.providers.JsonRpcProvider(
  process.env.ALCHEMY_MAINNET_URL
);
const address = "0xb5425ebed48d8c859a19a34463b6df9437974d1b";

async function getAddressENSName(address) {
  // 查询与给定地址相关联的ENS域名
  const ensName = await provider.lookupAddress(address);

  return ensName;
}

getAddressENSName(address)
  .then((ensName) => {
    console.log("ENS Name: ", ensName);
  })
  .catch((error) => {
    console.log("Error: ", error);
  });

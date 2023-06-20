const { ethers } = require("ethers");
require("dotenv").config();

const provider = new ethers.providers.JsonRpcProvider(
  process.env.ALCHEMY_MAINNET_URL
);
const address = "0xb5425ebed48d8c859a19a34463b6df9437974d1b";
const name = "ricmoo.eth";

async function getENSNameByAddress(address) {
  //in 11.099 seconds
  const ensName = await provider.lookupAddress(address);

  console.log(ensName);
}
async function getAddressByENSName1(name) {
  //in 6.616 seconds
  const addressByENS = await provider.resolveName("ricmoo.eth");
  console.log(addressByENS);
}
async function getAddressByENSName(name) {
  // in 6.416 seconds
  const resolver = await provider.getResolver(name);
  console.log(await resolver.getAddress());
}
async function main() {
  await getENSNameByAddress(address);

  await getAddressByENSName(name);
}
main();

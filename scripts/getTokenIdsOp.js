const { ethers } = require("ethers");
require("dotenv").config();
const apiKey = process.env.ETHERSCAN_API_KEY;

const nftAddress = "0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4";
const abi = [
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];
const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );

  const nft = new ethers.Contract(nftAddress, abi, provider);
  try {
    const totalSupply = await nft.totalSupply();
    getData(goerliurl, nftAddress, totalSupply.toNumber());
    console.log(totalSupply.toNumber());
  } catch (error) {
    getData(goerliurl, nftAddress, 0);
  }
}

async function getData(url, nftAddress, totalSupply) {
  const account_0x0 = "0x0000000000000000000000000000000000000000";
  if (totalSupply > 0) {
    url =
      url +
      `/api?module=account&action=tokennfttx&contractaddress=${nftAddress}&address=${account_0x0}&startblock=0&endblock=latest&sort=asc&apikey=${apiKey}`;

    console.log(url);
  } else {
  }
}
main();

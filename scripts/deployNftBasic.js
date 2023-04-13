// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("NFTBasic");
  // constructor(name,symbol,baseURI_)
  // const nft = await NFT.deploy(
  //   "WPUNKS",
  //   "WPS",
  //   "https://wrappedpunks.com:3000/api/punks/metadata/"
  // );

  // const nft = await NFT.deploy(
  //   "Bored Ape Yacht Club",
  //   "BAYC",
  //   "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/"
  // );

  // const nft = await NFT.deploy(
  //   "MutantApeYachtClub ",
  //   "MAYC",
  //   "https://boredapeyachtclub.com/api/mutants/"
  // );

  const nft = await NFT.deploy(
    "EtherPOAP OG",
    "EPO",
    "ipfs://bafybeidlx7d65ftmtvk2v6lzxmii2nnkvmlcqj2hmlcvpug7viv36ljqty/"
  );

  await nft.deployed();

  console.log(`NFTBasic deployed to ${nft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// ["0xCcC991EA497647a90Ec6630eD72607d20F87C079","0xa002d00E2Db3Aa0a8a3f0bD23Affda03a694D06A","0x75bA7E89F1907Bd26acd7Fe532A4E8b33bB8F21e","0xba8E66Ade899BabD6B4255a4caD8770d5C65611B","0x809470247DE84986B5D13a4c27b433CA77510196"]
// [20,20,20,20,20]

// npx hardhat run scripts/deployNftBasic.js --network sepolia

// npx hardhat verify --network sepolia `contractAddress` `args`

// npx hardhat verify --network sepolia 0x382916FE4a917A33722c222c9297c5fc997A0222  "WPUNKS" "WPS" "https://wrappedpunks.com:3000/api/punks/metadata/"
// npx hardhat verify --network sepolia 0x42fE9E6345B26FDbeC7130823d48142B6dC1407f  "Bored Ape Yacht Club" "BAYC" "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/"

// 0x382916FE4a917A33722c222c9297c5fc997A0222
// 0x42fE9E6345B26FDbeC7130823d48142B6dC1407f

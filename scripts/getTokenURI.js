const getTokenURI = require("../utils/getTokenURI.js");

const Multicall2_address = "0x8c6f3bF9Ed05afa8DC0D3f08C2DB4a6E731a3574";
const nft_address = "0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4";

const tokenIds = Array.from({ length: 10000 }, (_, i) => i + 1);

async function main() {
  const result = await getTokenURI(nft_address, tokenIds, Multicall2_address);
  console.log(result);
}

main();
// node scripts/getTokenURI.js

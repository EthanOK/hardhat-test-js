const axios = require("axios");

// use thegraph
const query = `
{
    factories(first: 5) {
      id
      poolCount
      txCount
      totalVolumeUSD
    }
    bundles(first: 5) {
      id
      ethPriceUSD
    }
  }
`;
async function getEthPriceUSD() {
  const result = await axios
    .post("https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3", {
      query,
    })
    .catch((err) => console.error(err));
  const ethPriceUSD = result.data.data.bundles[0].ethPriceUSD;
  console.log(`${ethPriceUSD} USD`);
}

getEthPriceUSD();

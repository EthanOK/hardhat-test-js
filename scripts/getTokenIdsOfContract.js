const getData = require("../utils/getTokenIdsOfContract.js");

const nftAddress = "0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b";

// const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

getData(nftAddress, goerliurl)
  .then((data) => {
    console.log(data);
  })
  .catch((error) => {
    console.log(error);
  });

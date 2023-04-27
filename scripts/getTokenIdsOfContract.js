const getData = require("../utils/getTokenIdsOfContract.js");
// mainurl 0xd774557b647330C91Bf44cfEAB205095f7E6c367
const mnftAddress = "0x60e4d786628fea6478f785a6d7e704777c86a7c6";
const gnftAddress = "0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4";

const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

getData(mnftAddress, mainurl)
  .then((data) => {
    console.log(data);
  })
  .catch((error) => {
    console.log(error);
  });

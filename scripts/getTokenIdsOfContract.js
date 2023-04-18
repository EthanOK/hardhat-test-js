const getData = require("../utils/getTokenIdsOfContract.js");
// mainurl 0xd774557b647330C91Bf44cfEAB205095f7E6c367
const mnftAddress = "0xd774557b647330C91Bf44cfEAB205095f7E6c367";
const gnftAddress = "0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b";

const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

getData(mnftAddress, mainurl)
  .then((data) => {
    console.log(data);
  })
  .catch((error) => {
    console.log(error);
  });

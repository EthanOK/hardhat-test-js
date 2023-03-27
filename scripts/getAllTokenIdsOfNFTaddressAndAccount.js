const getData = require("../utils/getAllTokenIdsOfNFTaddressAndAccount.js");

const address = "0xccc991ea497647a90ec6630ed72607d20f87c079";
const nftaddress = "0x0d3e02768ab63516ab5d386fad462214ca3e6a86";

// const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

getData(nftaddress, address, goerliurl)
  .then((data) => {
    console.log(data);
  })
  .catch((error) => {
    console.log(error);
  });

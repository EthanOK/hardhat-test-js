const getData = require("../utils/getAllTokenIdsOfNFTaddressAndAccount.js");

const address = "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2";
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

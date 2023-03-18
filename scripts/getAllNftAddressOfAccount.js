const getData = require("../utils/getAllNftAddressOfAccount.js");

const address = "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2";

// const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

getData(address, goerliurl)
  .then((data) => {
    console.log(data);
  })
  .catch((error) => {
    console.log(error);
  });

const axios = require("axios");
require("dotenv").config();
const address = "0x690B9A9E9aa1C9dB991C7721a92d351Db4FaC990";
const apiKey = process.env.ETHERSCAN_API_KEY;

getAllNftAddressOfAccount(address);

function getAllNftAddressOfAccount(account) {
  const url = `https://api.etherscan.io/api?module=account&action=tokennfttx&address=${account}&startblock=0&endblock=999999999&sort=asc&apikey=${apiKey}`;
  console.log("Account: " + account);
  axios
    .get(url)
    .then((response) => {
      const data = response.data;
      if (data.status === "1") {
        const contractCounts = new Map();
        data.result.forEach((item) => {
          const contractAddress = item.contractAddress;
          if (contractCounts.has(contractAddress)) {
            contractCounts.set(
              contractAddress,
              contractCounts.get(contractAddress) + 1
            );
          } else {
            contractCounts.set(contractAddress, 1);
          }
        });
        console.log(`该账户地址下 ERC721 Token 合约地址及持有数量：`);
        contractCounts.forEach((value, key) => {
          console.log(`${key}: ${value}`);
        });
      } else {
        console.error(`查询 ERC721 Token 合约地址失败：${data.message}`);
      }
    })
    .catch((error) => {
      console.error(`查询 ERC721 Token 合约地址失败：${error.message}`);
    });
}

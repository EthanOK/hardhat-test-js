const axios = require("axios");
require("dotenv").config();
const apiKey = process.env.ETHERSCAN_API_KEY;

// getAllNftAddressOfAccount
function getData(account, url) {
  url =
    url +
    `/api?module=account&action=tokennfttx&address=${account}&startblock=0&endblock=latest&sort=asc&apikey=${apiKey}`;
  // console.log(url);
  // console.log("Account: " + account);
  return axios
    .get(url)
    .then((response) => {
      const data = response.data;
      if (data.status === "1") {
        const contractCounts = new Map();
        const contractNames = new Map();
        const contractSymbol = new Map();
        data.result.forEach((item) => {
          const contractAddress = item.contractAddress;
          if (contractCounts.has(contractAddress)) {
            let counts;
            if (item.to.toLowerCase() == account.toLowerCase()) {
              counts = contractCounts.get(contractAddress) + 1;
            } else {
              counts = contractCounts.get(contractAddress) - 1;
            }
            contractCounts.set(contractAddress, counts);
          } else {
            contractCounts.set(contractAddress, 1);
            contractNames.set(contractAddress, item.tokenName);
            contractSymbol.set(contractAddress, item.tokenSymbol);
          }
        });
        // console.log(`该账户地址下 ERC721 Token 合约地址及持有数量：`);
        const result = [];
        contractCounts.forEach((value, key) => {
          // console.log(`${key}: ${value}`);
          if (value > 0) {
            result.push({
              TokenAddress: key,
              TokenName: contractNames.get(key),
              TokenSymbol: contractSymbol.get(key),
              TokenQuantity: value.toString(),
            });
          }
        });

        const returndata = { status: "1", message: "OK", result: result };
        const jsonString = JSON.stringify(returndata);
        // console.log(jsonString);
        return jsonString;
      } else {
        const nodata = {
          status: "0",
          message: "No transactions found",
          result: [],
        };
        // console.log(nodata);
        return nodata;
      }
    })
    .catch((error) => {
      console.error(`查询 ERC721 Token 合约地址失败：${error.message}`);
    });
}
module.exports = getData;

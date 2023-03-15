const axios = require("axios");
require("dotenv").config();
const address = "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2";
const apiKey = process.env.ETHERSCAN_API_KEY;

getAllNftAddressOfAccount(address);

function getAllNftAddressOfAccount(account) {
  // const url = `https://api.etherscan.io/api?module=account&action=tokennfttx&address=${account}&startblock=0&endblock=999999999&sort=asc&apikey=${apiKey}`;
  const goerliurl = `https://api-goerli.etherscan.io/api?module=account&action=tokennfttx&address=${account}&startblock=0&endblock=999999999&sort=asc&apikey=${apiKey}`;
  console.log(goerliurl);
  console.log("Account: " + account);
  axios
    .get(goerliurl)
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
        console.log(`该账户地址下 ERC721 Token 合约地址及持有数量：`);
        const result = [];
        contractCounts.forEach((value, key) => {
          // console.log(`${key}: ${value}`);

          result.push({
            TokenAddress: key,
            TokenName: contractNames.get(key),
            TokenSymbol: contractSymbol.get(key),
            TokenQuantity: value.toString(),
          });
        });

        const returndata = { status: "1", message: "OK", result: result };
        const jsonString = JSON.stringify(returndata);
        console.log(jsonString);
        return jsonString;
      } else {
        console.error(`查询 ERC721 Token 合约地址失败：${data.message}`);
      }
    })
    .catch((error) => {
      console.error(`查询 ERC721 Token 合约地址失败：${error.message}`);
    });
}

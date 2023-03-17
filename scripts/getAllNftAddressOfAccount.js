const axios = require("axios");
require("dotenv").config();
const address = "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2";
const apiKey = process.env.ETHERSCAN_API_KEY;

// const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

// 查询 Account 名下的所有 ERC721 Token 的合约地址列表
// 返回一个地址所持有的ERC-721代币和金额
// 效果等同于 https://docs.etherscan.io/api-endpoints/tokens#get-address-erc721-token-holding
getAllNftAddressOfAccount(address, goerliurl);

function getAllNftAddressOfAccount(account, url) {
  url =
    url +
    `/api?module=account&action=tokennfttx&address=${account}&startblock=0&endblock=latest&sort=asc&apikey=${apiKey}`;
  console.log(url);
  console.log("Account: " + account);
  axios
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
        console.log(`该账户地址下 ERC721 Token 合约地址及持有数量：`);
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
        console.log(jsonString);
        return jsonString;
      } else {
        const nodata = {
          status: "0",
          message: "No transactions found",
          result: [],
        };
        console.log(nodata);
        return nodata;
      }
    })
    .catch((error) => {
      console.error(`查询 ERC721 Token 合约地址失败：${error.message}`);
    });
}

// 返回格式
/* 
  {
    "status": "1",
    "message": "OK",
    "result": [
      {
        "TokenAddress": "0x6e7f9fccadfd34689a9542534c25475b5ffb7282",
        "TokenName": "A",
        "TokenSymbol": "A",
        "TokenQuantity": "2"
      }
    ]
  } 
*/

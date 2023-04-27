const axios = require("axios");
require("dotenv").config();

const apiKey = process.env.ETHERSCAN_API_KEY;

// getTokenIdsOfContract
function getData(address, url) {
  const account_0x0 = "0x0000000000000000000000000000000000000000";
  url =
    url +
    `/api?module=account&action=tokennfttx&contractaddress=${address}&address=${account_0x0}&startblock=0&endblock=latest&sort=asc&apikey=${apiKey}`;
  console.log(url);
  return axios
    .get(url)
    .then((response) => {
      const data = response.data;
      if (data.status === "1") {
        const tokenids = [];

        data.result.forEach((item) => {
          if (item.from.toLowerCase() == account_0x0.toLowerCase()) {
            tokenids.push(item.tokenID);
          }
        });

        console.log(`该合约地址${address}已经铸造的所有nft的tokenId: `);

        const returndata = { status: "1", message: "OK", result: tokenids };
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

// 返回格式
/* 
  {
    "status": "1",
    "message": "OK",
    "result": ["0", "43", "44", "45", "46", "47"]
  } 
*/

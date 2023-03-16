const axios = require("axios");
require("dotenv").config();
const nftAddress = "0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b";
const apiKey = process.env.ETHERSCAN_API_KEY;

// const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

// 查询ERC721合约已经铸造的所有nft的tokenId
// 返回一个地址所持有的ERC-721代币和金额
// 效果等同于 https://docs.etherscan.io/api-endpoints/tokens#get-address-erc721-token-holding
getTokenIdsOfContract(nftAddress, goerliurl);
// api?module=account&action=tokennfttx&contractaddress=0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D&address=0x0000000000000000000000000000000000000000&startblock=0&endblock=latest&sort=asc&apikey=YourApiKeyToken
function getTokenIdsOfContract(address, url) {
  const account_0x0 = "0x0000000000000000000000000000000000000000";
  url =
    url +
    `/api?module=account&action=tokennfttx&contractaddress=${address}&address=${account_0x0}&startblock=0&endblock=latest&sort=asc&apikey=${apiKey}`;
  // console.log(url);
  axios
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

        console.log(`该合约已经铸造的所有nft的tokenId: `);

        const returndata = { status: "1", message: "OK", result: tokenids };
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
    "result": ["0", "43", "44", "45", "46", "47"]
  } 
*/

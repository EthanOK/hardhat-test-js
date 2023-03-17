const axios = require("axios");
require("dotenv").config();
const address = "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2";
const apiKey = process.env.ETHERSCAN_API_KEY;
const nftaddress = "0x0d3e02768ab63516ab5d386fad462214ca3e6a86";

// const mainurl = `https://api.etherscan.io`;
const goerliurl = `https://api-goerli.etherscan.io`;

console.log("account:" + address);
console.log("nftaddress:" + nftaddress);
// 查询 Account 名下持有某nft的tokenId集合
// 返回一个地址所持有某一ERC-721代币的tokenIds
// 效果等同于 https://docs.etherscan.io/api-endpoints/tokens#get-address-erc721-token-inventory-by-contract-address
getAllTokenIdsOfNFTaddressAndAccount(nftaddress, address, goerliurl);

function getAllTokenIdsOfNFTaddressAndAccount(nftaddress, account, url) {
  url =
    url +
    `/api?module=account&action=tokennfttx&contractaddress=${nftaddress}&address=${account}&startblock=0&endblock=latest&sort=asc&apikey=${apiKey}`;

  axios
    .get(url)
    .then((response) => {
      const data = response.data;
      if (data.status === "1") {
        const tokensSet = new Set();

        data.result.forEach((item) => {
          if (item.to.toLowerCase() == account.toLowerCase()) {
            tokensSet.add(item.tokenID);
          } else {
            if (tokensSet.has(item.tokenID) == true) {
              tokensSet.delete(item.tokenID);
            }
          }
        });

        console.log(`该账户地址下持有该NFT的所有tokenIds:`);
        const ids = [...tokensSet];
        console.log("tokenIds: " + ids);
        const result = [];
        ids.forEach((value) => {
          result.push({
            TokenAddress: nftaddress.toLowerCase(),
            TokenId: value.toString(),
          });
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
      "TokenId": "1"
    },
    {
      "TokenAddress": "0x6e7f9fccadfd34689a9542534c25475b5ffb7282",
      "TokenId": "10"
    }
  ]
}
*/

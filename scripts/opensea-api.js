const Web3 = require("web3");
const { OpenSeaSDK, Network } = require("opensea-js");
const fs = require("fs");
require("dotenv").config();
const getOrder = require("../utils/getOrderDataOfOpenSea.js");

const YOUR_API_KEY = process.env.OPENSEA_API;
const PRC = process.env.ALCHEMY_GOERLI_URL;
// This example provider won't let you make transactions, only read-only calls:
const provider = new Web3.providers.HttpProvider(PRC);
// console.log(provider);

const openseaSDK = new OpenSeaSDK(provider, {
  networkName: Network.Goerli,
  //   apiKey: YOUR_API_KEY,
});
const asset = {
  tokenAddress: "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d", // CryptoKitties
  tokenId: "1710", // Token ID
};
const accountAddress = "0xC675897Bb91797EaeA7584F025A5533DBB13A000";

async function main() {
  // 获取资产
  //   const OpenSeaAsset = await openseaSDK.api.getAsset(asset);

  // 具体来说，“ask”表示出售订单，即卖家希望以特定价格出售其NFT。
  // 而“bid”表示出价订单，即买家希望以特定价格购买NFT。
  const contractAddress = "0x97f236e644db7be9b8308525e6506e4b3304da7b";
  const tokenId = "1000";

  const transactionData = await getOrder(
    openseaSDK,
    accountAddress,
    contractAddress,
    tokenId
  );
  console.log(transactionData);
  //   const order = await openseaSDK.api.getOrder({
  //     side: "ask",
  //     assetContractAddress: contractAddress,
  //     tokenId: tokenId,
  //   });
  //   console.log(order);

  //   const result = await openseaSDK.api.generateFulfillmentData(
  //     accountAddress,
  //     order.orderHash,
  //     order.protocolAddress,
  //     order.side
  //   );
  //   console.log(result);
  //   const jsonOrders = JSON.stringify(result);

  //   fs.writeFile("./json/data.json", jsonOrders, (err) => {
  //     if (err) throw err;
  //     console.log("The file has been saved!");
  //   });

  const getTokenURI = require("../utils/getTokenURI.js");
}

main();

async function getAssetBalance() {
  // 获取资产余额
  const balance = await openseaSDK.getAssetBalance({
    accountAddress, // string
    asset, // Asset
  });
  console.log("balance:" + balance);
}
async function getTokenBalance() {
  // 获取Token余额
  const balanceOfWETH = await openseaSDK.getTokenBalance({
    accountAddress, // string
    tokenAddress: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
  });
  console.log("balanceOfWETH:" + balanceOfWETH);
}

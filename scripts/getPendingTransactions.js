const { ethers } = require("ethers");

require("dotenv").config();

const provider = new ethers.providers.JsonRpcProvider(
  process.env.ALCHEMY_GOERLI_URL
);
async function getPendingTransactions() {
  provider.on("pending", async (tx) => {
    if (tx) {
      // 获取交易详细信息
      console.log(tx.hash);
    }
  });
}

getPendingTransactions().catch((error) => {
  console.log(error);
});

// Setup: npm install alchemy-sdk
const { Alchemy, Network } = require("alchemy-sdk");

const config = {
  apiKey: "Alchemy_apiKey",
  network: Network.ETH_MAINNET,
};
const alchemy = new Alchemy(config);

const main = async () => {
  // 合约地址
  const address = "0x1b489201D974D37DDd2FaF6756106a7651914A63";

  // 是否省略元数据的标志
  const omitMetadata = false;

  // 设置要开始查询的项目的索引
  const fromIndex = 101;
  const toIndex = 200;

  // 从第201个项目开始获取所有NFT
  const response = await alchemy.nft.getNftsForContract(address, {
    omitMetadata: omitMetadata,
    from: fromIndex,
    to: toIndex,
  });
  console.log(JSON.stringify(response, null, 2));
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();

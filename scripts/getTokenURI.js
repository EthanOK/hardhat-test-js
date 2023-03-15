const { ethers } = require("hardhat");

const abi = [
  {
    inputs: [
      {
        components: [
          { internalType: "address", name: "target", type: "address" },
          { internalType: "bytes", name: "callData", type: "bytes" },
        ],
        internalType: "struct Multicall2.Call[]",
        name: "calls",
        type: "tuple[]",
      },
    ],
    name: "aggregateStaticCall",
    outputs: [
      { internalType: "uint256", name: "blockNumber", type: "uint256" },
      { internalType: "bytes[]", name: "returnData", type: "bytes[]" },
    ],
    stateMutability: "view",
    type: "function",
  },
];
const Multicall2_address = "0x8c6f3bF9Ed05afa8DC0D3f08C2DB4a6E731a3574";
const nft_address = "0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4";

const tokenIds = Array.from({ length: 100 }, (_, i) => i + 1);

async function main() {
  // connect Multicall2
  const Multicall2 = await getContract(Multicall2_address, abi);
  console.log("Multicall2address:", Multicall2.address);

  try {
    // get staticcalls struct data
    const staticcalls = getStaticcallsOftokenURI(nft_address, tokenIds);

    // return bytes[]:returnData
    const [blockNumber_, returnData] = await Multicall2.aggregateStaticCall(
      staticcalls
    );
    console.log("NFT contract address:" + nft_address);
    console.log("`````````````````````````````````````````");
    // bytes to string (tokenURI() return string)
    for (let i = 0; i < returnData.length; i++) {
      const decodedata = ethers.utils.defaultAbiCoder.decode(
        ["string"],
        returnData[i]
      );

      console.log(`tokenURI(${tokenIds[i]}): ` + decodedata.toString());
    }
  } catch (error) {
    console.log(error);
  }
}

async function getContract(Caddress, abi_) {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );

  // connect Contract: new ethers.Contract(addressOrName, abi, providerOrSigner);
  const Multicall2 = new ethers.Contract(Caddress, abi_, provider);
  return Multicall2;
}

// calculate `balanceOf(address)` 的 calldata
// paramsType ["address"]
// params [owner]
function calculateCalldata(sselector, paramsType, params) {
  const functionSelector = ethers.utils.id(sselector);
  const selector = ethers.utils.hexDataSlice(functionSelector, 0, 4);

  if (params.length == 0) {
    return selector;
  }

  const encodedParams = ethers.utils.defaultAbiCoder.encode(paramsType, params);
  const balanceOfcalldata = selector + encodedParams.slice(2);
  return balanceOfcalldata;
}

function getStaticcallsOftokenURI(address, tokenIds) {
  const sselector_ = "tokenURI(uint256)"; // 0xc87b56dd
  let paramsType_ = ["uint256"];

  const callstruct = [];

  for (let i = 0; i < tokenIds.length; i++) {
    callstruct.push({
      target: address,
      callData: calculateCalldata(sselector_, paramsType_, [tokenIds[i]]),
    });
  }
  return callstruct;
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

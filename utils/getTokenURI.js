const { ethers } = require("ethers");
require("dotenv").config();

async function getTokenURI(erc721_address, tokenIds_, M_address) {
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
  // connect Multicall2
  const Multicall2 = await getContract(M_address, abi);

  try {
    // get staticcalls struct data
    const staticcalls = getStaticcallsOftokenURI(erc721_address, tokenIds_);

    // return bytes[]:returnData
    const [blockNumber_, returnData] = await Multicall2.aggregateStaticCall(
      staticcalls
    );

    const result = [];
    // bytes to string (tokenURI() return string)
    for (let i = 0; i < returnData.length; i++) {
      const decodedata = ethers.utils.defaultAbiCoder.decode(
        ["string"],
        returnData[i]
      );
      result.push({
        TokenId: tokenIds_[i].toString(),
        TokenURI: decodedata.toString(),
      });
    }
    const returndata = { status: "1", message: "OK", result: result };
    const jsonString = JSON.stringify(returndata);
    // console.log(jsonString);
    return jsonString;
  } catch (error) {
    console.log(error.message);
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

module.exports = getTokenURI;

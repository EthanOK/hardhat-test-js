const { ethers } = require("ethers");
require("dotenv").config();

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
    name: "aggregate",
    outputs: [
      { internalType: "uint256", name: "blockNumber", type: "uint256" },
      { internalType: "bytes[]", name: "returnData", type: "bytes[]" },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
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
    name: "blockAndAggregate",
    outputs: [
      { internalType: "uint256", name: "blockNumber", type: "uint256" },
      { internalType: "bytes32", name: "blockHash", type: "bytes32" },
      {
        components: [
          { internalType: "bool", name: "success", type: "bool" },
          { internalType: "bytes", name: "returnData", type: "bytes" },
        ],
        internalType: "struct Multicall2.Result[]",
        name: "returnData",
        type: "tuple[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "blockNumber", type: "uint256" }],
    name: "getBlockHash",
    outputs: [{ internalType: "bytes32", name: "blockHash", type: "bytes32" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getBlockNumber",
    outputs: [
      { internalType: "uint256", name: "blockNumber", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getCurrentBlockCoinbase",
    outputs: [{ internalType: "address", name: "coinbase", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getCurrentBlockDifficulty",
    outputs: [{ internalType: "uint256", name: "difficulty", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getCurrentBlockGasLimit",
    outputs: [{ internalType: "uint256", name: "gaslimit", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getCurrentBlockTimestamp",
    outputs: [{ internalType: "uint256", name: "timestamp", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "addr", type: "address" }],
    name: "getEthBalance",
    outputs: [{ internalType: "uint256", name: "balance", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getLastBlockHash",
    outputs: [{ internalType: "bytes32", name: "blockHash", type: "bytes32" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "bool", name: "requireSuccess", type: "bool" },
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
    name: "tryAggregate",
    outputs: [
      {
        components: [
          { internalType: "bool", name: "success", type: "bool" },
          { internalType: "bytes", name: "returnData", type: "bytes" },
        ],
        internalType: "struct Multicall2.Result[]",
        name: "returnData",
        type: "tuple[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "bool", name: "requireSuccess", type: "bool" },
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
    name: "tryBlockAndAggregate",
    outputs: [
      { internalType: "uint256", name: "blockNumber", type: "uint256" },
      { internalType: "bytes32", name: "blockHash", type: "bytes32" },
      {
        components: [
          { internalType: "bool", name: "success", type: "bool" },
          { internalType: "bytes", name: "returnData", type: "bytes" },
        ],
        internalType: "struct Multicall2.Result[]",
        name: "returnData",
        type: "tuple[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_GOERLI_URL
  );
  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);
  // 交互合约 new ethers.Contract(addressOrName, abi, providerOrSigner);
  let Multicall2_address = "0x8c6f3bF9Ed05afa8DC0D3f08C2DB4a6E731a3574";

  console.log("owner:", wallet.address);

  const Multicall2 = new ethers.Contract(Multicall2_address, abi, wallet);
  try {
    const blockNumber = await Multicall2.getBlockNumber();
    console.log("blockNumber:", blockNumber.toString());
    const owner = wallet.address;
    const balance = await Multicall2.getEthBalance(owner);
    console.log(`wallet balance:`, ethers.utils.formatEther(balance), "ether");

    // function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData)
    //   struct Call {
    //     address target;
    //     bytes callData;
    // }

    // USDT：0xB8628a816b302A14697d99f103dBe58b6E1777AF
    // totalSupply() 0x18160ddd
    // symbol() 0x95d89b41
    // const calls = [
    //   {
    //     target: "0xB8628a816b302A14697d99f103dBe58b6E1777AF",
    //     callData: "0x18160ddd",
    //   },
    //   {
    //     target: "0xB8628a816b302A14697d99f103dBe58b6E1777AF",
    //     callData: "0x95d89b41",
    //   },
    // ];
    // // 发送交易
    // const tx = await Multicall2.aggregate(calls);
    // // 等待链上确认交易
    // await tx.wait();
    // console.log(tx.hash);

    // Only Read Data (external account call not gas)
    // function aggregateStaticCall(Call[] memory calls) public view returns (uint256 blockNumber, bytes[] memory returnData)
    // totalSupply() 0x18160ddd
    // symbol() 0x95d89b41
    // balanceOf(0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2) 0x70a082310000000000000000000000006278a1e803a76796a3a1f7f6344fe874ebfe94b2
    // decimals() 0x313ce567

    // 计算 Solidity 函数 `balanceOf(address)` 的 calldata
    const functionSelector = ethers.utils.id("balanceOf(address)");
    const selector = ethers.utils.hexDataSlice(functionSelector, 0, 4);
    const encodedParams = ethers.utils.defaultAbiCoder.encode(
      ["address"],
      [owner]
    );
    const balanceOfcalldata = selector + encodedParams.slice(2); // 去除前面的 '0x'

    console.log("```````````````````````````````");
    const staticcalls = [
      {
        target: "0xB8628a816b302A14697d99f103dBe58b6E1777AF",
        callData: "0x18160ddd",
      },
      {
        target: "0xB8628a816b302A14697d99f103dBe58b6E1777AF",
        callData: "0x95d89b41",
      },
      {
        target: "0xB8628a816b302A14697d99f103dBe58b6E1777AF",
        callData: balanceOfcalldata,
      },
      {
        target: "0xB8628a816b302A14697d99f103dBe58b6E1777AF",
        callData: "0x313ce567",
      },
    ];

    let [blockNumber_, returnData] = await Multicall2.callStatic.aggregate(
      staticcalls
    );

    const totalSupply = parseInt(returnData[0], 16);

    // 解码 Solidity 结构体数据
    const decodedSymbol = ethers.utils.defaultAbiCoder.decode(
      ["string"],
      returnData[1]
    );

    const symbol = decodedSymbol.toString();
    console.log(symbol);
    console.log("blockNumber:", blockNumber_.toString());
    const decimals = parseInt(returnData[3], 16);
    const total_usdt = ethers.utils.formatUnits(totalSupply, decimals);

    console.log(`totalSupply: ${total_usdt} ${symbol}`);

    // balanceOf(owner)
    const balanceOf_owner = parseInt(returnData[2], 16);
    const balanceOf_owner_usdt = ethers.utils.formatUnits(
      balanceOf_owner,
      decimals
    );
    console.log(`balanceOf(owner): ${balanceOf_owner_usdt} ${symbol}`);
  } catch (error) {
    console.log(error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/multicall.js
// node scripts/multicall.js

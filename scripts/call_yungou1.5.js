const { ethers, BigNumber } = require("ethers");

require("dotenv").config();

// 构建结构体
// enum OrderType {
//     ETH_TO_ERC721,
//     ETH_TO_ERC1155,
//     ERC20_TO_ERC721,
//     ERC20_TO_ERC1155,
//     ERC721_TO_ERC20,
//     ERC1155_TO_ERC20
// }

let yungou1_5Abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "offerer",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "offerToken",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "offerTokenId",
        type: "uint256",
      },
      {
        components: [
          {
            internalType: "enum ExchangeDomainV1_5.OrderType",
            name: "orderType",
            type: "uint8",
          },
          { internalType: "address payable", name: "offerer", type: "address" },
          { internalType: "address", name: "offerToken", type: "address" },
          { internalType: "uint256", name: "offerTokenId", type: "uint256" },
          { internalType: "uint256", name: "unitPrice", type: "uint256" },
          { internalType: "uint256", name: "sellAmount", type: "uint256" },
          { internalType: "uint256", name: "startTime", type: "uint256" },
          { internalType: "uint256", name: "endTime", type: "uint256" },
          { internalType: "address", name: "paymentToken", type: "address" },
          { internalType: "uint256", name: "paymentTokenId", type: "uint256" },
          { internalType: "uint256", name: "royaltyFee", type: "uint256" },
          { internalType: "uint256", name: "platformFee", type: "uint256" },
          { internalType: "uint256", name: "afterTaxPrice", type: "uint256" },
        ],
        indexed: false,
        internalType: "struct ExchangeDomainV1_5.BasicOrderParameters",
        name: "parameters",
        type: "tuple",
      },
      {
        indexed: false,
        internalType: "address",
        name: "buyer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "buyAmount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "totalPayment",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "totalRoyaltyFee",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "totalPlatformFee",
        type: "uint256",
      },
    ],
    name: "Exchange",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: "uint8", name: "version", type: "uint8" },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "Paused",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "Unpaused",
    type: "event",
  },
  {
    inputs: [],
    name: "NAME_YUNGOU",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "VERSION",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "enum ExchangeDomainV1_5.OrderType",
                name: "orderType",
                type: "uint8",
              },
              {
                internalType: "address payable",
                name: "offerer",
                type: "address",
              },
              { internalType: "address", name: "offerToken", type: "address" },
              {
                internalType: "uint256",
                name: "offerTokenId",
                type: "uint256",
              },
              { internalType: "uint256", name: "unitPrice", type: "uint256" },
              { internalType: "uint256", name: "sellAmount", type: "uint256" },
              { internalType: "uint256", name: "startTime", type: "uint256" },
              { internalType: "uint256", name: "endTime", type: "uint256" },
              {
                internalType: "address",
                name: "paymentToken",
                type: "address",
              },
              {
                internalType: "uint256",
                name: "paymentTokenId",
                type: "uint256",
              },
              { internalType: "uint256", name: "royaltyFee", type: "uint256" },
              { internalType: "uint256", name: "platformFee", type: "uint256" },
              {
                internalType: "uint256",
                name: "afterTaxPrice",
                type: "uint256",
              },
            ],
            internalType: "struct ExchangeDomainV1_5.BasicOrderParameters",
            name: "parameters",
            type: "tuple",
          },
          { internalType: "bytes", name: "orderSignature", type: "bytes" },
          { internalType: "uint256", name: "buyAmount", type: "uint256" },
          { internalType: "uint256", name: "totalRoyaltyFee", type: "uint256" },
          {
            internalType: "uint256",
            name: "totalPlatformFee",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "totalAfterTaxIncome",
            type: "uint256",
          },
          { internalType: "uint256", name: "totalPayment", type: "uint256" },
          { internalType: "uint256", name: "expiryDate", type: "uint256" },
          { internalType: "bytes", name: "systemSignature", type: "bytes" },
        ],
        internalType: "struct ExchangeDomainV1_5.BasicOrder[]",
        name: "orders",
        type: "tuple[]",
      },
      { internalType: "address", name: "receiver", type: "address" },
    ],
    name: "batchExcuteWithETH",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "enum ExchangeDomainV1_5.OrderType",
                name: "orderType",
                type: "uint8",
              },
              {
                internalType: "address payable",
                name: "offerer",
                type: "address",
              },
              { internalType: "address", name: "offerToken", type: "address" },
              {
                internalType: "uint256",
                name: "offerTokenId",
                type: "uint256",
              },
              { internalType: "uint256", name: "unitPrice", type: "uint256" },
              { internalType: "uint256", name: "sellAmount", type: "uint256" },
              { internalType: "uint256", name: "startTime", type: "uint256" },
              { internalType: "uint256", name: "endTime", type: "uint256" },
              {
                internalType: "address",
                name: "paymentToken",
                type: "address",
              },
              {
                internalType: "uint256",
                name: "paymentTokenId",
                type: "uint256",
              },
              { internalType: "uint256", name: "royaltyFee", type: "uint256" },
              { internalType: "uint256", name: "platformFee", type: "uint256" },
              {
                internalType: "uint256",
                name: "afterTaxPrice",
                type: "uint256",
              },
            ],
            internalType: "struct ExchangeDomainV1_5.BasicOrderParameters",
            name: "parameters",
            type: "tuple",
          },
          { internalType: "bytes", name: "orderSignature", type: "bytes" },
          { internalType: "uint256", name: "buyAmount", type: "uint256" },
          { internalType: "uint256", name: "totalRoyaltyFee", type: "uint256" },
          {
            internalType: "uint256",
            name: "totalPlatformFee",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "totalAfterTaxIncome",
            type: "uint256",
          },
          { internalType: "uint256", name: "totalPayment", type: "uint256" },
          { internalType: "uint256", name: "expiryDate", type: "uint256" },
          { internalType: "bytes", name: "systemSignature", type: "bytes" },
        ],
        internalType: "struct ExchangeDomainV1_5.BasicOrder",
        name: "order",
        type: "tuple",
      },
      { internalType: "address", name: "receiver", type: "address" },
    ],
    name: "excuteWithETH",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "getBeneficiary",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "_beneficiary",
        type: "address",
      },
      { internalType: "address", name: "_systemVerifier", type: "address" },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "paused",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "newBeneficiary",
        type: "address",
      },
    ],
    name: "setBeneficiary",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "setPause",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "newOwner", type: "address" }],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "account", type: "address" }],
    name: "withdrawEther",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];
let orderType = 0;
let offerer = "0x6278a1e803a76796a3a1f7f6344fe874ebfe94b2";
let offerToken = "0xeaafcc17f28afe5cda5b3f76770efb7ef162d20b";
let offerTokenId = BigNumber.from("7");
let unitPrice = BigNumber.from("10000000000000000");
let sellAmount = 1;
let startTime = 1684304543;
let endTime = 1686896535;
let paymentToken = "0x0000000000000000000000000000000000000000";
let paymentTokenId = 0;
let royaltyFee = BigNumber.from("250000000000000");
let platformFee = BigNumber.from("250000000000000");
let afterTaxPrice = BigNumber.from("9500000000000000");

let parameters = {
  orderType: orderType,
  offerer: offerer,
  offerToken: offerToken,
  offerTokenId: offerTokenId,
  unitPrice: unitPrice,
  sellAmount: sellAmount,
  startTime: startTime,
  endTime: endTime,
  paymentToken: paymentToken,
  paymentTokenId: paymentTokenId,
  royaltyFee: royaltyFee,
  platformFee: platformFee,
  afterTaxPrice: afterTaxPrice,
};

// // buy it now
// struct BasicOrderParameters {
//     OrderType orderType;
//     address payable offerer;
//     address offerToken;
//     uint256 offerTokenId;
//     uint256 unitPrice;
//     uint256 sellAmount;
//     uint256 startTime;
//     uint256 endTime;
//     address paymentToken;
//     uint256 paymentTokenId;
//     uint256 royaltyFee;
//     uint256 platformFee;
//     uint256 afterTaxPrice;
// }

let orderSignature =
  "0x3fdbd808fb738b573e84c461580aca8224ecd9b7f120270782115658e1c0b10910cbf1584155cc201688863ed1d21c2f0c35b73c1d061e72296ff2e8819e99931b";
let buyAmount = 1;
let totalRoyaltyFee = BigNumber.from("250000000000000");
let totalPlatformFee = BigNumber.from("250000000000000");
let totalAfterTaxIncome = BigNumber.from("9500000000000000");
let totalPayment = BigNumber.from("10000000000000000");
let expiryDate = 1686896535;
let systemSignature =
  "0x8bd4b149217efc24c5ce3b55608eb7f557a4424defd86b7a87fbfa06846911f53ce2ceecae197448fad068bc288ea169a95edb208db936527cf5a4fbf0525f741b";

let order = {
  parameters: parameters,
  orderSignature: orderSignature,
  buyAmount: buyAmount,
  totalRoyaltyFee: totalRoyaltyFee,
  totalPlatformFee: totalPlatformFee,
  totalAfterTaxIncome: totalAfterTaxIncome,
  totalPayment: totalPayment,
  expiryDate: expiryDate,
  systemSignature: systemSignature,
};

let receiver = "0xD1fFE5310EeFCfB2558ed2C5F7b0F7F497db9666";

console.log(order);
let yungou1_5Address = "0x413E7C5Cc2cD3380b7C32159A1933de7c70f4735";
const provider = new ethers.providers.JsonRpcProvider(
  process.env.ALCHEMY_GOERLI_URL
);
const yungou1_5 = new ethers.Contract(yungou1_5Address, yungou1_5Abi, provider);

async function main() {
  let result_ = await yungou1_5.populateTransaction.excuteWithETH(
    order,
    receiver
  );
  console.log(result_);
}
main();

// struct BasicOrder {
//     BasicOrderParameters parameters;
//     bytes orderSignature;
//     uint256 buyAmount;
//     uint256 totalRoyaltyFee;
//     uint256 totalPlatformFee;
//     uint256 totalAfterTaxIncome;
//     uint256 totalPayment;
//     uint256 expiryDate;
//     bytes systemSignature;
// }

// struct EIP712Domain {
//     string name;
//     uint256 chainId;
//     address verifyingContract;
// }

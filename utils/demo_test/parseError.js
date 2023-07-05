const { ethers } = require("ethers");
const { makeBigNumber } = require("opensea-js/lib/utils/utils");
require("dotenv").config();

const abi = [
  { inputs: [], stateMutability: "nonpayable", type: "constructor" },
  {
    inputs: [{ internalType: "string", name: "hash", type: "string" }],
    name: "Documents__AlreadyExist",
    type: "error",
  },
  {
    inputs: [{ internalType: "string", name: "hash", type: "string" }],
    name: "Documents__NotHash",
    type: "error",
  },
  {
    inputs: [{ internalType: "address", name: "sender", type: "address" }],
    name: "Documents__NotOwner",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: "string", name: "hash", type: "string" },
    ],
    name: "DocumentHashAdded",
    type: "event",
  },
  {
    inputs: [{ internalType: "string", name: "hash", type: "string" }],
    name: "addDocumentHash",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "string", name: "hash", type: "string" }],
    name: "getDocumentHasheConfirmation",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getOwner",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
];
const provider = new ethers.providers.JsonRpcProvider(
  process.env.ALCHEMY_SEPOLIA_URL
);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
let iface;
async function main() {
  try {
    const contract = new ethers.Contract(
      "0xe6bD6b317E0136Df4E6bBb6329507D3537FbD1Da",
      abi,
      signer
    );
    iface = new ethers.utils.Interface(abi);
    // const errordata =
    //   "0x8f1e19540000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004035373032343665613566616133356366616661623735323537636532636338653963303764323465363138353532386565363361303530656135343262313431";

    // const iface = contract.interface;
    // const selecter = errordata.slice(0, 10);
    // const res = iface.decodeErrorResult(selecter, errordata);
    // const errorName = iface.getError(selecter).name;
    // console.log(errorName);
    // console.log(res.toString());

    // const owner = await contract.callStatic.getOwner();
    // console.log(owner);
    // const re = await contract.callStatic.addDocumentHash(
    //   "570246ea5faa35cfafab75257ce2cc8e9c07d24e6185528ee63a050ea542b141"
    // );
    // return;
    const re = await contract.addDocumentHash(
      "570246ea5faa35cfafab75257ce2cc8e9c07d24e6185528ee63a050ea542b141"
    );
    await re.wait();
  } catch (error) {
    console.log(error.error.error.error.data);
    const errordata = error.error.error.error.data;
    const selecter = errordata.slice(0, 10);
    const res = iface.decodeErrorResult(selecter, errordata);
    const errorName = iface.getError(selecter).name;
    console.log(errorName);
    console.log(res.toString());
  }
}
main();

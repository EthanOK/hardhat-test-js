const Web3 = require("web3");
const web3 = new Web3();
const privateKey =
  "5c95b96f81a27868d71027a7e1ba23f3fa061b3e06280279294c579c8fcda0ed";

const message = web3.utils.utf8ToHex(
  "0xf6896007477ab25a659f87c4f8c5e3baac32547bf305e77aa57743046e10578b"
);

const signature = web3.eth.accounts.sign(message, privateKey);
console.log(signature.signature);

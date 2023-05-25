const Web3 = require("web3");
const web3 = new Web3();

require("dotenv").config();

const privateKey = process.env.PRIVATE_KEY_SIGN;

const message = web3.utils.utf8ToHex(
  "0xf6896007477ab25a659f87c4f8c5e3baac32547bf305e77aa57743046e10578b"
);

const signature = web3.eth.accounts.sign(message, privateKey);
console.log(signature.signature);

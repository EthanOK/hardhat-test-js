const { ethers } = require("ethers");

main();

function main() {
  let sender = "0xC675897Bb91797EaeA7584F025A5533DBB13A000";
  let nonce = 11;
  getAddressCreate(sender, nonce);
}
function getAddressCreate(sender, nonce) {
  // from + nonce
  let address = ethers.utils.getContractAddress({ from: sender, nonce: nonce });
  console.log("Create:" + address);
  return address;
}

const Web3 = require("web3");

const providerRPC = {
  development: "http://127.0.0.1:8545/",
  moonbase: "",
};
const web3 = new Web3(providerRPC.development); // Change to correct network

const account_from = {
  privateKey:
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
  address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
};
const addressTo = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";

const balances = async () => {
  // 4. Fetch balance info
  const balanceFrom = web3.utils.fromWei(
    await web3.eth.getBalance(account_from.address),
    "ether"
  );
  const balanceTo = web3.utils.fromWei(
    await web3.eth.getBalance(addressTo),
    "ether"
  );

  console.log(`The balance of ${account_from.address} is: ${balanceFrom} ETH`);
  console.log(`The balance of ${addressTo} is: ${balanceTo} ETH`);
};
const send = async () => {
  console.log("Transaction Start:");
  console.log(
    `Attempting to send transaction from ${account_from.address} to ${addressTo}`
  );

  const createTransaction = await web3.eth.accounts.signTransaction(
    {
      to: addressTo,
      value: web3.utils.toWei("10", "ether"),
      gas: web3.utils.toHex(21000),
      gasPrice: web3.utils.toHex(web3.utils.toWei("10", "gwei")),
    },
    account_from.privateKey
  );

  const createReceipt = await web3.eth.sendSignedTransaction(
    createTransaction.rawTransaction
  );
  console.log(
    `Transaction successful with hash: ${createReceipt.transactionHash}`
  );
  console.log("Transaction End!");
};
async function main() {
  await balances();
  await send();
  await balances();
}
main();

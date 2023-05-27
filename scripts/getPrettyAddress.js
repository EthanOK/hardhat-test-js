const { ethers } = require("ethers");
var wallet; // 钱包

/* 
- 开头几位字符匹配，我们用`^`符号，例如`^0x000`就会匹配以`0x000`开头的地址。
- 最后几位字符匹配，我们用`$`符号，例如`000$`就会匹配以`000`结尾的地址。
- 中间几位我们不关心，可以利用`.*`通配符，例如`^0x000.*000$`就会匹配任何以`0x000`开头并以`000`结尾的地址。
*/
const regex = /^0x0000.*88$/; // 表达式
var isValid = false;
while (!isValid) {
  wallet = ethers.Wallet.createRandom(); // 随机生成钱包，安全
  isValid = regex.test(wallet.address); // 检验正则表达式
}
// 打印靓号地址与私钥
console.log(`靓号地址：${wallet.address}`);
console.log(`靓号私钥：${wallet.privateKey}`);

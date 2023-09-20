const { BigNumber } = require("ethers");
const Decimal = require("decimal.js");

function caculatePriceBySqrtPriceX96() {
  let sqrtPriceX96_ = "5379665721256550655574226248";
  let sqrtPriceX96 = BigNumber.from(sqrtPriceX96_);
  let sqrtPriceX96_m2 = sqrtPriceX96.mul(sqrtPriceX96).toString();
  let _X_m2_192 = BigNumber.from("2").pow(192).toString();
  // 浮点数计算
  let s = new Decimal(sqrtPriceX96_m2).div(new Decimal(_X_m2_192));
  console.log(1 / s);
  console.log(s);
  nnn(5379665721256550655574226248);
}
function nnn(sqrtPriceX96) {
  let price = (sqrtPriceX96 / 2 ** 96) ** 2;
  console.log(1 / price);
  console.log(price);
}

caculatePriceBySqrtPriceX96();

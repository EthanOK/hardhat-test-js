const ethers = require("ethers");

const abiQuoter = [
  "function quoteExactInputSingle(address tokenIn,address tokenOut,uint24 fee,uint256 amountIn,uint160 sqrtPriceLimitX96) external returns (uint256 amountOut)",
];
const abiPool = [
  "function slot0() external view returns (uint160 sqrtPriceX96,int24,uint16,uint16,uint16,uint8,bool)",
];

const provider = new ethers.providers.JsonRpcProvider("https://0xrpc.io/eth");
const quoter = new ethers.Contract(
  "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",
  abiQuoter,
  provider
);

const POOL_ADDRESS = "0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35";
const USDC_ADDRESS = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const WBTC_ADDRESS = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599";

const pool = new ethers.Contract(POOL_ADDRESS, abiPool, provider);

const USDC = ethers.utils.getAddress(USDC_ADDRESS.toLowerCase());
const WBTC = ethers.utils.getAddress(WBTC_ADDRESS.toLowerCase());

async function getUniswapWBTCPrice() {
  try {
    const amountIn = ethers.utils.parseUnits("1", 8);
    const params = {
      tokenIn: WBTC,
      tokenOut: USDC,
      fee: 3000,
      amountIn: amountIn.toString(),
      sqrtPriceLimitX96: 0,
    };

    const amountOut = await quoter.callStatic.quoteExactInputSingle(
      params.tokenIn,
      params.tokenOut,
      params.fee,
      params.amountIn,
      params.sqrtPriceLimitX96
    );
    const price_wbtc = parseFloat(ethers.utils.formatUnits(amountOut, 6));
    return price_wbtc;
  } catch (_err) {
    console.error(_err);
    console.warn(
      "⚠️ Quoter failed, fallback para slot0(), erro:",
      _err.reason || _err.message
    );
  }
}

async function getUniswapWBTCPriceBySlot0() {
  // fallback via slot0()
  try {
    const { sqrtPriceX96 } = await pool.slot0();
    const sqrtF = parseFloat(sqrtPriceX96.toString()) / 2 ** 96;
    return sqrtF ** 2 * (1e8 / 1e6);
  } catch (err2) {
    console.error("❌ Fallback slot0() falhou:", err2.message);
    return null;
  }
}

getUniswapWBTCPrice().then(
  (price) => {
    console.log("swap price:", price);
  },
  (err) => {
    console.error(err);
  }
);

getUniswapWBTCPriceBySlot0().then(
  (price) => {
    console.log("market price:", price);
  },
  (err) => {
    console.error(err);
  }
);

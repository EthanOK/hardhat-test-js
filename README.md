# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:
verify:

```
npm install @openzeppelin/contracts
npm install @openzeppelin/contracts-upgradeable
npm install dotenv --save
npm install --save-dev @nomiclabs/hardhat-etherscan

```

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js --network goerli
npx hardhat verify --network goerli `contractAddress` `args`
npx hardhat blocknumber --network goerli
npx hardhat check
```

```
Multicall
https://github.com/makerdao/multicall
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Multicall.sol

contract NFT721 is Ownable, SignerRole, IERC721, ERC721Base{}
```

NftExchangeV1 contracts-upgradeable

```
部署顺序：
1. NftExchange_V1_upgradeable.sol
2. ProxyAdmin.sol
3. TransparentUpgradeableProxy.sol (_data is initialize() calldata)
```

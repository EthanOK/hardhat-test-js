// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    constructor(uint256 x) {}

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function f() public payable returns (uint256 x) {
        x = msg.value;
    }

    function getBlockTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }

    function getBlockNumberTime()
        external
        view
        returns (
            address walletAddress,
            string memory name,
            string memory b64Image
        )
    {
        return (walletAddress, "Not Found", "Not Found");
    }

    fallback() external payable {}

    receive() external payable {}
}

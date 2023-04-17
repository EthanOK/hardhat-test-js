// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract encodeTest {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Order {
        address account;
        uint256 amount;
    }

    function encode(
        Order[] calldata orders_,
        uint256[] calldata royaltyFees,
        uint256 endTime
    ) external view returns (bytes memory) {
        EIP712Domain memory domain = EIP712Domain({
            name: "TESTCODE",
            version: "1.0.0",
            chainId: block.chainid,
            verifyingContract: address(this)
        });
        return abi.encode(domain, orders_, royaltyFees, endTime);
    }
}

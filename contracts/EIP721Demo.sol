// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract EIP712Demo is EIP712 {
    enum OrderType {
        ETH_TO_ERC721,
        ETH_TO_ERC1155,
        ERC20_TO_ERC721,
        ERC20_TO_ERC1155,
        ERC721_TO_ERC20,
        ERC1155_TO_ERC20
    }

    // buy it now
    struct BasicOrderParameters {
        OrderType orderType;
        address payable offerer;
        address offerToken;
        uint256 offerTokenId;
        uint256 unitPrice;
        uint256 sellAmount;
        uint256 startTime;
        uint256 endTime;
        address paymentToken;
        uint256 paymentTokenId;
        uint256 salt;
        uint256 royaltyFee;
        uint256 platformFee;
        uint256 afterTaxPrice;
    }
    BasicOrderParameters public parameters;
    bytes32 public constant ORDERSTRUCT_HASH =
        keccak256(
            "BasicOrderParameters(uint8 orderType,address offerer,address offerToken,uint256 offerTokenId,uint256 unitPrice,uint256 sellAmount,uint256 startTime,uint256 endTime,address paymentToken,uint256 paymentTokenId,uint256 salt,uint256 royaltyFee,uint256 platformFee,uint256 afterTaxPrice)"
        );
    bytes32 public hashData;

    constructor() EIP712("Demo", "2") {
        parameters.orderType = OrderType.ETH_TO_ERC721;
        parameters.offerer = payable(
            0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2
        );
        parameters.offerToken = 0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b;
        parameters.offerTokenId = 7;
        parameters.unitPrice = 10000000000000000;
        parameters.sellAmount = 1;
        parameters.startTime = 1684304543;
        parameters.endTime = 1686896535;
        parameters.paymentToken = 0x0000000000000000000000000000000000000000;
        parameters.paymentTokenId = 0;
        parameters.salt = 7;
        parameters.royaltyFee = 250000000000000;
        parameters.platformFee = 250000000000000;
        parameters.afterTaxPrice = 9500000000000000;

        hashData = getHash(parameters);
    }

    function setSalt(uint256 _salt) external {
        parameters.salt = _salt;
        hashData = getHash(parameters);
    }

    function getHash(
        BasicOrderParameters memory orderParams
    ) internal view returns (bytes32 hash) {
        hash = _hashTypedDataV4(
            keccak256(abi.encode(ORDERSTRUCT_HASH, orderParams))
        );
    }

    function verifySign(
        bytes calldata signature
    ) external view returns (address, bool) {
        bytes32 hash = getHash(parameters);

        address signer = ECDSA.recover(hash, signature);
        return (signer, signer == msg.sender);
    }
}

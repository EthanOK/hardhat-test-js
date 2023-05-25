// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract encodeYG {
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

    struct BasicOrder {
        BasicOrderParameters parameters;
        bytes orderSignature;
        uint256 buyAmount;
        uint256 totalRoyaltyFee;
        uint256 totalPlatformFee;
        uint256 totalAfterTaxIncome;
        uint256 totalPayment;
        uint256 expiryDate;
        bytes systemSignature;
    }

    // TODO:remove version
    struct EIP712Domain {
        string name;
        uint256 chainId;
        address verifyingContract;
    }
    BasicOrderParameters parameters;
    EIP712Domain domain;
    BasicOrder order;
    bytes public constant orderSignature =
        hex"000086c8e6da20779da45fd9ca46ba34754c390c2926b41789d4ffef8bddb85e78fcfab4d1ea66d72038f964cd7bd077baffe9e75ab459ba106b2219a0eb78121c";

    constructor() {
        init();
    }

    function init() internal {
        parameters.orderType = OrderType.ETH_TO_ERC721;
        parameters.offerer = payable(
            0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2
        );
        parameters.offerToken = 0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b;
        parameters.offerTokenId = 8;
        parameters.unitPrice = 10000000000000000;
        parameters.sellAmount = 1;
        parameters.startTime = 1684304543;
        parameters.endTime = 1686896535;
        parameters.paymentToken = 0x0000000000000000000000000000000000000000;
        parameters.paymentTokenId = 0;
        parameters.salt = 8;
        parameters.royaltyFee = 250000000000000;
        parameters.platformFee = 250000000000000;
        parameters.afterTaxPrice = 9500000000000000;

        domain.name = "YUNGOU";
        domain.chainId = 5;
        domain.verifyingContract = 0x413E7C5Cc2cD3380b7C32159A1933de7c70f4735;

        order.orderSignature = orderSignature;
        order.buyAmount = 1;
        order.totalRoyaltyFee = 250000000000000;
        order.totalPlatformFee = 250000000000000;
        order.totalAfterTaxIncome = 9500000000000000;
        order.totalPayment = 10000000000000000;
        order.expiryDate = 1686896535;
        order
            .systemSignature = hex"43fb46f4fccc7df07cf21f7b3b811a13026c9c7cd4d9003d422ddba26b38ccb01d1bea6e15135275cdb4a517100c2f801d44334dad5741ee822c624a9c80cc9a1c";
    }

    function encodeBasicOrderParameters()
        external
        view
        returns (
            bytes32 hash_para,
            bytes32 hash_domain_para,
            bytes32 hash_sysyem
        )
    {
        hash_para = keccak256(abi.encode(parameters));
        hash_domain_para = keccak256(abi.encode(domain, parameters));
        hash_sysyem = keccak256(
            abi.encode(
                order.orderSignature,
                order.buyAmount,
                order.totalRoyaltyFee,
                order.totalPlatformFee,
                order.totalAfterTaxIncome,
                order.totalPayment,
                order.expiryDate
            )
        );
    }
}

// 0:
// bytes32: hash_para 0x2b1630017fb732f616365f889ac4090bc9732278a6ff83fb5a7cafc0683bd522
// 1:
// bytes32: hash_domain_para 0x9b0e4afa31f5bcf93711d4475bd9226b23fb1c8084c14ce3414028cd9dabd4f3
// 2:
// bytes32: hash_sysyem 0xdcaf7a4253b15fb29e696cb971699556291eb4d3a5648e8abfcfaa4da6948cf6

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract ExchangeDomainV1 {
    enum AssetType {
        ETH,
        ERC20,
        ERC1155,
        ERC721,
        ERC721Deprecated
    }

    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint256 salt;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* The total quantity the seller wants to sell */
        uint256 sellAmount;
        /* unit price */
        uint256 unitPrice;
        // oeder startTime
        uint256 startTime;
        // oeder endTime
        uint256 endTime;
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    struct Royalty {
        /* contract address */
        address addressNft;
        /* royalty fee value */
        uint256 royaltyFee;
        uint256 sigTime;
    }
}

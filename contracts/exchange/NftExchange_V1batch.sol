// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ExchangeDomainV1 {
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
}

contract NftExchangeV1 is Ownable, ReentrancyGuard, ExchangeDomainV1 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    event Buy(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        uint256 sellAmount,
        uint256 unitPrice,
        address seller,
        address buyToken,
        uint256 buyTokenId,
        address buyer,
        uint256 amount,
        uint256 PriceTotal,
        uint256 royaltyFee
    );

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    uint256 public constant FEE_10000 = 10000;

    address payable public beneficiary;
    address public royaltyFeeSigner;
    uint256 public platformFee;

    constructor(
        address payable _beneficiary,
        address _royaltyFeeSigner,
        uint256 _platformFee
    ) {
        beneficiary = _beneficiary;
        royaltyFeeSigner = _royaltyFeeSigner;
        platformFee = _platformFee;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setRoyaltyFeeSigner(
        address newRoyaltyFeeSigner
    ) external onlyOwner {
        royaltyFeeSigner = newRoyaltyFeeSigner;
    }

    function setPlatformFee(uint256 newPlatformFee) external onlyOwner {
        platformFee = newPlatformFee;
    }

    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint256 amount,
        uint256 endTime,
        uint256 royaltyFee,
        Sig calldata royaltySig
    ) external payable {
        address buyer = _msgSender();
        require(block.timestamp <= endTime, "royalty sig has expired");
        require(amount > 0, "amount should > 0");

        require(
            order.startTime <= block.timestamp &&
                block.timestamp <= order.endTime,
            "order has expired"
        );

        require(
            order.key.sellAsset.assetType == AssetType.ERC721 ||
                order.key.sellAsset.assetType == AssetType.ERC721Deprecated ||
                order.key.sellAsset.assetType == AssetType.ERC1155,
            "sell asset type must NFT"
        );
        require(
            order.key.buyAsset.assetType == AssetType.ETH ||
                order.key.buyAsset.assetType == AssetType.ERC20,
            "buy asset type must ETH or ERC20"
        );

        validateOrderSig(order, sig);

        validateRoyaltyFeeSig(order, royaltyFee, endTime, royaltySig);

        if (
            order.key.sellAsset.assetType == AssetType.ERC721 ||
            order.key.sellAsset.assetType == AssetType.ERC721Deprecated ||
            IERC165(order.key.sellAsset.token).supportsInterface(
                INTERFACE_ID_ERC721
            )
        ) {
            amount = 1;
        } else if (
            order.key.sellAsset.assetType == AssetType.ERC1155 ||
            IERC165(order.key.sellAsset.token).supportsInterface(
                INTERFACE_ID_ERC1155
            )
        ) {
            verifyOrderSales(order.key, order.sellAmount, amount);
        }

        uint256 payPrice = order.unitPrice * amount;

        if (order.key.buyAsset.assetType == AssetType.ETH) {
            require(msg.value >= payPrice, "ETH insufficient");
        } else if (order.key.buyAsset.assetType == AssetType.ERC20) {
            uint256 allowanceAmount = IERC20(order.key.buyAsset.token)
                .allowance(buyer, address(this));
            require(payPrice <= allowanceAmount, "allowance not enough");
        }

        // transfer nft to buyer
        transfer_NftToBuyer(
            order.key.sellAsset.assetType,
            order.key.sellAsset.token,
            order.key.owner,
            buyer,
            order.key.sellAsset.tokenId,
            amount
        );

        // transfer to seller  eth or erc20
        transferBuyToken(
            order.key.buyAsset.assetType,
            order.key.buyAsset.token,
            buyer,
            order.key.owner,
            payPrice,
            royaltyFee
        );

        // emit Exchange(
        //     order.key.sellAsset.token,
        //     order.key.sellAsset.tokenId,
        //     order.key.owner,
        //     order.key.buyAsset.token,
        //     buyerAccount,
        //     amount,
        //     payPrice,
        //     royaltyFee
        // );
    }

    // function batchExchangeERC721(
    //     Order[] calldata orders,
    //     Sig[] calldata sigs,
    //     uint256[] calldata royaltyFees,
    //     uint256 amount,
    //     uint256 sigTime,
    //     Sig calldata royaltySig
    // ) external payable {
    //     address buyerAccount = _msgSender();

    //     require(
    //         amount > 0 &&
    //             orders.length == sigs.length &&
    //             orders.length == royaltyFees.length,
    //         "amount is wrong"
    //     );

    //     // verify orders
    //     for (uint256 i = 0; i < amount; i++) {
    //         require(
    //             orders[i].startTime <= block.timestamp &&
    //                 block.timestamp <= orders[i].endTime,
    //             "order has expired"
    //         );

    //         require(
    //             block.timestamp <= sigTime + sigEffectiveTime,
    //             "royalty sig has expired"
    //         );

    //         require(
    //             orders[i].key.sellAsset.assetType != AssetType.ETH,
    //             "ETH is not supported on sell side"
    //         );
    //         require(
    //             orders[i].key.sellAsset.assetType != AssetType.ERC20,
    //             "ERC20 is not supported on sell side"
    //         );
    //         require(
    //             orders[i].key.sellAsset.assetType ==
    //                 AssetType.ERC721Deprecated ||
    //                 IERC165(orders[i].key.sellAsset.token).supportsInterface(
    //                     INTERFACE_ID_ERC721
    //                 ),
    //             "Not ERC721"
    //         );
    //         validateOrderSig(orders[i], sigs[i]);
    //     }
    //     // verify RoyaltyFeeSig
    //     batchValidateRoyaltyFeeSig(orders, royaltyFees, sigTime, royaltySig);

    //     for (uint256 i = 0; i < amount; i++) {
    //         uint256 payPrice = orders[i].unitPrice;

    //         // 用eth购买
    //         if (orders[i].key.buyAsset.assetType == AssetType.ETH) {
    //             // 验证 msg.value 足量
    //             require(msg.value >= payPrice, "ETH insufficient");
    //         } else if (orders[i].key.buyAsset.assetType == AssetType.ERC20) {
    //             uint256 allowanceAmount = IERC20(orders[i].key.buyAsset.token)
    //                 .allowance(buyerAccount, address(this));
    //             require(payPrice <= allowanceAmount, "allowance not enough");
    //         }

    //         // transfer nft to buyer
    //         transfer_NftToBuyer(
    //             orders[i].key.sellAsset.assetType,
    //             orders[i].key.sellAsset.token,
    //             orders[i].key.owner,
    //             buyerAccount,
    //             orders[i].key.sellAsset.tokenId,
    //             1
    //         );

    //         // transfer to seller  eth or erc20
    //         transferBuyToken(
    //             orders[i].key.buyAsset.assetType,
    //             orders[i].key.buyAsset.token,
    //             buyerAccount,
    //             orders[i].key.owner,
    //             payPrice,
    //             royaltyFees[i]
    //         );

    //         emit Exchange(
    //             orders[i].key.sellAsset.token,
    //             orders[i].key.sellAsset.tokenId,
    //             orders[i].key.owner,
    //             orders[i].key.buyAsset.token,
    //             buyerAccount,
    //             amount,
    //             payPrice,
    //             royaltyFees[i]
    //         );
    //     }
    // }

    function transfer_NftToBuyer(
        AssetType assertType,
        address nftAddress,
        address fromAccount,
        address toAccount,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (assertType == AssetType.ERC721) {
            IERC721(nftAddress).safeTransferFrom(
                fromAccount,
                toAccount,
                tokenId
            );
        } else if (assertType == AssetType.ERC721Deprecated) {
            IERC721(nftAddress).transferFrom(fromAccount, toAccount, tokenId);
        } else if (assertType == AssetType.ERC1155) {
            IERC1155(nftAddress).safeTransferFrom(
                fromAccount,
                toAccount,
                tokenId,
                amount,
                "0x"
            );
        }
    }

    function transferBuyToken(
        AssetType assertType,
        address erc20Address,
        address fromAccount,
        address toAccount,
        uint256 payAmount,
        uint256 royaltyFee
    ) internal {
        uint256 totalFee = ((royaltyFee + platformFee) * payAmount) / FEE_10000;

        uint256 actualPrice = payAmount - totalFee;

        if (assertType == AssetType.ETH) {
            payable(toAccount).transfer(actualPrice);
            payable(beneficiary).transfer(totalFee);
        } else if (assertType == AssetType.ERC20) {
            IERC20(erc20Address).safeTransferFrom(
                fromAccount,
                toAccount,
                actualPrice
            );
            IERC20(erc20Address).safeTransferFrom(
                fromAccount,
                beneficiary,
                totalFee
            );
        }
    }

    function validateOrderSig(
        Order memory order,
        Sig memory sig
    ) internal pure {
        bytes32 hash = keccak256(abi.encode(order)).toEthSignedMessageHash();
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == order.key.owner, "incorrect order signature");
    }

    function validateRoyaltyFeeSig(
        Order memory order,
        uint256 royaltyFee,
        uint256 endTime,
        Sig memory royaltySig
    ) internal view {
        bytes32 hash = keccak256(abi.encode(order, royaltyFee, endTime))
            .toEthSignedMessageHash();
        address signer = ecrecover(
            hash,
            royaltySig.v,
            royaltySig.r,
            royaltySig.s
        );
        require(signer == royaltyFeeSigner, "incorrect royalty fee signature");
    }

    // function batchValidateRoyaltyFeeSig(
    //     Order[] memory orders,
    //     uint256[] memory royaltyFees,
    //     uint256 sigTime,
    //     Sig memory royaltySig
    // ) internal view {
    //     bytes32 hash = keccak256(abi.encode(orders, royaltyFees, sigTime))
    //         .toEthSignedMessageHash();
    //     address signer = ecrecover(
    //         hash,
    //         royaltySig.v,
    //         royaltySig.r,
    //         royaltySig.s
    //     );
    //     require(signer == royaltyFeeSigner, "incorrect royalty fee signature");
    // }

    // only erc1155 call
    function verifyOrderSales(
        OrderKey memory key,
        uint256 sellAmount,
        uint256 amount
    ) internal view {
        uint256 amountOn = IERC1155(key.sellAsset.token).balanceOf(
            key.owner,
            key.sellAsset.tokenId
        );
        require(
            amount <= sellAmount && amount <= amountOn,
            "insufficient Sales"
        );
    }
}

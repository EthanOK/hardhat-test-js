// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ExchangeDomainV1.sol";

contract NftExchangeV1 is Ownable, ExchangeDomainV1 {
    // using UintLibrary for uint256;
    // using StringLibrary for string;
    using ECDSA for bytes32;

    event Exchange(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        address indexed seller,
        address buyToken,
        address buyer,
        uint256 amount,
        uint256 payPrice,
        uint256 royaltyFee
    );

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    // percentage : (royaltyFee + platformFee) / FEE_10000
    uint256 public constant FEE_10000 = 10000;

    address payable public beneficiary;
    address public royaltyFeeSigner;
    uint256 public platformFee;
    uint256 public sigEffectiveTime;

    constructor(
        address payable _beneficiary,
        address _royaltyFeeSigner,
        uint256 _platformFee,
        uint256 _sigEffectiveTime
    ) {
        beneficiary = _beneficiary;
        royaltyFeeSigner = _royaltyFeeSigner;
        platformFee = _platformFee;
        sigEffectiveTime = _sigEffectiveTime;
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

    function setSigEffectiveTime(uint256 _sigEffectiveTime) external onlyOwner {
        sigEffectiveTime = _sigEffectiveTime;
    }

    // 后台再针对order及 order签名进行二次签名
    function exchange(
        Order calldata order,
        Sig calldata sig,
        Royalty calldata royalty,
        uint256 amount,
        uint256 sigTime,
        Sig calldata royaltySig
    ) external payable {
        address buyerAccount = _msgSender();
        require(amount > 0, "amount should > 0");
        require(
            order.key.sellAsset.token == royalty.addressNft,
            "nft contract mismatch"
        );
        require(
            order.startTime <= block.timestamp &&
                block.timestamp <= order.endTime,
            "order has expired"
        );

        require(
            block.timestamp <= sigTime + sigEffectiveTime,
            "royalty sig has expired"
        );

        require(
            order.key.sellAsset.assetType != AssetType.ETH,
            "ETH is not supported on sell side"
        );
        require(
            order.key.sellAsset.assetType != AssetType.ERC20,
            "ERC20 is not supported on sell side"
        );

        validateOrderSig(order, sig);

        validateRoyaltyFeeSig(sig, royalty, amount, sigTime, royaltySig);

        if (
            order.key.sellAsset.assetType == AssetType.ERC721Deprecated ||
            IERC165(order.key.sellAsset.token).supportsInterface(
                INTERFACE_ID_ERC721
            )
        ) {
            // is 721
            amount = 1;
        } else if (
            IERC165(order.key.sellAsset.token).supportsInterface(
                INTERFACE_ID_ERC1155
            )
        ) {
            // is 1155
            // if 1155 验证购买数量
            verifyOrderSales(order.key, order.sellAmount, amount);
        }

        uint256 payPrice = order.unitPrice * amount;

        // 用eth购买
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            // 验证 msg.value 足量
            require(msg.value >= payPrice, "ETH insufficient");
        } else if (order.key.buyAsset.assetType == AssetType.ERC20) {
            uint256 allowanceAmount = IERC20(order.key.buyAsset.token)
                .allowance(buyerAccount, address(this));
            require(payPrice <= allowanceAmount, "allowance not enough");
        }

        // transfer nft to buyer
        transfer_NftToBuyer(
            order.key.sellAsset.assetType,
            order.key.sellAsset.token,
            order.key.owner,
            buyerAccount,
            order.key.sellAsset.tokenId,
            amount
        );

        // transfer to seller  eth or erc20
        transferEthOrErc20ToSellerAndPlant(
            order.key.buyAsset.assetType,
            order.key.buyAsset.token,
            buyerAccount,
            order.key.owner,
            payPrice,
            royalty.royaltyFee
        );

        emit Exchange(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            order.key.owner,
            order.key.buyAsset.token,
            buyerAccount,
            amount,
            payPrice,
            royalty.royaltyFee
        );
    }

    function batchExchangeERC721(
        Order[] calldata orders,
        Sig[] calldata sigs,
        Royalty[] calldata royaltys,
        uint256 amount,
        uint256 sigTime,
        Sig calldata royaltySig
    ) external payable {
        address buyerAccount = _msgSender();

        require(
            amount > 0 &&
                orders.length == sigs.length &&
                orders.length == royaltys.length,
            "amount is wrong"
        );

        // verify orders
        for (uint256 i = 0; i < amount; i++) {
            require(
                orders[i].key.sellAsset.token == royaltys[i].addressNft,
                "nft contract mismatch"
            );
            require(
                orders[i].startTime <= block.timestamp &&
                    block.timestamp <= orders[i].endTime,
                "order has expired"
            );

            require(
                block.timestamp <= sigTime + sigEffectiveTime,
                "royalty sig has expired"
            );

            require(
                orders[i].key.sellAsset.assetType != AssetType.ETH,
                "ETH is not supported on sell side"
            );
            require(
                orders[i].key.sellAsset.assetType != AssetType.ERC20,
                "ERC20 is not supported on sell side"
            );
            require(
                orders[i].key.sellAsset.assetType ==
                    AssetType.ERC721Deprecated ||
                    IERC165(orders[i].key.sellAsset.token).supportsInterface(
                        INTERFACE_ID_ERC721
                    ),
                "Not ERC721"
            );
            validateOrderSig(orders[i], sigs[i]);
        }
        // verify RoyaltyFeeSig
        batchValidateRoyaltyFeeSig(sigs, royaltys, amount, sigTime, royaltySig);

        for (uint256 i = 0; i < amount; i++) {
            uint256 payPrice = orders[i].unitPrice;

            // 用eth购买
            if (orders[i].key.buyAsset.assetType == AssetType.ETH) {
                // 验证 msg.value 足量
                require(msg.value >= payPrice, "ETH insufficient");
            } else if (orders[i].key.buyAsset.assetType == AssetType.ERC20) {
                uint256 allowanceAmount = IERC20(orders[i].key.buyAsset.token)
                    .allowance(buyerAccount, address(this));
                require(payPrice <= allowanceAmount, "allowance not enough");
            }

            // transfer nft to buyer
            transfer_NftToBuyer(
                orders[i].key.sellAsset.assetType,
                orders[i].key.sellAsset.token,
                orders[i].key.owner,
                buyerAccount,
                orders[i].key.sellAsset.tokenId,
                1
            );

            // transfer to seller  eth or erc20
            transferEthOrErc20ToSellerAndPlant(
                orders[i].key.buyAsset.assetType,
                orders[i].key.buyAsset.token,
                buyerAccount,
                orders[i].key.owner,
                payPrice,
                royaltys[i].royaltyFee
            );

            emit Exchange(
                orders[i].key.sellAsset.token,
                orders[i].key.sellAsset.tokenId,
                orders[i].key.owner,
                orders[i].key.buyAsset.token,
                buyerAccount,
                amount,
                payPrice,
                royaltys[i].royaltyFee
            );
        }
    }

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

    function transferEthOrErc20ToSellerAndPlant(
        AssetType assertType,
        address erc20Address,
        address fromAccount,
        address toAccount,
        uint256 payAmount,
        uint256 royaltyFee
    ) internal {
        uint256 totalFee = royaltyFee + platformFee;
        uint256 amountFee = (payAmount * totalFee) / FEE_10000;
        uint256 amountOfSeller = payAmount - amountFee;

        if (assertType == AssetType.ETH) {
            payable(toAccount).transfer(amountOfSeller);
            payable(beneficiary).transfer(amountFee);
        } else if (assertType == AssetType.ERC20) {
            IERC20(erc20Address).transferFrom(
                fromAccount,
                toAccount,
                amountOfSeller
            );
            IERC20(erc20Address).transferFrom(
                fromAccount,
                toAccount,
                amountOfSeller
            );
            IERC20(erc20Address).transferFrom(
                fromAccount,
                beneficiary,
                amountFee
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
        Sig memory sig,
        Royalty memory royalty,
        uint256 amount,
        uint256 sigTime,
        Sig memory royaltySig
    ) internal view {
        bytes32 hash = keccak256(abi.encode(sig, royalty, amount, sigTime))
            .toEthSignedMessageHash();
        address signer = ecrecover(
            hash,
            royaltySig.v,
            royaltySig.r,
            royaltySig.s
        );
        require(signer == royaltyFeeSigner, "incorrect royalty fee signature");
    }

    function batchValidateRoyaltyFeeSig(
        Sig[] memory sigs,
        Royalty[] memory royaltys,
        uint256 amount,
        uint256 sigTime,
        Sig memory royaltySig
    ) internal view {
        bytes32 hash = keccak256(abi.encode(sigs, royaltys, amount, sigTime))
            .toEthSignedMessageHash();
        address signer = ecrecover(
            hash,
            royaltySig.v,
            royaltySig.r,
            royaltySig.s
        );
        require(signer == royaltyFeeSigner, "incorrect royalty fee signature");
    }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../lib/utils/StringLibrary.sol";
import "../lib/utils/BytesLibrary.sol";

import "./ExchangeDomainV1.sol";

contract NftExchangeV1 is Ownable, ExchangeDomainV1 {
    using UintLibrary for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    event Buy(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        uint256 sellValue,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 buyValue,
        address buyer,
        uint256 amount,
        uint256 salt
    );

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    address payable public beneficiary;
    address public royaltyFeeSigner;
    uint256 public platformFee;
    uint256 public sigEffectiveTime = 10 minutes;

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

    function setSigEffectiveTime(uint256 _sigEffectiveTime) external onlyOwner {
        sigEffectiveTime = _sigEffectiveTime;
    }

    // 后台再针对order及 order签名进行二次签名
    function exchange(
        Order calldata order,
        Sig calldata sig,
        Royalty calldata royalty,
        uint256 amount,
        Sig calldata royaltySig
    ) external payable {
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
            block.timestamp <= royalty.sigTime + sigEffectiveTime,
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
        // 验证订单签名
        validateOrderSig(order, sig);
        // 验证 版权手续费 签名(将订单签名再次打包由系统签名，以此来判定订单是否失效)

        validateRoyaltyFeeSig(royalty, sig, amount, royaltySig);

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
            payable(msg.sender).transfer(msg.value - payPrice);
        }
        // transfer nft
        transfer_NftToBuyer(
            order.key.sellAsset.assetType,
            order.key.sellAsset.token,
            order.key.owner,
            msg.sender,
            order.key.sellAsset.tokenId,
            amount
        );
        // transfer eth or erc20
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

    function validateOrderSig(
        Order memory order,
        Sig memory sig
    ) internal pure {
        require(
            prepareMessage(order).recover(sig.v, sig.r, sig.s) ==
                order.key.owner,
            "incorrect signature"
        );
    }

    function validateRoyaltyFeeSig(
        Royalty memory royalty,
        Sig memory sig,
        uint256 amount,
        Sig memory royaltySig
    ) internal view {
        require(
            prepareRoyaltyFeeMessage(royalty, sig, amount).recover(
                royaltySig.v,
                royaltySig.r,
                royaltySig.s
            ) == royaltyFeeSigner,
            "incorrect royalty fee signature"
        );
    }

    function prepareRoyaltyFeeMessage(
        Royalty memory royalty,
        Sig memory sig,
        uint256 amount
    ) public pure returns (string memory) {
        return keccak256(abi.encode(royalty, sig, amount)).toString();
    }

    function prepareMessage(
        Order memory order
    ) public pure returns (string memory) {
        return keccak256(abi.encode(order)).toString();
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

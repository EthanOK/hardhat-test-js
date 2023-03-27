// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface TransferProxy {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract ExchangeDomain {
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
        uint256 sellAmount;
        uint256 unitPrice;
        uint256 startTime;
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

contract NftExchangeYLD is Ownable, ReentrancyGuard, ExchangeDomain {
    using ECDSA for bytes32;

    event Buy(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        uint256 sellAmount,
        uint256 unitPrice,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        address buyer,
        uint256 amount,
        uint256 PriceTotal,
        uint256 royaltyFee
    );
    uint256 public constant FEE_10000 = 10000;

    address payable public beneficiary;

    TransferProxy public transferProxy;
    address public royaltyFeeSigner;

    uint256 public platformFee;
    bool public verifyFeesig;

    bytes32 public orderHash;
    bytes32 public royaltyFeeHash;

    constructor() {
        transferProxy = TransferProxy(
            0x378b43412b8f547341c6Ae9F6ddec09F966D4526
        );
        platformFee = 250;
        beneficiary = payable(0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2);
        royaltyFeeSigner = 0xa002d00E2Db3Aa0a8a3f0bD23Affda03a694D06A;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setRoyaltyFeeSigner(
        address newRoyaltyFeeSigner
    ) external onlyOwner {
        royaltyFeeSigner = newRoyaltyFeeSigner;
    }

    function setVerifyFeersig(bool _verifyFeesig) external onlyOwner {
        verifyFeesig = _verifyFeesig;
    }

    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint256 amount,
        uint256 endTime,
        uint256 royaltyFee,
        Sig calldata royaltySig
    ) external payable nonReentrant {
        require(block.timestamp <= endTime, "Time expired");
        require(
            order.key.sellAsset.assetType != AssetType.ETH,
            "ETH is not supported on sell"
        );
        if (order.key.sellAsset.assetType == AssetType.ERC721) {
            amount = 1;
        }
        address seller = order.key.owner;
        address payable buyer = payable(msg.sender);

        orderHash = keccak256(abi.encode(order));
        royaltyFeeHash = keccak256(abi.encode(order, royaltyFee, endTime));

        validateOrderSig(order, sig);

        if (verifyFeesig) {
            validateBuyerFeeSig(order, royaltyFee, endTime, royaltySig);
        }

        uint256 priceTotal = order.unitPrice * amount;

        require(msg.value >= priceTotal, "you should add eth");

        // 将NFT从出售者转到购买者
        transferProxy.erc721safeTransferFrom(
            IERC721(order.key.sellAsset.token),
            seller,
            buyer,
            order.key.sellAsset.tokenId
        );

        // 购买者支付
        // 收手续费

        uint256 fee = ((royaltyFee + platformFee) * priceTotal) / 10000;
        uint256 actualPrice = priceTotal - fee;
        payable(seller).transfer(actualPrice);
        payable(beneficiary).transfer(fee);
        emitBuy(order, amount, buyer, priceTotal, royaltyFee);
    }

    function validateOrderSig(Order memory order, Sig memory sig) private pure {
        bytes32 hash = keccak256(abi.encode(order)).toEthSignedMessageHash();
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == order.key.owner, "incorrect order signature");
    }

    function validateBuyerFeeSig(
        Order memory order,
        uint256 royaltyFee,
        uint256 endTime,
        Sig memory sig
    ) private view {
        bytes32 hash = keccak256(abi.encode(order, royaltyFee, endTime))
            .toEthSignedMessageHash();
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == royaltyFeeSigner, "incorrect buyer fee signature");
    }

    function emitBuy(
        Order memory order,
        uint256 amount,
        address buyer,
        uint256 priceTotal,
        uint256 royaltyFee
    ) internal {
        emit Buy(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            order.sellAmount,
            order.unitPrice,
            order.key.owner,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId,
            buyer,
            amount,
            priceTotal,
            royaltyFee
        );
    }

    function withdraw(address account) external onlyOwner {
        payable(account).transfer(address(this).balance);
    }
}

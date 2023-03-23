// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling */
        uint256 sellerFee;
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

contract NftExchange is Ownable, ExchangeDomain {
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

    address payable public beneficiary;
    address public buyerFeeSigner;
    TransferProxy public transferProxy;
    bool public verifyFersig;
    bytes32 public orderHash;
    bytes32 public buyerFeeHash;

    constructor() {
        transferProxy = TransferProxy(
            0x378b43412b8f547341c6Ae9F6ddec09F966D4526
        );

        beneficiary = payable(0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2);
        buyerFeeSigner = 0xa002d00E2Db3Aa0a8a3f0bD23Affda03a694D06A;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }

    function setVerifyFersig(bool _verifyFersig) external onlyOwner {
        verifyFersig = _verifyFersig;
    }

    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint256 buyerFee,
        Sig calldata buyerFeeSig,
        uint256 amount,
        address buyer
    ) external payable {
        amount = 1;
        orderHash = keccak256(abi.encode(order));
        buyerFeeHash = keccak256(abi.encode(order, buyerFee));

        validateOrderSig(order, sig);
        require(
            order.key.sellAsset.assetType == AssetType.ERC721,
            "Must ERC721"
        );

        if (verifyFersig) {
            validateBuyerFeeSig(order, buyerFee, buyerFeeSig);
        }

        uint256 price = order.selling * amount;
        // 收买家手续费
        uint256 buyerfee = (price * buyerFee) / 10000;
        require(msg.value >= price + buyerfee, "you should add eth");

        // 不支持出售eth
        require(
            order.key.sellAsset.assetType != AssetType.ETH,
            "ETH is not supported on sell side"
        );

        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }

        // 将NFT从出售者转到购买者
        transferProxy.erc721safeTransferFrom(
            IERC721(order.key.sellAsset.token),
            order.key.owner,
            buyer,
            order.key.sellAsset.tokenId
        );

        // 购买者支付token给出售者
        // 收卖家手续费
        uint256 sellfee = (price * order.sellerFee) / 10000;
        uint256 realsellerget = price - sellfee;
        payable(order.key.owner).transfer(realsellerget);
        payable(beneficiary).transfer(sellfee + buyerfee);
        emitBuy(order, amount, buyer);
    }

    function validateOrderSig(Order memory order, Sig memory sig) public pure {
        bytes32 hash = keccak256(abi.encode(order));
        hash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == order.key.owner, "incorrect order signature");
    }

    function validateBuyerFeeSig(
        Order memory order,
        uint256 buyerFee,
        Sig memory sig
    ) public view {
        bytes32 hash = keccak256(abi.encode(order, buyerFee));
        hash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == buyerFeeSigner, "incorrect buyer fee signature");
    }

    function emitBuy(
        Order memory order,
        uint256 amount,
        address buyer
    ) internal {
        emit Buy(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            order.selling,
            order.key.owner,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId,
            order.buying,
            buyer,
            amount,
            order.key.salt
        );
    }
}

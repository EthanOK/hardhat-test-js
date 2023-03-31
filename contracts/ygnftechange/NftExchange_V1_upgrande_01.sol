// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

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
        /* The quantity the seller wants to sell */
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

    // Multi Call
    struct Call {
        address target;
        bytes callData;
    }

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
        uint256 payPrice,
        uint256 royaltyFee
    );
}

contract NftExchangeV1Upgradeable01 is
    ExchangeDomainV1,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    uint256 public constant FEE_10000 = 10000;

    address payable public beneficiary;
    address public royaltyFeeSigner;
    uint256 public platformFee;

    constructor() {
        // _disableInitializers();
    }

    function initialize(
        address payable _beneficiary,
        address _royaltyFeeSigner,
        uint256 _platformFee,
        address _owner,
        address _operator
    ) public initializer {
        beneficiary = _beneficiary;
        royaltyFeeSigner = _royaltyFeeSigner;
        platformFee = _platformFee;

        __ReentrancyGuard_init();
        __Pausable_init();

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function setBeneficiary(
        address payable newBeneficiary
    ) external onlyRole(OWNER_ROLE) {
        beneficiary = newBeneficiary;
    }

    function setRoyaltyFeeSigner(
        address newRoyaltyFeeSigner
    ) external onlyRole(OWNER_ROLE) {
        royaltyFeeSigner = newRoyaltyFeeSigner;
    }

    function setPlatformFee(
        uint256 newPlatformFee
    ) external onlyRole(OWNER_ROLE) {
        platformFee = newPlatformFee;
    }

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    // nft exchange
    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint256 amount,
        uint256 endTime,
        uint256 royaltyFee,
        Sig calldata royaltySig
    ) external payable whenNotPaused nonReentrant {
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
        transferNftToBuyer(
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
            payPrice,
            royaltyFee
        );
    }

    function transferNftToBuyer(
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
        bytes32 hash = keccak256(abi.encode(order));
        hash = toEthSignedMessageHash(hash);
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == order.key.owner, "incorrect order signature");
    }

    function validateRoyaltyFeeSig(
        Order memory order,
        uint256 royaltyFee,
        uint256 endTime,
        Sig memory royaltySig
    ) internal view {
        bytes32 hash = keccak256(abi.encode(order, royaltyFee, endTime));
        hash = toEthSignedMessageHash(hash);
        address signer = ecrecover(
            hash,
            royaltySig.v,
            royaltySig.r,
            royaltySig.s
        );
        require(signer == royaltyFeeSigner, "incorrect royalty fee signature");
    }

    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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

    // withdraw ether
    function withdraw(address account) external onlyRole(OWNER_ROLE) {
        payable(account).transfer(address(this).balance);
    }

    // Multi Static Call
    function aggregateStaticCall(
        Call[] calldata calls
    )
        external
        view
        onlyRole(OPERATOR_ROLE)
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new bytes[](calls.length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            bool success;
            call = calls[i];
            (success, returnData[i]) = call.target.staticcall(call.callData);
            require(success, "Multicall3: call failed");
            unchecked {
                ++i;
            }
        }
    }

    // validate signature onlyRole(OPERATOR_ROLE)
    function validateSignature(
        bytes32 hash,
        Sig calldata sig,
        address signer
    ) external view onlyRole(OPERATOR_ROLE) returns (bool) {
        hash = toEthSignedMessageHash(hash);
        address signer_ = ecrecover(hash, sig.v, sig.r, sig.s);
        return signer == signer_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/math/SafeMath.sol";
import "../lib/interface/IERC1155.sol";
import "../lib/utils/StringLibrary.sol";
import "../lib/utils/BytesLibrary.sol";
import "../lib/contracts/ERC165.sol";
import "./OwnableOperatorRole.sol";
import "./ERC20TransferProxy.sol";
import "./TransferProxy.sol";
import "./ExchangeOrdersHolder.sol";
import "./ExchangeDomain.sol";
import "./ExchangeState.sol";
import "./TransferProxyForDeprecated.sol";

import "../lib/contracts/HasSecondarySaleFees.sol";
import "../lib/utils/Ownable.sol";

contract NftExchange is Ownable, ExchangeDomain {
    using SafeMath for uint256;
    using UintLibrary for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    enum FeeSide {
        NONE,
        SELL,
        BUY
    }

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

    event Cancel(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 salt
    );

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    address payable public beneficiary;
    address public buyerFeeSigner;

    TransferProxy public transferProxy;
    TransferProxyForDeprecated public transferProxyForDeprecated;
    ERC20TransferProxy public erc20TransferProxy;
    ExchangeState public state;
    ExchangeOrdersHolder public ordersHolder;

    constructor(
        TransferProxy _transferProxy,
        TransferProxyForDeprecated _transferProxyForDeprecated,
        ERC20TransferProxy _erc20TransferProxy,
        ExchangeState _state,
        ExchangeOrdersHolder _ordersHolder,
        address payable _beneficiary,
        address _buyerFeeSigner
    ) {
        transferProxy = _transferProxy;
        transferProxyForDeprecated = _transferProxyForDeprecated;
        erc20TransferProxy = _erc20TransferProxy;
        state = _state;
        ordersHolder = _ordersHolder;
        beneficiary = _beneficiary;
        buyerFeeSigner = _buyerFeeSigner;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }

    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint256 buyerFee,
        Sig calldata buyerFeeSig,
        uint256 amount,
        address buyer
    ) external payable {
        // 验证订单签名
        validateOrderSig(order, sig);
        // 验证 购买手续费 签名
        validateBuyerFeeSig(order, buyerFee, buyerFeeSig);
        //
        uint256 paying = order.buying.mul(amount).div(order.selling);
        // 验证购买数量与库存
        verifyOpenAndModifyOrderState(order.key, order.selling, amount);
        // 不支持出售eth
        require(
            order.key.sellAsset.assetType != AssetType.ETH,
            "ETH is not supported on sell side"
        );
        // 用eth购买
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            // 验证 msg.value 足量
            validateEthTransfer(paying, buyerFee);
        }

        FeeSide feeSide = getFeeSide(
            order.key.sellAsset.assetType,
            order.key.buyAsset.assetType
        );
        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }
        /* SELL = accept, BUY = buy */
        // 将NFT从出售者转到购买者
        transferWithFeesPossibility(
            order.key.sellAsset,
            amount,
            order.key.owner,
            buyer,
            feeSide == FeeSide.SELL,
            buyerFee,
            order.sellerFee,
            order.key.buyAsset
        );

        // 购买者支付token给出售者
        transferWithFeesPossibility(
            order.key.buyAsset,
            paying,
            msg.sender,
            order.key.owner,
            feeSide == FeeSide.BUY,
            order.sellerFee,
            buyerFee,
            order.key.sellAsset
        );
        emitBuy(order, amount, buyer);
    }

    function validateEthTransfer(
        uint256 value,
        uint256 buyerFee
    ) internal view {
        uint256 buyerFeeValue = value.bp(buyerFee);
        require(msg.value == value + buyerFeeValue, "msg.value is incorrect");
    }

    function cancel(OrderKey calldata key) external {
        require(key.owner == msg.sender, "not an owner");
        state.setCompleted(key, UINT256_MAX);
        emit Cancel(
            key.sellAsset.token,
            key.sellAsset.tokenId,
            msg.sender,
            key.buyAsset.token,
            key.buyAsset.tokenId,
            key.salt
        );
    }

    function validateOrderSig(
        Order memory order,
        Sig memory sig
    ) internal view {
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            require(ordersHolder.exists(order), "incorrect signature");
        } else {
            require(
                prepareMessage(order).recover(sig.v, sig.r, sig.s) ==
                    order.key.owner,
                "incorrect signature"
            );
        }
    }

    function validateBuyerFeeSig(
        Order memory order,
        uint256 buyerFee,
        Sig memory sig
    ) internal view {
        require(
            prepareBuyerFeeMessage(order, buyerFee).recover(
                sig.v,
                sig.r,
                sig.s
            ) == buyerFeeSigner,
            "incorrect buyer fee signature"
        );
    }

    function prepareBuyerFeeMessage(
        Order memory order,
        uint256 fee
    ) public pure returns (string memory) {
        return keccak256(abi.encode(order, fee)).toString();
    }

    function prepareMessage(
        Order memory order
    ) public pure returns (string memory) {
        return keccak256(abi.encode(order)).toString();
    }

    function transferWithFeesPossibility(
        Asset memory firstType,
        uint256 value,
        address from,
        address to,
        bool hasFee,
        uint256 sellerFee,
        uint256 buyerFee,
        Asset memory secondType
    ) internal {
        if (!hasFee) {
            transfer(firstType, value, from, to);
        } else {
            transferWithFees(
                firstType,
                value,
                from,
                to,
                sellerFee,
                buyerFee,
                secondType
            );
        }
    }

    function transfer(
        Asset memory asset,
        uint256 value,
        address from,
        address to
    ) internal {
        if (asset.assetType == AssetType.ETH) {
            address payable toPayable = payable(to);
            toPayable.transfer(value);
        } else if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenId == 0, "tokenId  be 0");
            erc20TransferProxy.erc20safeTransferFrom(
                IERC20(asset.token),
                from,
                to,
                value
            );
        } else if (asset.assetType == AssetType.ERC721) {
            require(value == 1, "value  be 1 for ERC-721");
            transferProxy.erc721safeTransferFrom(
                IERC721(asset.token),
                from,
                to,
                asset.tokenId
            );
        } else if (asset.assetType == AssetType.ERC721Deprecated) {
            require(value == 1, "value  be 1 for ERC-721");
            transferProxyForDeprecated.erc721TransferFrom(
                IERC721(asset.token),
                from,
                to,
                asset.tokenId
            );
        } else {
            transferProxy.erc1155safeTransferFrom(
                IERC1155(asset.token),
                from,
                to,
                asset.tokenId,
                value,
                ""
            );
        }
    }

    function transferWithFees(
        Asset memory firstType,
        uint256 value,
        address from,
        address to,
        uint256 sellerFee,
        uint256 buyerFee,
        Asset memory secondType
    ) internal {
        // 手续费 transfer to Beneficiary account
        uint256 restValue = transferFeeToBeneficiary(
            firstType,
            from,
            value,
            sellerFee,
            buyerFee
        );
        // 有二次销售费用
        if (
            (secondType.assetType == AssetType.ERC1155 &&
                IERC1155(secondType.token).supportsInterface(
                    _INTERFACE_ID_FEES
                )) ||
            ((secondType.assetType == AssetType.ERC721 ||
                secondType.assetType == AssetType.ERC721Deprecated) &&
                IERC721(secondType.token).supportsInterface(_INTERFACE_ID_FEES))
        ) {
            HasSecondarySaleFees withFees = HasSecondarySaleFees(
                secondType.token
            );
            address payable[] memory recipients = withFees.getFeeRecipients(
                secondType.tokenId
            );
            uint256[] memory fees = withFees.getFeeBps(secondType.tokenId);
            require(fees.length == recipients.length);
            for (uint256 i = 0; i < fees.length; i++) {
                (uint256 newRestValue, uint256 current) = subFeeInBp(
                    restValue,
                    value,
                    fees[i]
                );
                restValue = newRestValue;
                transfer(firstType, current, from, recipients[i]);
            }
        }

        address payable toPayable = payable(to);
        transfer(firstType, restValue, from, toPayable);
    }

    function transferFeeToBeneficiary(
        Asset memory asset,
        address from,
        uint256 total,
        uint256 sellerFee,
        uint256 buyerFee
    ) internal returns (uint256) {
        (uint256 restValue, uint256 sellerFeeValue) = subFeeInBp(
            total,
            total,
            sellerFee
        );
        uint256 buyerFeeValue = total.bp(buyerFee);
        uint256 beneficiaryFee = buyerFeeValue.add(sellerFeeValue);
        if (beneficiaryFee > 0) {
            transfer(asset, beneficiaryFee, from, beneficiary);
        }
        return restValue;
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

    function subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(
        uint256 value,
        uint256 fee
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function verifyOpenAndModifyOrderState(
        OrderKey memory key,
        uint256 selling,
        uint256 amount
    ) internal {
        uint256 completed = state.getCompleted(key);
        uint256 newCompleted = completed.add(amount);
        require(
            newCompleted <= selling,
            "not enough stock of order for buying"
        );
        state.setCompleted(key, newCompleted);
    }

    function getFeeSide(
        AssetType sellType,
        AssetType buyType
    ) internal pure returns (FeeSide) {
        if (
            (sellType == AssetType.ERC721 ||
                sellType == AssetType.ERC721Deprecated) &&
            (buyType == AssetType.ERC721 ||
                buyType == AssetType.ERC721Deprecated)
        ) {
            return FeeSide.NONE;
        }
        if (uint256(sellType) > uint256(buyType)) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }
}

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

import "../lib/utils/Ownable.sol";

contract NftExchange is Ownable, ExchangeDomain {
    using SafeMath for uint256;
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

    event Cancel(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 salt
    );

    // interface HasSecondarySaleFees
    // bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    address payable public beneficiary;
    address public royaltyFeeSigner;
    uint256 public platformFee;

    TransferProxy public transferProxy;
    TransferProxyForDeprecated public transferProxyForDeprecated;
    ERC20TransferProxy public erc20TransferProxy;
    ExchangeState public state;
    ExchangeOrdersHolder public ordersHolder;

    constructor(
        TransferProxy _transferProxy,
        TransferProxyForDeprecated _transferProxyForDeprecated,
        ERC20TransferProxy _erc20TransferProxy,
        // ExchangeState _state,
        // ExchangeOrdersHolder _ordersHolder,
        address payable _beneficiary,
        address _royaltyFeeSigner,
        uint256 _platformFee
    ) {
        transferProxy = _transferProxy;
        transferProxyForDeprecated = _transferProxyForDeprecated;
        erc20TransferProxy = _erc20TransferProxy;
        // state = _state;
        // ordersHolder = _ordersHolder;
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

    // 后台再针对order及 order签名进行二次签名
    function exchange(
        Order calldata order,
        Sig calldata sig,
        Royalty calldata royalty,
        Sig calldata royaltySig,
        uint256 amount,
        address buyer
    ) external payable {
        require(
            order.key.sellAsset.token == royalty.addressNft,
            "nft contract mismatch"
        );
        require(
            order.startTime <= block.timestamp &&
                block.timestamp <= order.endTime,
            "order has expired"
        );
        // 时间限制 def = 3min
        require(
            block.timestamp <= royalty.sigTime + 180,
            "royalty sig has expired"
        );
        // 验证订单签名
        validateOrderSig(order, sig);
        // 验证 版权手续费 签名(将订单签名再次打包由系统签名，以此来判定订单是否失效)

        validateRoyaltyFeeSig(royalty, sig, royaltySig);

        //
        // uint256 paying = order.buying.mul(amount).div(order.selling);
        uint256 payPrice = (order.sellPrice * amount) / order.sellAmount;
        // 验证购买数量与库存
        verifyOpenAndModifyOrderState(order.key, order.sellAmount, amount);
        // 不支持出售eth
        require(
            order.key.sellAsset.assetType != AssetType.ETH,
            "ETH is not supported on sell side"
        );
        // 用eth购买
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            // 验证 msg.value 足量
            require(msg.value >= payPrice, "msg.value is incorrect");
        }

        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }
        /* SELL = accept, BUY = buy */
        // 将NFT从出售者转到购买者
        // transferWithFeesPossibility(
        //     order.key.sellAsset,
        //     amount,
        //     order.key.owner,
        //     buyer,
        //     feeSide == FeeSide.SELL,
        //     buyerFee,
        //     order.sellerFee,
        //     order.key.buyAsset
        // );

        // 购买者支付token给出售者
        // transferWithFeesPossibility(
        //     order.key.buyAsset,
        //     paying,
        //     msg.sender,
        //     order.key.owner,
        //     feeSide == FeeSide.BUY,
        //     order.sellerFee,
        //     buyerFee,
        //     order.key.sellAsset
        // );
        emitBuy(order, amount, buyer);
    }

    function validateEthTransfer(
        uint256 value,
        uint256 buyerFee
    ) internal view {
        uint256 buyerFeeValue = value.bp(buyerFee);
        require(msg.value == value + buyerFeeValue, "msg.value is incorrect");
    }

    // 下架tokenId(之前的签名失效)
    // function cancel(Order[] calldata orders, Sig[] calldata sigs) external {
    //     require(orders.length == sigs.length, "length");
    //     uint256 len = orders.length;
    //     for (uint256 i = 0; i < len; i++) {
    //         require(orders[i].key.owner == msg.sender, "not an owner");
    //         validateOrderSig(orders[i], sigs[i]);
    //         require(!state.getInvalidOrders(orders[i]), "Mismatched length");
    //     }
    //     state.setInvalidOrders(orders);

    //     // orders[len - 1] 最新订单价格
    //     emit Cancel(
    //         orders[len - 1].key.sellAsset.token,
    //         orders[len - 1].key.sellAsset.tokenId,
    //         msg.sender,
    //         orders[len - 1].key.buyAsset.token,
    //         orders[len - 1].key.buyAsset.tokenId,
    //         orders[len - 1].key.salt
    //     );
    // }

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
        Sig memory royaltySig
    ) internal view {
        require(
            prepareRoyaltyFeeMessage(royalty, sig).recover(
                royaltySig.v,
                royaltySig.r,
                royaltySig.s
            ) == royaltyFeeSigner,
            "incorrect royalty fee signature"
        );
    }

    function prepareRoyaltyFeeMessage(
        Royalty memory royalty,
        Sig memory sig
    ) public pure returns (string memory) {
        return keccak256(abi.encode(royalty, sig)).toString();
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
            order.sellAmount,
            order.key.owner,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId,
            order.sellPrice,
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
}

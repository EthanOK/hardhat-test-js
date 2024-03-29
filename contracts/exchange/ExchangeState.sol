// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ExchangeDomain.sol";
import "./OwnableOperatorRole.sol";

contract ExchangeState is OwnableOperatorRole {
    // keccak256(OrderKey) => completed
    //
    mapping(bytes32 => uint256) public completed;
    //V1 记录失效订单
    mapping(bytes32 => bool) internal invalidOrders;

    function getCompleted(
        ExchangeDomain.OrderKey calldata key
    ) external view returns (uint256) {
        return completed[getCompletedKey(key)];
    }

    function getInvalidOrders(
        ExchangeDomain.Order calldata order
    ) external view returns (bool) {
        return invalidOrders[prepareKey(order)];
    }

    function setCompleted(
        ExchangeDomain.OrderKey calldata key,
        uint256 newCompleted
    ) external onlyOperator {
        completed[getCompletedKey(key)] = newCompleted;
    }

    function setInvalidOrders(
        ExchangeDomain.Order[] calldata orders
    ) external onlyOperator {
        for (uint256 i = 0; i < orders.length; i++) {
            invalidOrders[prepareKey(orders[i])] = true;
        }
    }

    // 紧密打包order参数哈希运算得到bytes32的key，作为订单标识
    function getCompletedKey(
        ExchangeDomain.OrderKey memory key
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    key.owner,
                    key.sellAsset.token,
                    key.sellAsset.tokenId,
                    key.buyAsset.token,
                    key.buyAsset.tokenId,
                    key.salt
                )
            );
    }

    function prepareKey(
        ExchangeDomain.Order memory order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.key.sellAsset.token,
                    order.key.sellAsset.tokenId,
                    order.key.owner,
                    order.key.buyAsset.token,
                    order.key.buyAsset.tokenId,
                    order.key.salt
                )
            );
    }
}

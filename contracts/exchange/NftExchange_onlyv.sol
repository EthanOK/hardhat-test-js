// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/utils/StringLibrary.sol";
import "../lib/utils/BytesLibrary.sol";

import "./ExchangeDomain.sol";

contract NftExchange_only is ExchangeDomain {
    using SafeMath for uint256;
    using UintLibrary for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    constructor() {}

    function exchange(Order calldata order, Sig calldata sig) external payable {
        // 验证订单签名
        validateOrderSig(order, sig);
    }

    function validateOrderSig(
        Order memory order,
        Sig memory sig
    ) internal view {
        require(
            prepareMessage(order).recover(sig.v, sig.r, sig.s) ==
                order.key.owner,
            "incorrect signature"
        );
    }

    function prepareMessage(
        Order memory order
    ) public pure returns (string memory) {
        return keccak256(abi.encode(order)).toString();
    }
}

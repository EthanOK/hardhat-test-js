// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SeaportStruct {
    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,
        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,
        // 2: ERC721 items
        ERC721,
        // 3: ERC1155 items
        ERC1155,
        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,
        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }
    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,
        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,
        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,
        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED,
        // 4: contract order type
        CONTRACT
    }
    enum BasicOrderType {
        // 0: no partial fills, anyone can execute
        ETH_TO_ERC721_FULL_OPEN,
        // 1: partial fills supported, anyone can execute
        ETH_TO_ERC721_PARTIAL_OPEN,
        // 2: no partial fills, only offerer or zone can execute
        ETH_TO_ERC721_FULL_RESTRICTED,
        // 3: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC721_PARTIAL_RESTRICTED,
        // 4: no partial fills, anyone can execute
        ETH_TO_ERC1155_FULL_OPEN,
        // 5: partial fills supported, anyone can execute
        ETH_TO_ERC1155_PARTIAL_OPEN,
        // 6: no partial fills, only offerer or zone can execute
        ETH_TO_ERC1155_FULL_RESTRICTED,
        // 7: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,
        // 8: no partial fills, anyone can execute
        ERC20_TO_ERC721_FULL_OPEN,
        // 9: partial fills supported, anyone can execute
        ERC20_TO_ERC721_PARTIAL_OPEN,
        // 10: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC721_FULL_RESTRICTED,
        // 11: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,
        // 12: no partial fills, anyone can execute
        ERC20_TO_ERC1155_FULL_OPEN,
        // 13: partial fills supported, anyone can execute
        ERC20_TO_ERC1155_PARTIAL_OPEN,
        // 14: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC1155_FULL_RESTRICTED,
        // 15: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
        // 16: no partial fills, anyone can execute
        ERC721_TO_ERC20_FULL_OPEN,
        // 17: partial fills supported, anyone can execute
        ERC721_TO_ERC20_PARTIAL_OPEN,
        // 18: no partial fills, only offerer or zone can execute
        ERC721_TO_ERC20_FULL_RESTRICTED,
        // 19: partial fills supported, only offerer or zone can execute
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,
        // 20: no partial fills, anyone can execute
        ERC1155_TO_ERC20_FULL_OPEN,
        // 21: partial fills supported, anyone can execute
        ERC1155_TO_ERC20_PARTIAL_OPEN,
        // 22: no partial fills, only offerer or zone can execute
        ERC1155_TO_ERC20_FULL_RESTRICTED,
        // 23: partial fills supported, only offerer or zone can execute
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }
    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }
    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }
    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }
    struct BasicOrderParameters {
        // calldata offset
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        BasicOrderType basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
        // Total length, excluding dynamic array data: 0x264 (580)
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }
    enum Side {
        // 0: Items that can be spent
        OFFER,
        // 1: Items that must be received
        CONSIDERATION
    }
    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address payable recipient;
    }

    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }
}

contract Seaport is SeaportStruct {
    // blue 一笔 opensea 订单（用户直接调用）
    function fulfillOrder(
        /**
         * @custom:name order
         */
        Order calldata,
        bytes32 fulfillerConduitKey
    ) external payable returns (bool fulfilled) {
        // Convert order to "advanced" order, then validate and fulfill it.
        // fulfilled = _validateAndFulfillAdvancedOrder(
        //     _toAdvancedOrderReturnType(_decodeOrderAsAdvancedOrder)(
        //         CalldataStart.pptr()
        //     ),
        //     new CriteriaResolver[](0), // No criteria resolvers supplied.
        //     fulfillerConduitKey,
        //     msg.sender
        // );
    }

    // blue 多笔 opensea 订单（用户直接调用）
    function fulfillAvailableOrders(
        /**
         * @custom:name orders
         */
        Order[] calldata,
        /**
         * @custom:name offerFulfillments
         */
        FulfillmentComponent[][] calldata,
        /**
         * @custom:name considerationFulfillments
         */
        FulfillmentComponent[][] calldata,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (
            bool[] memory /* availableOrders */,
            Execution[] memory /* executions */
        )
    {
        // Convert orders to "advanced" orders and fulfill all available orders.
        // return
        //     _fulfillAvailableAdvancedOrders(
        //         _toAdvancedOrdersReturnType(_decodeOrdersAsAdvancedOrders)(
        //             CalldataStart.pptr()
        //         ), // Convert to advanced orders.
        //         new CriteriaResolver[](0), // No criteria resolvers supplied.
        //         _toNestedFulfillmentComponentsReturnType(
        //             _decodeNestedFulfillmentComponents
        //         )(
        //             CalldataStart.pptr(
        //                 Offset_fulfillAvailableOrders_offerFulfillments
        //             )
        //         ),
        //         _toNestedFulfillmentComponentsReturnType(
        //             _decodeNestedFulfillmentComponents
        //         )(
        //             CalldataStart.pptr(
        //                 Offset_fulfillAvailableOrders_considerationFulfillments
        //             )
        //         ),
        //         fulfillerConduitKey,
        //         msg.sender,
        //         maximumFulfilled
        //     );
    }

    function fulfillBasicOrder(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled) {
        // Validate and fulfill the basic order.
        // fulfilled = _validateAndFulfillBasicOrder(parameters);
    }

    // 多笔订单
    function fulfillAvailableAdvancedOrders(
        /**
         * @custom:name advancedOrders
         */
        AdvancedOrder[] calldata,
        /**
         * @custom:name criteriaResolvers
         */
        CriteriaResolver[] calldata,
        /**
         * @custom:name offerFulfillments
         */
        FulfillmentComponent[][] calldata,
        /**
         * @custom:name considerationFulfillments
         */
        FulfillmentComponent[][] calldata,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (
            bool[] memory /* availableOrders */,
            Execution[] memory /* executions */
        )
    {
        // Fulfill all available orders.
        // return
        //     _fulfillAvailableAdvancedOrders(
        //         _toAdvancedOrdersReturnType(_decodeAdvancedOrders)(
        //             CalldataStart.pptr()
        //         ),
        //         _toCriteriaResolversReturnType(_decodeCriteriaResolvers)(
        //             CalldataStart.pptr(
        //                 Offset_fulfillAvailableAdvancedOrders_criteriaResolvers
        //             )
        //         ),
        //         _toNestedFulfillmentComponentsReturnType(
        //             _decodeNestedFulfillmentComponents
        //         )(
        //             CalldataStart.pptr(
        //                 Offset_fulfillAvailableAdvancedOrders_offerFulfillments
        //             )
        //         ),
        //         _toNestedFulfillmentComponentsReturnType(
        //             _decodeNestedFulfillmentComponents
        //         )(
        //             CalldataStart.pptr(
        //                 Offset_fulfillAvailableAdvancedOrders_cnsdrationFlflmnts
        //             )
        //         ),
        //         fulfillerConduitKey,
        //         _substituteCallerForEmptyRecipient(recipient),
        //         maximumFulfilled
        //     );
    }
}

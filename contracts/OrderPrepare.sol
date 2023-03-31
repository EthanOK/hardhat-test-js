// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface NftExchange {
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

    function exchange(
        Order memory order,
        Sig calldata sig,
        uint256 buyerFee,
        Sig calldata buyerFeeSig,
        uint256 amount,
        address buyer
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

contract OrderPrepare is ExchangeDomain {
    using ECDSA for bytes32;
    Order public order;
    NftExchange nftex = NftExchange(0xFF4eD4B494ECbD052bf7fb9587d0E04030FF419c);
    bytes public orderbytes;

    constructor() {
        setOrderPram();
    }

    function getAssetType() public view returns (AssetType) {
        return order.key.sellAsset.assetType;
    }

    // function exchange(bytes memory signature) public {
    //     NftExchange.Sig memory sig;
    //     NftExchange.Order memory order_;
    //     order_.key.owner = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;
    //     order_
    //         .key
    //         .salt = 30043922068787383796652898510281479419555943511176550733606329901780427724528;
    //     //
    //     order_.sellAmount = 1;
    //     order_.unitPrice = 6000000000000000;
    //     order_.startTime = 1679968643;
    //     order_.endTime = 1682647043;
    //     //
    //     order_.key.sellAsset.token = 0x0D3e02768aB63516Ab5D386fAD462214CA3E6A86;
    //     order_.key.sellAsset.tokenId = 1;
    //     order_.key.sellAsset.assetType = NftExchange.AssetType.ERC721;
    //     //
    //     order_.key.buyAsset.token = address(0);
    //     order_.key.buyAsset.tokenId = 0;
    //     order_.key.buyAsset.assetType = NftExchange.AssetType.ETH;

    //     (sig.r, sig.s, sig.v) = signatureToRSV(signature);
    //     nftex.exchange(
    //         order_,
    //         sig,
    //         250,
    //         sig,
    //         1,
    //         0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2
    //     );
    // }

    function setOrderPram() public returns (bytes32) {
        order.key.owner = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;
        order
            .key
            .salt = 29632628411802564619696950749064795221497375268021588264186431382484631903328;
        //
        order.sellAmount = 1;
        order.unitPrice = 1000000000000000000;
        order.startTime = 1679986352;
        order.endTime = 1680105600;
        //
        order.key.sellAsset.token = 0x0D3e02768aB63516Ab5D386fAD462214CA3E6A86;
        order.key.sellAsset.tokenId = 1;
        order.key.sellAsset.assetType = AssetType.ERC721;

        order.key.buyAsset.token = address(0);
        order.key.buyAsset.tokenId = 0;
        order.key.buyAsset.assetType = AssetType.ETH;
        orderbytes = abi.encode(order);
        return prepareMessage();
    }

    function prepareMessage() public view returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    function validateOrderSig(
        bytes memory signature
    ) public view returns (address) {
        bytes32 hash = prepareMessage();
        (bytes32 r, bytes32 s, uint8 v) = signatureToRSV(signature);
        hash = hash.toEthSignedMessageHash();
        address signer = ecrecover(hash, v, r, s);
        // require(signer == order.key.owner, "incorrect signature");
        return signer;
    }

    function validateMessageSig(
        bytes32 message,
        bytes memory signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = signatureToRSV(signature);
        message = message.toEthSignedMessageHash();
        address signer = ecrecover(message, v, r, s);
        // require(signer == order.key.owner, "incorrect signature");
        return signer;
    }

    // function verify(bytes32 hash,bytes memory signature)
    function signatureToRSV(
        bytes memory signature
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            // First 32 bytes are the signature length
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature value");

        return (r, s, v);
    }

    function recoverSignerFromSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 hash
    ) external pure returns (address) {
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }

    function getBytes(
        bytes32 hash
    )
        public
        pure
        returns (bytes memory hashofencodePacked, bytes32 hashofether)
    {
        hashofencodePacked = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hash
        );
        hashofether = keccak256(hashofencodePacked);
    }
}

/* 
contract：0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
owner:0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2
message:0xad8f0e55bc60011facdc84454ce99b1f36fc7d202890523346307499086fec18
sig:0x85b6bf49ae6e533769568d36770f750243869a1a83e1a1c718711a65e22a43103b231861cfda97c28a8f9af6a0489f45d89d8e64b92c87191c41157895f3fa0e1c

0x257ab07f3543f4b8de850ea616b1a8db05d1edc6af7e0d28544ab9f34f23e1e1
0x4d0c1682baa4aad596111bcf1a4748d1bc1a4cb358447fd11192ae9aea3980db6d2fc8520cd5eaa7da2c0d61451eeba3e35ff03bda815283f43bb341d6c4b62e1c



0xf6896007477ab25a659f87c4f8c5e3baac32547bf305e77aa57743046e10578b
0x2085008022cb7c11f0b9d617b06fc0ff1caafb990bcfc5cb90e19ec3d8aeb0691379accfe9ebde9164bb5386c299d53d09dcd40bc11296976301d118ee4b69441c

bytes32: r 0x2085008022cb7c11f0b9d617b06fc0ff1caafb990bcfc5cb90e19ec3d8aeb069
1:
bytes32: s 0x1379accfe9ebde9164bb5386c299d53d09dcd40bc11296976301d118ee4b6944
2:
uint8: v 28
 */

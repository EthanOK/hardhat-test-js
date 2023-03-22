// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract AboutSig {
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
        bytes32 sig
    ) external pure returns (address) {
        address signer = ecrecover(sig, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }
}

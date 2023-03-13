// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchNFTDEMO is Ownable, ERC721 {
    uint256 tokenCount;
    uint256 public constant MAX_total = 1000;
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) ERC721(name, symbol) {
        baseURI = baseURI_;
        batchMint(msg.sender, 10);
    }

    function totalSupply() external view returns (uint256) {
        return tokenCount;
    }

    function batchMint(address to, uint256 amount) public onlyOwner {
        require(tokenCount + amount <= MAX_total, "Over MAX_total");
        uint256 tokenId = tokenCount;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, tokenId);
            tokenId++;
        }
        tokenCount += amount;
    }

    function batchTransfer(
        address[] memory to,
        uint256[] memory tokenId
    ) external {
        require(to.length == tokenId.length, "Array lengths must match");

        for (uint256 i = 0; i < to.length; i++) {
            safeTransferFrom(msg.sender, to[i], tokenId[i]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}

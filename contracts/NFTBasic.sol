// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTBasic is ERC721 {
    uint256 public constant MAX_total = 10000;
    uint256 tokenCount;
    address public owner;
    string public baseURI;
    mapping(address => bool) public operator;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) ERC721(name, symbol) {
        owner = msg.sender;
        _batchMint(msg.sender, 20);
        baseURI = baseURI_;
    }

    function setOperator(address _account) external onlyOwner {
        operator[_account] = !operator[_account];
    }

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }

    function swap(address to, uint256 amount) external onlyOperator {
        _batchMint(to, amount);
    }

    function batchMintMul(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(tos.length == amounts.length, "Array lengths must match");
        for (uint256 i = 0; i < tos.length; ++i) {
            _batchMint(tos[i], amounts[i]);
        }
    }

    function batchMint(address to, uint256 amount) external onlyOwner {
        _batchMint(to, amount);
    }

    function _batchMint(address to, uint256 amount) private {
        require(tokenCount + amount <= MAX_total, "Over MAX_total");
        uint256 tokenId = tokenCount;
        for (uint256 i = 0; i < amount; ++i) {
            ++tokenId;
            _safeMint(to, tokenId);
        }
        tokenCount += amount;
    }

    function batchTransfer(
        address[] memory tos,
        uint256[] memory tokenIds
    ) external {
        require(tos.length == tokenIds.length, "Array lengths must match");

        for (uint256 i = 0; i < tos.length; ++i) {
            safeTransferFrom(msg.sender, tos[i], tokenIds[i]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
    modifier onlyOperator() {
        require(operator[_msgSender()], "not operator");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BatchMintTransferNFT is ERC721 {
    uint256 public constant MAX_total = 1000;
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
        batchMint(0xCcC991EA497647a90Ec6630eD72607d20F87C079, 10);
        batchMint(0xa002d00E2Db3Aa0a8a3f0bD23Affda03a694D06A, 10);
        batchMint(0x75bA7E89F1907Bd26acd7Fe532A4E8b33bB8F21e, 10);
        batchMint(0xba8E66Ade899BabD6B4255a4caD8770d5C65611B, 10);
        batchMint(0x809470247DE84986B5D13a4c27b433CA77510196, 10);
        batchMint(owner, 10);
        baseURI = baseURI_;
    }

    function setOperator(address _account) external onlyOwner {
        operator[_account] = !operator[_account];
    }

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }

    function swap(
        address to,
        address _recommender,
        uint256 amount
    ) external onlyOperator {
        _recommender = address(0);
        require(tokenCount + amount <= MAX_total, "Over MAX_total");
        uint256 tokenId = tokenCount;
        for (uint256 i = 0; i < amount; ++i) {
            ++tokenId;
            _safeMint(to, tokenId);
        }
        tokenCount += amount;
    }

    function batchMint(address to, uint256 amount) public onlyOwner {
        require(tokenCount + amount <= MAX_total, "Over MAX_total");
        uint256 tokenId = tokenCount;
        for (uint256 i = 0; i < amount; ++i) {
            ++tokenId;
            _safeMint(to, tokenId);
        }
        tokenCount += amount;
    }

    function batchTransfer(
        address[] memory to,
        uint256[] memory tokenId
    ) public {
        require(to.length == tokenId.length, "Array lengths must match");

        for (uint256 i = 0; i < to.length; ++i) {
            safeTransferFrom(msg.sender, to[i], tokenId[i]);
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

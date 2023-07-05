// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract ERC1155Standard is Ownable, ERC1155Supply {
    using Strings for uint256;
    string private _baseURI = "https://boredapeyachtclub.com/api/mutants/";
    uint256 private _totalSupplyALL;

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupplyALL;
    }

    constructor() ERC1155("") {
        // _setBaseURI(newBaseURI);
        _mint(msg.sender, 1, 10, "0x");
        _mint(msg.sender, 2, 20, "0x");
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _setBaseURI(newuri);
    }

    function _setBaseURI(string memory newuri) internal {
        _baseURI = newuri;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            uint256 _temp;
            for (uint256 i = 0; i < ids.length; ++i) {
                _temp += amounts[i];
            }
            _totalSupplyALL += _temp;
        }

        if (to == address(0)) {
            uint256 _temp;
            for (uint256 i = 0; i < ids.length; ++i) {
                _temp += amounts[i];
            }
            _totalSupplyALL -= _temp;
        }
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(exists(tokenId), "TokenId doesn't exist");
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : "";
    }
}

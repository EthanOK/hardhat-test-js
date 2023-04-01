// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YgStakingDomain is Pausable, Ownable {
    struct StakingData {
        address account;
        uint256 startTime;
        uint256 endTime;
    }

    uint256[] public stakingPeriods = [30 days, 90 days, 180 days];

    IERC721 public ygme;

    // tokenId staking data
    mapping(uint256 => StakingData) public stakingDatas;

    mapping(uint256 => bool) public stakedState;

    // account staking tokenId list
    mapping(address => uint256[]) stakingTokenIds;

    // stake total
    // ygmeTotal =>
    // accountTotal => 0x6163636f756e74546f74616c

    mapping(bytes => uint256) public stakeTotals;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

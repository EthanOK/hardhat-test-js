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
import "./YgStakingDomain.sol";

contract YgStaking is YgStakingDomain, ERC721Holder, ReentrancyGuard {
    constructor() {}

    function staking(
        uint256[] calldata _tokenIds,
        uint256 _stakeTime
    ) external whenNotPaused nonReentrant returns (bool) {
        uint256 length = _tokenIds.length;

        require(length > 0, "invalid length");

        for (uint256 i = 0; i < length; i++) {
            require(!stakedState[_tokenIds[i]], "invalid stake state");

            require(ygme.ownerOf(_tokenIds[i]) == msg.sender, "invalid owner");
        }

        if (stakingTokenIds[msg.sender].length == 0) {
            stakeTotals[bytes("accountTotal")] += 1;
        }

        for (uint256 i = 0; i < length; i++) {
            uint256 _tokenId = _tokenIds[i];

            ygme.safeTransferFrom(msg.sender, address(this), _tokenId);

            StakingData memory _data = StakingData({
                account: msg.sender,
                startTime: block.timestamp,
                endTime: block.timestamp + _stakeTime
            });

            stakingDatas[_tokenId] = _data;

            // emit StakeData();

            if (stakingTokenIds[msg.sender].length == 0) {
                stakingTokenIds[msg.sender] = [_tokenId];
            } else {
                stakingTokenIds[msg.sender].push(_tokenId);
            }

            if (!stakedState[_tokenId]) {
                stakeTotals[bytes("ygmeTotal")] += 1;
                stakedState[_tokenId] = true;
            }
        }
        return true;
    }

    function unStake(
        uint256[] calldata _tokenIds
    ) external whenNotPaused nonReentrant returns (bool) {}
}

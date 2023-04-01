// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./YgStakingDomain.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YgStaking is
    YgStakingDomain,
    Pausable,
    Ownable,
    ERC721Holder,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    uint64[3] private stakingPeriods;

    IERC721 public ygme;

    address private withdrawSigner;

    mapping(uint256 => StakingData) public stakingDatas;

    mapping(address => uint256[]) public stakingTokenIds;

    mapping(uint256 => bool) public orderIsInvalid;

    uint128 public accountTotal;

    uint128 public ygmeTotal;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setStakingPeriods(uint64[3] calldata _periods) external onlyOwner {
        stakingPeriods = _periods;
    }

    function getStakingPeriods()
        external
        view
        onlyOwner
        returns (uint64[3] memory)
    {
        return stakingPeriods;
    }

    function setWithdrawSigner(address _withdrawSigner) external onlyOwner {
        withdrawSigner = _withdrawSigner;
    }

    function getWithdrawSigner() external view onlyOwner returns (address) {
        return withdrawSigner;
    }

    constructor(
        address _ygme,
        address _withdrawSigner,
        uint64[3] memory _periods
    ) {
        ygme = IERC721(_ygme);
        withdrawSigner = _withdrawSigner;
        stakingPeriods = _periods;
    }

    function staking(
        uint256[] calldata _tokenIds,
        uint256 _stakeTime
    ) external whenNotPaused nonReentrant returns (bool) {
        uint256 length = _tokenIds.length;

        address _account = _msgSender();

        require(length > 0, "invalid _tokenIds");

        require(
            _stakeTime == stakingPeriods[0] ||
                _stakeTime == stakingPeriods[1] ||
                _stakeTime == stakingPeriods[2],
            "invalid staking time"
        );

        for (uint256 i = 0; i < length; i++) {
            require(
                !stakingDatas[_tokenIds[i]].stakedState,
                "invalid stake state"
            );

            require(ygme.ownerOf(_tokenIds[i]) == _account, "invalid owner");
        }

        if (stakingTokenIds[_account].length == 0) {
            unchecked {
                accountTotal += 1;
            }
        }

        for (uint256 i = 0; i < length; i++) {
            uint256 _tokenId = _tokenIds[i];

            ygme.safeTransferFrom(_account, address(this), _tokenId);

            StakingData memory _data = StakingData({
                account: _account,
                startTime: block.timestamp,
                endTime: block.timestamp + _stakeTime,
                stakedState: true
            });

            stakingDatas[_tokenId] = _data;

            if (stakingTokenIds[_account].length == 0) {
                stakingTokenIds[_account] = [_tokenId];
            } else {
                stakingTokenIds[_account].push(_tokenId);
            }

            unchecked {
                ygmeTotal += 1;
            }

            emit Staking(
                _account,
                _tokenId,
                address(ygme),
                _data.startTime,
                _data.endTime
            );
        }
        return true;
    }

    function unStake(
        uint256[] calldata _tokenIds
    ) external whenNotPaused nonReentrant returns (bool) {
        uint256 length = _tokenIds.length;

        address _account = _msgSender();

        require(length > 0, "invalid tokenIds");

        for (uint256 i = 0; i < length; i++) {
            uint256 _tokenId = _tokenIds[i];

            StakingData storage _data = stakingDatas[_tokenId];

            require(_data.account == _account, "invalid account");

            require(stakingDatas[_tokenId].stakedState, "invalid stake state");

            require(
                block.timestamp >= _data.endTime,
                "It's not time to unStake"
            );

            ygme.safeTransferFrom(address(this), _data.account, _tokenId);

            uint256 _len = stakingTokenIds[_account].length;

            for (uint256 j = 0; j < _len; j++) {
                if (stakingTokenIds[_account][j] == _tokenId) {
                    stakingTokenIds[_account][j] = stakingTokenIds[_account][
                        _len - 1
                    ];
                    stakingTokenIds[_account].pop();
                    break;
                }
            }

            if (stakingTokenIds[_account].length == 0) {
                accountTotal -= 1;
            }

            ygmeTotal -= 1;

            emit UnStake(
                _account,
                _tokenId,
                address(ygme),
                _data.startTime,
                block.timestamp
            );

            delete stakingDatas[_tokenId];
        }
        return true;
    }

    function withdrawERC20(
        bytes calldata data,
        Sig calldata sig
    ) external nonReentrant returns (bool) {
        bytes32 hash = keccak256(data);

        _verifySignature(hash, sig);

        (
            uint256 orderId,
            address erc20,
            address account,
            uint256 amount,
            string memory random
        ) = abi.decode(data, (uint256, address, address, uint256, string));

        require(!orderIsInvalid[orderId], "order is invalid");

        require(account == msg.sender, "caller is not the account");

        orderIsInvalid[orderId] = true;

        IERC20(erc20).safeTransferFrom(address(this), account, amount);

        emit WithdrawERC20(orderId, erc20, account, amount, random);

        return true;
    }

    function _verifySignature(bytes32 hash, Sig calldata sig) internal view {
        hash = _toEthSignedMessageHash(hash);

        address signer = ecrecover(hash, sig.v, sig.r, sig.s);

        require(signer == withdrawSigner, "incorrect withdraw signature");
    }

    function _toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

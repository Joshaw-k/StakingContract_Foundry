// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./interface/IWETH.sol";
import {IJOSHAWK} from "./interface/IJOSHAWK.sol";
import {IRECIPEE} from "./interface/IRECIPEE.sol";
import "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Staking {
    IWETH WETH;
    IJOSHAWK rewardToken;
    IRECIPEE receiptToken;
    IUniswapV2Router02 public uniswapRouter;

    struct StakerInfo {
        uint256 stakedAmount;
        bool autoCompound;
        uint256 timeStaked;
        bool triggered;
        uint256 lastCompoundedTimestamp;
        uint256 reward;
    }

    mapping(address => StakerInfo) _stakerInfo;

    uint256 public annualAPR = 14;
    uint256 public compoundingFeePercentage = 1;
    uint256 public rewardMultiplier = 10;

    constructor(address _weth, address _rewardToken, address _receiptToken, address _uniswapRouterAddr) {
        WETH = IWETH(_weth);
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddr);
        rewardToken = IJOSHAWK(_rewardToken);
        receiptToken = IRECIPEE(_receiptToken);
    }

    function stake(bool _autoCompound) public payable {
        require(msg.value > 0, "No Zero Staking");
        WETH.deposit{value: msg.value}();
        receiptToken.mint(msg.sender, msg.value);
        StakerInfo storage stakerInfo = _stakerInfo[msg.sender];
        stakerInfo.receiptAmount = msg.value;
        stakerInfo.autoCompound = _autoCompound;
        stakerInfo.timeStaked = block.timestamp;
    }

    function compoundEarnings(address user) internal {
        uint256 lastCompounded = _stakerInfo[user].lastCompoundedTimestamp;
        uint256 balance = _stakerInfo[user].stakedAmount;
        uint256 timeSinceLastCompounded = block.timestamp - lastCompounded;

        if (timeSinceLastCompounded > 0) {
            uint256 earnings = (balance * annualAPR * timeSinceLastCompounded) / (365 days * 100);
            uint256 reward = (earnings * rewardMultiplier);
            _stakerInfo[user].reward += reward;
            _stakerInfo[user].lastCompoundedTimestamp = block.timestamp;
        }
    }

    function compoundRewards() external {
        Stake storage staker = _stakerInfo[msg.sender];
        require(_stakerInfo[msg.sender].stakedAmount > 0, "No staked WETH");
        uint256 rewardsToCompound = calculateRewardsToCompound(msg.sender);
        require(rewardsToCompound > 0, "No rewards to compound");
        uint256 fee = rewardsToCompound * compoundingFeePercentage / 100;
        uint256 wethToStake = rewardsToCompound - fee / 10;
        _stakerInfo[msg.sender].stakedAmount = staker.stakedAmount + wethToStake;
        _stakerInfo[msg.sender].reward = staker.totalRewards + rewardsToCompound - fee;
        _stakerInfo[msg.sender].timeStaked = block.timestamp;
    }

    function calculateRewardsToCompound(address user) internal view returns (uint256) {
        Stake storage staker = _stakerInfo[user];
        uint256 timeSinceLastStake = block.timestamp - _stakerInfo[user].timeStaked;
        uint256 annualSeconds = 365 days;
        uint256 annualRate = annualAPR * annualSeconds / 100;
        uint256 result = _stakerInfo[user].receiptAmount * annualRate * timeSinceLastStake / annualSeconds;
        return result;
    }

    function withdraw() external {
        StakerInfo storage stakerInfo = _stakerInfo[msg.sender];

        require(_stakerInfo[msg.sender].stakedAmount > 0, "No staked WETH");

        uint256 rewardsToWithdraw = staker.rewards;

        require(rewardsToWithdraw > 0, "No rewards to withdraw");

        WETH.transfer(msg.sender, staker.stakedAmount);
        blessedToken.burn(msg.sender, rewardsToWithdraw);
        _stakerInfo[msg.sender].stakedAmount = 0;
        _stakerInfo[msg.sender].reward = 0;
        _stakerInfo[msg.sender].timeStaked = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IWETH} from "../src/interface/IWETH.sol";
import {IJOSHAWK} from "../src/interface/IJOSHAWK.sol";
import {IRECIPEE} from "../src/interface/IRECIPEE.sol";
import {Staking} from "../src/staking.sol";
import {Recipee} from "../src/recipee.sol";
import {Joshawk} from "../src/Joshawk.sol";
import "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract StakingTest is Test {
    IUniswapV2Router02 uniswapRouter;
    IWETH WETH;
    IJOSHAWK rewardToken;
    IRECIPEE receiptToken;
    Staking stakingContract;
    address user1 = 0xB5119738BB5Fe8BE39aB592539EaA66F03A77174;

    function setUp() public {
        WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rewardToken = new Recipee();
        receiptToken = new Joshawk();
    }

    function testStakeEth() public {
        // Send 1 ether to the staking contract
        vm.prank(user1);
        vm.deal(user1, 50 ether);
        stakingContract.stake{value: 1 ether}();

        // Check that the balance and earned tokens are updated correctly
        assertEq(stakingContract.balances(address(this)), 1 ether);
        assertEq(stakingContract.earnedTokens(address(this)), 10 ether);

        // Check that the receipt token is minted correctly
        assertEq(WDMitongToken.balanceOf(address(this)), 10 ether);
    }

    function testWithdraw() public {
        // Stake some ETH first
        stakingContract.stake{value: 1 ether}();

        // Withdraw the staked amount and the earned tokens
        stakingContract.withdraw(1 ether);

        // Check that the balance and earned tokens are zero
        assertEq(stakingContract.balances(address(this)), 0);
        assertEq(stakingContract.earnedTokens(address(this)), 0);

        // Check that the WETH and WDMitongToken are transferred correctly
        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(WDMitongToken.balanceOf(address(this)), 10 ether);
    }
}

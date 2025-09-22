// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../Token/token.sol";
import "./staking.sol";

/**
 * @title StakingContractTest
 * @dev Comprehensive test suite for the StakingContract
 */
contract StakingContractTest is Test {
    StakingContract public stakingContract;
    Token public stakingToken;
    Token public rewardToken;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18; // 1M tokens
    uint256 public constant STAKE_AMOUNT = 1000 * 10**18; // 1000 tokens
    uint256 public constant REWARD_AMOUNT = 100000 * 10**18; // 100K tokens for rewards
    
    function setUp() public {
        // Deploy tokens
        vm.startPrank(owner);
        stakingToken = new Token(INITIAL_SUPPLY, "StakingToken", "STK", 18);
        rewardToken = new Token(INITIAL_SUPPLY, "RewardToken", "RWD", 18);
        
        // Deploy staking contract
        stakingContract = new StakingContract(address(stakingToken), address(rewardToken));
        
        // Transfer tokens to users
        stakingToken.transfer(user1, STAKE_AMOUNT * 10);
        stakingToken.transfer(user2, STAKE_AMOUNT * 10);
        
        // Transfer reward tokens to staking contract
        rewardToken.transfer(address(stakingContract), REWARD_AMOUNT);
        
        vm.stopPrank();
    }
    
    // ============ CONSTRUCTOR TESTS ============
    
    function testConstructor() public view {
        assertEq(address(stakingContract.stakingToken()), address(stakingToken));
        assertEq(address(stakingContract.rewardToken()), address(rewardToken));
        assertEq(stakingContract.owner(), owner);
        assertEq(stakingContract.tierCount(), 4); // 4 default tiers
    }
    
    function testConstructorInvalidToken() public {
        vm.expectRevert("Invalid staking token address");
        new StakingContract(address(0), address(rewardToken));
        
        vm.expectRevert("Invalid reward token address");
        new StakingContract(address(stakingToken), address(0));
    }
    
    // ============ STAKING TESTS ============
    
    function testStake() public {
        vm.startPrank(user1);
        
        // Approve tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        
        // Stake tokens
        stakingContract.stake(STAKE_AMOUNT, 0); // Tier 0 (30 days)
        
        // Check staking info
        assertEq(stakingContract.getUserStakeCount(user1), 1);
        assertEq(stakingContract.getUserTotalStaked(user1), STAKE_AMOUNT);
        assertEq(stakingContract.totalStaked(), STAKE_AMOUNT);
        
        // Check user balance
        assertEq(stakingToken.balanceOf(user1), STAKE_AMOUNT * 9); // 10 - 1 = 9
        assertEq(stakingToken.balanceOf(address(stakingContract)), STAKE_AMOUNT);
        
        vm.stopPrank();
    }
    
    function testStakeInvalidAmount() public {
        vm.startPrank(user1);
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        
        // Test minimum amount
        vm.expectRevert("Amount below minimum stake");
        stakingContract.stake(50 * 10**18, 0); // Below minimum
        
        // Test maximum amount
        vm.expectRevert("Amount exceeds maximum stake");
        stakingContract.stake(2000000 * 10**18, 0); // Above maximum
        
        vm.stopPrank();
    }
    
    function testStakeInvalidTier() public {
        vm.startPrank(user1);
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        
        // Test invalid tier
        vm.expectRevert("Invalid staking tier");
        stakingContract.stake(STAKE_AMOUNT, 10); // Non-existent tier
        
        vm.stopPrank();
    }
    
    function testStakeInsufficientBalance() public {
        vm.startPrank(user1);
        
        // Test insufficient balance
        vm.expectRevert("Insufficient token balance");
        stakingContract.stake(STAKE_AMOUNT * 100, 0); // More than user has
        
        vm.stopPrank();
    }
    
    function testStakeInsufficientAllowance() public {
        vm.startPrank(user1);
        
        // Test insufficient allowance
        vm.expectRevert("Insufficient allowance");
        stakingContract.stake(STAKE_AMOUNT, 0); // No approval
        
        vm.stopPrank();
    }
    
    // ============ UNSTAKING TESTS ============
    
    function testUnstake() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        // Fast forward time to unlock period
        vm.warp(block.timestamp + 31 days);
        
        // Unstake
        stakingContract.unstake(0);
        
        // Check unstaking
        assertEq(stakingContract.getUserTotalStaked(user1), 0);
        assertEq(stakingContract.totalStaked(), 0);
        assertEq(stakingToken.balanceOf(user1), STAKE_AMOUNT * 10); // Back to original
        
        vm.stopPrank();
    }
    
    function testUnstakeTooEarly() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        // Try to unstake too early
        vm.expectRevert("Stake still locked");
        stakingContract.unstake(0);
        
        vm.stopPrank();
    }
    
    function testUnstakeInvalidStakeId() public {
        vm.startPrank(user1);
        
        // Try to unstake non-existent stake
        vm.expectRevert("Invalid stake ID");
        stakingContract.unstake(0);
        
        vm.stopPrank();
    }
    
    // ============ REWARD TESTS ============
    
    function testClaimRewards() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        // Fast forward time to accumulate rewards
        vm.warp(block.timestamp + 1 days);
        
        // Check earned rewards
        uint256 earned = stakingContract.earned(user1);
        assertTrue(earned > 0);
        
        // Claim rewards
        stakingContract.claimRewards();
        
        // Check reward token balance
        assertTrue(rewardToken.balanceOf(user1) > 0);
        
        vm.stopPrank();
    }
    
    function testClaimRewardsNoRewards() public {
        vm.startPrank(user1);
        
        // Try to claim without staking
        vm.expectRevert("No rewards to claim");
        stakingContract.claimRewards();
        
        vm.stopPrank();
    }
    
    // ============ ADMIN FUNCTION TESTS ============
    
    function testAddStakingTier() public {
        vm.startPrank(owner);
        
        // Add new tier
        stakingContract.addStakingTier(60 days, 12000); // 60 days, 1.2x multiplier
        
        // Check tier was added
        assertEq(stakingContract.tierCount(), 5);
        
        vm.stopPrank();
    }
    
    function testAddStakingTierNotOwner() public {
        vm.startPrank(user1);
        
        // Try to add tier as non-owner
        vm.expectRevert();
        stakingContract.addStakingTier(60 days, 12000);
        
        vm.stopPrank();
    }
    
    function testUpdateStakingTier() public {
        vm.startPrank(owner);
        
        // Update tier status
        stakingContract.updateStakingTier(0, false);
        
        // Check tier is inactive
        (,, bool active) = stakingContract.stakingTiers(0);
        assertFalse(active);
        
        vm.stopPrank();
    }
    
    function testUpdateRewardRate() public {
        vm.startPrank(owner);
        
        // Update reward rate
        stakingContract.updateRewardRate(2000); // 0.2% per day
        
        // Check rate was updated
        assertEq(stakingContract.rewardRate(), 2000);
        
        vm.stopPrank();
    }
    
    function testDepositRewards() public {
        vm.startPrank(owner);
        
        // Approve reward tokens
        rewardToken.approve(address(stakingContract), REWARD_AMOUNT);
        
        // Deposit rewards
        stakingContract.depositRewards(REWARD_AMOUNT);
        
        // Check contract balance
        assertEq(rewardToken.balanceOf(address(stakingContract)), REWARD_AMOUNT * 2);
        
        vm.stopPrank();
    }
    
    // ============ PAUSE TESTS ============
    
    function testPause() public {
        vm.startPrank(owner);
        
        // Pause contract
        stakingContract.pause();
        
        // Try to stake while paused
        vm.stopPrank();
        vm.startPrank(user1);
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        
        vm.expectRevert();
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        vm.stopPrank();
    }
    
    function testUnpause() public {
        vm.startPrank(owner);
        
        // Pause and unpause
        stakingContract.pause();
        stakingContract.unpause();
        
        // Should be able to stake again
        vm.stopPrank();
        vm.startPrank(user1);
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        vm.stopPrank();
    }
    
    // ============ EMERGENCY TESTS ============
    
    function testEmergencyUnstake() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        vm.stopPrank();
        
        // Owner emergency unstake
        vm.startPrank(owner);
        stakingContract.emergencyUnstake(user1, 0);
        
        // Check user received 50% back
        assertEq(stakingToken.balanceOf(user1), STAKE_AMOUNT * 9 + STAKE_AMOUNT / 2);
        
        vm.stopPrank();
    }
    
    function testEmergencyUnstakeNotOwner() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        // Try emergency unstake as non-owner
        vm.expectRevert();
        stakingContract.emergencyUnstake(user1, 0);
        
        vm.stopPrank();
    }
    
    // ============ VIEW FUNCTION TESTS ============
    
    function testCanUnstake() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        // Check can't unstake yet
        assertFalse(stakingContract.canUnstake(user1, 0));
        
        // Fast forward time
        vm.warp(block.timestamp + 31 days);
        
        // Check can unstake now
        assertTrue(stakingContract.canUnstake(user1, 0));
        
        vm.stopPrank();
    }
    
    function testGetUserStake() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 1); // Tier 1
        
        // Get stake info
        StakingContract.StakingInfo memory stake = stakingContract.getUserStake(user1, 0);
        
        assertEq(stake.amount, STAKE_AMOUNT);
        assertEq(stake.tier, 1);
        assertTrue(stake.active);
        
        vm.stopPrank();
    }
    
    // ============ INTEGRATION TESTS ============
    
    function testMultipleStakes() public {
        vm.startPrank(user1);
        
        // Approve tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT * 3);
        
        // Stake in different tiers
        stakingContract.stake(STAKE_AMOUNT, 0); // 30 days
        stakingContract.stake(STAKE_AMOUNT, 1); // 90 days
        stakingContract.stake(STAKE_AMOUNT, 2); // 180 days
        
        // Check total staked
        assertEq(stakingContract.getUserTotalStaked(user1), STAKE_AMOUNT * 3);
        assertEq(stakingContract.getUserStakeCount(user1), 3);
        assertEq(stakingContract.totalStaked(), STAKE_AMOUNT * 3);
        
        vm.stopPrank();
    }
    
    function testRewardCalculation() public {
        vm.startPrank(user1);
        
        // Stake tokens
        stakingToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, 0);
        
        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);
        
        // Check earned rewards
        uint256 earned = stakingContract.earned(user1);
        assertTrue(earned > 0);
        
        // Fast forward another day
        vm.warp(block.timestamp + 1 days);
        
        // Check more rewards earned
        uint256 earned2 = stakingContract.earned(user1);
        assertTrue(earned2 > earned);
        
        vm.stopPrank();
    }
}

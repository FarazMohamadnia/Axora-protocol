// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StakingContract - Token Staking with Rewards
 * @dev A secure staking contract that allows users to stake tokens and earn rewards
 */
contract StakingContract is ReentrancyGuard, Pausable, Ownable {
    // ============ STATE VARIABLES ============
    
    IERC20 public immutable stakingToken;        // The token being staked
    IERC20 public immutable rewardToken;         // The token used for rewards
    
    uint256 public totalStaked;                  // Total amount of tokens staked
    uint256 public totalRewardsDistributed;     // Total rewards distributed
    
    // Staking pool configuration
    uint256 public constant MIN_STAKE_AMOUNT = 100 * 10**18;  // Minimum 100 tokens
    uint256 public constant MAX_STAKE_AMOUNT = 1000000 * 10**18; // Maximum 1M tokens
    
    // Reward calculation
    uint256 public rewardRate = 1000;            // Base reward rate (0.1% per day)
    uint256 public constant REWARD_RATE_DECIMALS = 10000; // 10000 = 100%
    uint256 public lastUpdateTime;               // Last time rewards were calculated
    uint256 public rewardPerTokenStored;         // Accumulated rewards per token
    
    // Staking tiers with different reward multipliers
    struct StakingTier {
        uint256 duration;        // Lock period in seconds
        uint256 multiplier;      // Reward multiplier (10000 = 1x)
        bool active;            // Whether this tier is active
    }
    
    mapping(uint256 => StakingTier) public stakingTiers;
    uint256 public tierCount;
    
    // User staking information
    struct StakingInfo {
        uint256 amount;         // Amount staked
        uint256 tier;           // Staking tier
        uint256 startTime;      // When staking started
        uint256 lastClaimTime;  // Last time rewards were claimed
        uint256 rewardDebt;     // Reward debt for accurate calculation
        bool active;            // Whether the stake is active
    }
    
    mapping(address => StakingInfo[]) public userStakes;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    // ============ EVENTS ============
    
    event Staked(address indexed user, uint256 amount, uint256 tier, uint256 stakeId);
    event Unstaked(address indexed user, uint256 amount, uint256 stakeId);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event StakingTierAdded(uint256 tierId, uint256 duration, uint256 multiplier);
    event StakingTierUpdated(uint256 tierId, bool active);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
    // ============ CONSTRUCTOR ============
    
    /**
     * @dev Constructor to initialize the staking contract
     * @param _stakingToken Address of the token to be staked
     * @param _rewardToken Address of the reward token
     */
    constructor(address _stakingToken, address _rewardToken) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid staking token address");
        require(_rewardToken != address(0), "Invalid reward token address");
        
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        lastUpdateTime = block.timestamp;
        
        // Initialize default staking tiers
        _addStakingTier(30 days, 10000);      // 30 days, 1x multiplier
        _addStakingTier(90 days, 15000);      // 90 days, 1.5x multiplier
        _addStakingTier(180 days, 20000);     // 180 days, 2x multiplier
        _addStakingTier(365 days, 30000);     // 365 days, 3x multiplier
    }
    
    // ============ MODIFIERS ============
    
    /**
     * @dev Modifier to update reward calculations
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    // ============ VIEW FUNCTIONS ============
    
    /**
     * @dev Returns the last time rewards were applicable
     * @return The last time rewards were calculated
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp;
    }
    
    /**
     * @dev Returns the current reward per token
     * @return The accumulated rewards per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored + 
               ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / 
               (totalStaked * 86400); // 86400 seconds in a day
    }
    
    /**
     * @dev Returns the earned rewards for an account
     * @param account The account to check
     * @return The amount of rewards earned
     */
    function earned(address account) public view returns (uint256) {
        return ((_getUserTotalStaked(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }
    
    /**
     * @dev Returns the total amount staked by a user
     * @param user The user address
     * @return The total staked amount
     */
    function getUserTotalStaked(address user) external view returns (uint256) {
        return _getUserTotalStaked(user);
    }
    
    /**
     * @dev Returns the number of active stakes for a user
     * @param user The user address
     * @return The number of active stakes
     */
    function getUserStakeCount(address user) external view returns (uint256) {
        return userStakes[user].length;
    }
    
    /**
     * @dev Returns staking information for a specific stake
     * @param user The user address
     * @param stakeId The stake ID
     * @return The staking information
     */
    function getUserStake(address user, uint256 stakeId) external view returns (StakingInfo memory) {
        require(stakeId < userStakes[user].length, "Invalid stake ID");
        return userStakes[user][stakeId];
    }
    
    /**
     * @dev Returns whether a stake can be unstaked (lock period completed)
     * @param user The user address
     * @param stakeId The stake ID
     * @return True if the stake can be unstaked
     */
    function canUnstake(address user, uint256 stakeId) external view returns (bool) {
        require(stakeId < userStakes[user].length, "Invalid stake ID");
        StakingInfo memory userStake = userStakes[user][stakeId];
        
        if (!userStake.active) return false;
        
        uint256 lockEndTime = userStake.startTime + stakingTiers[userStake.tier].duration;
        return block.timestamp >= lockEndTime;
    }
    
    // ============ STAKING FUNCTIONS ============
    
    /**
     * @dev Stakes tokens for a specific tier
     * @param amount The amount of tokens to stake
     * @param tier The staking tier
     */
    function stake(uint256 amount, uint256 tier) external whenNotPaused nonReentrant updateReward(msg.sender) {
        require(amount >= MIN_STAKE_AMOUNT, "Amount below minimum stake");
        require(amount <= MAX_STAKE_AMOUNT, "Amount exceeds maximum stake");
        require(tier < tierCount, "Invalid staking tier");
        require(stakingTiers[tier].active, "Staking tier not active");
        require(stakingToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(stakingToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        
        // Transfer tokens from user to contract
        stakingToken.transferFrom(msg.sender, address(this), amount);
        
        // Create new stake
        StakingInfo memory newStake = StakingInfo({
            amount: amount,
            tier: tier,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            rewardDebt: 0,
            active: true
        });
        
        userStakes[msg.sender].push(newStake);
        totalStaked += amount;
        
        emit Staked(msg.sender, amount, tier, userStakes[msg.sender].length - 1);
    }
    
    /**
     * @dev Unstakes tokens from a specific stake
     * @param stakeId The ID of the stake to unstake
     */
    function unstake(uint256 stakeId) external whenNotPaused nonReentrant updateReward(msg.sender) {
        require(stakeId < userStakes[msg.sender].length, "Invalid stake ID");
        StakingInfo storage userStake = userStakes[msg.sender][stakeId];
        require(userStake.active, "Stake not active");
        
        // Check if lock period has ended
        uint256 lockEndTime = userStake.startTime + stakingTiers[userStake.tier].duration;
        require(block.timestamp >= lockEndTime, "Stake still locked");
        
        uint256 stakeAmount = userStake.amount;
        userStake.active = false;
        totalStaked -= stakeAmount;
        
        // Transfer tokens back to user
        stakingToken.transfer(msg.sender, stakeAmount);
        
        emit Unstaked(msg.sender, stakeAmount, stakeId);
    }
    
    /**
     * @dev Claims accumulated rewards
     */
    function claimRewards() external whenNotPaused nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");
        
        rewards[msg.sender] = 0;
        totalRewardsDistributed += reward;
        
        rewardToken.transfer(msg.sender, reward);
        
        emit RewardClaimed(msg.sender, reward);
    }
    
    /**
     * @dev Emergency unstake (with penalty) - only for owner
     * @param user The user address
     * @param stakeId The stake ID
     */
    function emergencyUnstake(address user, uint256 stakeId) external onlyOwner {
        require(stakeId < userStakes[user].length, "Invalid stake ID");
        StakingInfo storage userStake = userStakes[user][stakeId];
        require(userStake.active, "Stake not active");
        
        uint256 stakeAmount = userStake.amount;
        userStake.active = false;
        totalStaked -= stakeAmount;
        
        // Apply 50% penalty for emergency unstake
        uint256 penaltyAmount = stakeAmount / 2;
        uint256 returnAmount = stakeAmount - penaltyAmount;
        
        // Transfer remaining tokens to user
        stakingToken.transfer(user, returnAmount);
        
        emit EmergencyWithdraw(user, returnAmount);
    }
    
    // ============ ADMIN FUNCTIONS ============
    
    /**
     * @dev Adds a new staking tier
     * @param duration The lock duration in seconds
     * @param multiplier The reward multiplier (10000 = 1x)
     */
    function addStakingTier(uint256 duration, uint256 multiplier) external onlyOwner {
        _addStakingTier(duration, multiplier);
    }
    
    /**
     * @dev Updates a staking tier's active status
     * @param tierId The tier ID
     * @param active Whether the tier is active
     */
    function updateStakingTier(uint256 tierId, bool active) external onlyOwner {
        require(tierId < tierCount, "Invalid tier ID");
        stakingTiers[tierId].active = active;
        emit StakingTierUpdated(tierId, active);
    }
    
    /**
     * @dev Updates the reward rate
     * @param newRate The new reward rate
     */
    function updateRewardRate(uint256 newRate) external onlyOwner updateReward(address(0)) {
        require(newRate > 0, "Invalid reward rate");
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    /**
     * @dev Deposits reward tokens into the contract
     * @param amount The amount of reward tokens to deposit
     */
    function depositRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(rewardToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(rewardToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }
    
    /**
     * @dev Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency function to withdraw stuck tokens
     * @param token The token address
     * @param amount The amount to withdraw
     */
    function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(stakingToken), "Cannot withdraw staking token");
        IERC20(token).transfer(owner(), amount);
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    /**
     * @dev Internal function to add a staking tier
     * @param duration The lock duration in seconds
     * @param multiplier The reward multiplier
     */
    function _addStakingTier(uint256 duration, uint256 multiplier) internal {
        require(duration > 0, "Invalid duration");
        require(multiplier > 0, "Invalid multiplier");
        
        stakingTiers[tierCount] = StakingTier({
            duration: duration,
            multiplier: multiplier,
            active: true
        });
        
        emit StakingTierAdded(tierCount, duration, multiplier);
        tierCount++;
    }
    
    /**
     * @dev Internal function to get user's total staked amount
     * @param user The user address
     * @return The total staked amount
     */
    function _getUserTotalStaked(address user) internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active) {
                total += userStakes[user][i].amount;
            }
        }
        return total;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
 * @title Airdrop Contract
 * @dev A secure airdrop contract with pause functionality and reentrancy protection
 * @notice Allows owners to distribute tokens to users in a controlled manner
 */
contract Airdrop is Ownable, ReentrancyGuard, Pausable {
    // Amount of tokens each user receives
    uint256 public immutable airdropAmount;
    
    // When the airdrop starts (deployment time)
    uint256 public immutable startTime;
    
    // When the airdrop ends
    uint256 public immutable endTime;
    
    // Remaining total amount available for airdrop
    uint256 public totalAmount;
    
    // The ERC20 token contract address
    IERC20 public immutable tokenAddress;
    


    /**
     * @dev User structure to store airdrop information
     * @param amount The amount of tokens allocated to this user
     * @param isClaimed Whether the user has claimed their airdrop
     * @param user The user's address
     */
    struct User {
        uint256 amount;
        bool isClaimed;
        address user;
    }

    // Array to store all users for easy iteration
    User[] public userList;

    // Mapping from user address to User struct for quick lookups
    mapping(address => User) private users;
    
    // Mapping from user address to their index in userList for efficient deletion
    mapping(address => uint256) private userIndex;

    /**
     * @dev Emitted when a user successfully claims their airdrop
     * @param user The address of the user who claimed
     * @param amount The amount of tokens claimed
     */
    event Airdropped(address indexed user, uint256 amount);

    /**
     * @dev Ensures the contract has sufficient token balance for airdrops
     */
    modifier sufficientTokenBalance() {
        require(tokenAddress.balanceOf(address(this)) > 0, "Insufficient token balance");
        _;
    }

    /**
     * @dev Ensures the airdrop has not ended (totalAmount > 0)
     */
    modifier endAirdrop() {
        require(totalAmount == 0, "Airdrop has ended");
        _;
    }

    /**
     * @dev Ensures the caller is a registered user who hasn't claimed yet
     */
    modifier onlyUser() {
        require(users[msg.sender].user == msg.sender, "You are not a user");
        require(!users[msg.sender].isClaimed, "You have already claimed");
        _;
    }

    /**
     * @dev Ensures the airdrop is currently active (within time window)
     */
    modifier airdropActive() {
        require(block.timestamp >= startTime, "Airdrop has not started yet");
        require(block.timestamp <= endTime, "Airdrop has ended");
        _;
    }

    /**
     * @dev Ensures the airdrop has not started yet (for adding users)
     */
    modifier airdropNotStarted() {
        require(endTime > startTime, "Airdrop has already started");
        _;
    }

    /**
     * @dev Constructor to initialize the airdrop contract
     * @param _tokenAddress The ERC20 token contract address
     * @param _totalAmount Total amount of tokens available for airdrop
     * @param _airdropAmount Amount of tokens each user will receive
     * @param _endTime When the airdrop period ends
     */
    constructor(
        address _tokenAddress, 
        uint256 _totalAmount, 
        uint256 _airdropAmount, 
        uint256 _endTime
    ) Ownable(msg.sender) {
        // Validate input parameters
        require(_endTime > block.timestamp, "End time must be after start time");
        require(_totalAmount > 0, "Total amount must be greater than 0");
        require(_airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_tokenAddress != address(0), "Invalid token address");
        
        // Initialize contract state
        startTime = block.timestamp;
        tokenAddress = IERC20(_tokenAddress);
        totalAmount = _totalAmount;
        airdropAmount = _airdropAmount;
        endTime = _endTime;
    }

    /**
     * @dev Adds a new user to the airdrop list
     * @param _user The address of the user to add
     * @notice Only owner can call this function before airdrop starts
     */
    function addUser(address _user) external onlyOwner airdropNotStarted {
        // Check if user already exists or has claimed
        require(users[_user].amount == 0, "User already exists");
        require(users[_user].isClaimed == false, "User is already claimed");

        // Update contract state
        totalAmount -= airdropAmount;
        userIndex[_user] = userList.length;
        users[_user] = User(airdropAmount, false, _user);
        userList.push(User(airdropAmount, false, _user));
    }



    /**
     * @dev Allows users to claim their airdrop tokens
     * @notice Users can only claim once and must be registered
     * @notice Protected against reentrancy attacks and can be paused
     */
    function airdrop() external onlyUser airdropActive sufficientTokenBalance whenNotPaused nonReentrant {
        // Mark user as claimed
        users[msg.sender] = User(airdropAmount, true, msg.sender);
        
        // Transfer tokens to user
        require(
            tokenAddress.transfer(msg.sender, airdropAmount),
            "Token transfer failed"
        );
        
        // Emit event
        emit Airdropped(msg.sender, airdropAmount);
    }


    /**
     * @dev Removes a user from the airdrop list
     * @param _user The address of the user to remove
     * @notice Only owner can call this function
     */
    function deleteUser(address _user) external onlyOwner {
        // Validate user exists and hasn't claimed
        require(users[_user].user == _user, "User not found");
        require(users[_user].isClaimed == false, "User has already claimed"); 

        // Get user's index in the list
        uint256 index = userIndex[_user];
        require(index < userList.length, "Invalid user index");
        require(userList[index].user == _user, "User index mismatch");

        // Efficiently remove user by swapping with last element
        if (index < userList.length - 1) {
            userList[index] = userList[userList.length - 1];
            userIndex[userList[index].user] = index; 
        }

        // Clean up data structures
        userList.pop();
        delete userIndex[_user]; 
        delete users[_user];
        totalAmount += airdropAmount; 
    }


    /**
     * @dev Returns user details for a specific address
     * @param _user The address to query
     * @return User struct containing amount, claim status, and address
     */
    function getUser(address _user) external view onlyOwner returns (User memory) {
        return users[_user];
    }

    /**
     * @dev Returns the complete list of all users
     * @return Array of all User structs
     */
    function getUserList() external view onlyOwner returns (User[] memory) {
        return userList;
    }

    /**
     * @dev Checks if the airdrop is currently active
     * @return True if airdrop is within the time window
     */
    function isAirdropActive() external view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    /**
     * @dev Returns time remaining until airdrop starts
     * @return Seconds until start, or 0 if already started
     */
    function getTimeUntilStart() external view returns (uint256) {
        if (block.timestamp >= startTime) return 0;
        return startTime - block.timestamp;
    }

    /**
     * @dev Returns time remaining until airdrop ends
     * @return Seconds until end, or 0 if already ended
     */
    function getTimeUntilEnd() external view returns (uint256) {
        if (block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }

    // Get current airdrop status
    function getAirdropStatus() external view returns (
        bool _isActive,
        bool _hasStarted,
        bool _hasEnded,
        uint256 _currentTime,
        uint256 _timeUntilStart,
        uint256 _timeUntilEnd
    ) {
        bool hasStarted = block.timestamp >= startTime;
        bool hasEnded = block.timestamp >= endTime;
        bool isActive = hasStarted && !hasEnded;
        
        return (
            isActive,
            hasStarted,
            hasEnded,
            block.timestamp,
            hasStarted ? 0 : startTime - block.timestamp,
            hasEnded ? 0 : endTime - block.timestamp
        );
    }

    /**
     * @dev Emergency function to pause all airdrop operations
     * @notice Only owner can call this function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes airdrop operations after being paused
     * @notice Only owner can call this function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency function to withdraw all tokens from contract
     * @notice Only owner can call this when contract is paused
     * @notice This is a safety mechanism for emergency situations
     */
    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 balance = tokenAddress.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(
            tokenAddress.transfer(owner(), balance),
            "Token transfer failed"
        );
    }

    /**
     * @dev Returns the current owner address
     * @return The address of the contract owner
     */
    function getOwner() external view returns (address) {
        return owner();
    }
}
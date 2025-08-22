// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Airdrop {
    address public immutable owner;
    uint256 public immutable airdropAmount;
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256 public totalAmount;
    IERC20 public immutable tokenAddress;
    


    struct User{
        uint256 amount;
        bool isClaimed;
        address user;
    }

    User[] public userList;

    mapping(address => User) private users;

    event Airdropped(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier sufficientTokenBalance() {
        require(tokenAddress.balanceOf(address(this)) > 0, "Insufficient token balance");
        _;
    }

    modifier endAirdrop() {
        require(totalAmount == 0, "Airdrop has ended");
        _;
    }

    modifier onlyUser() {
        require(users[msg.sender].user == msg.sender, "You are not a user");
        require(!users[msg.sender].isClaimed, "You have already claimed");
        _;
    }

    modifier airdropActive() {
        require(block.timestamp >= startTime, "Airdrop has not started yet");
        require(block.timestamp <= endTime, "Airdrop has ended");
        _;
    }

    modifier airdropNotStarted() {
        require(endTime > startTime, "Airdrop has already started");
        _;
    }

    constructor(
        address _owner, 
        address _tokenAddress, 
        uint256 _totalAmount, 
        uint256 _airdropAmount, 
        uint256 _endTime
    ) {
        require(_endTime > block.timestamp, "End time must be after start time");
        require(_totalAmount > 0, "Total amount must be greater than 0");
        require(_airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_tokenAddress != address(0), "Invalid token address");
        
        startTime = block.timestamp;
        owner = _owner;
        tokenAddress = IERC20(_tokenAddress);
        totalAmount = _totalAmount;
        airdropAmount = _airdropAmount;
        endTime = _endTime;
 
    }

    // Add user to airdrop
    function addUser(address _user) external onlyOwner airdropNotStarted {
        require(users[_user].amount == 0, "User already exists");
        require(users[_user].isClaimed == false, "User is already claimed");

        totalAmount -= airdropAmount;
        users[_user] = User(airdropAmount, false, _user);
        userList.push(User(airdropAmount, false, _user));
    }



    // Get Airdrop
    function airdrop() external onlyUser airdropActive sufficientTokenBalance {
        users[msg.sender] = User(airdropAmount, true, msg.sender);
        require(
            tokenAddress.transfer(msg.sender, airdropAmount),
            "Token transfer failed"
        );
        emit Airdropped(msg.sender, airdropAmount);
    }

    // Get user details
    function getUser(address _user) external view onlyOwner returns (User memory) {
        return users[_user];
    }

    // Check if airdrop is currently active
    function isAirdropActive() external view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    // Get remaining time until airdrop starts
    function getTimeUntilStart() external view returns (uint256) {
        if (block.timestamp >= startTime) return 0;
        return startTime - block.timestamp;
    }

    // Get remaining time until airdrop ends
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
}
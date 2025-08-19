// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is IERC20, ReentrancyGuard, Pausable, Ownable {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) public _balanceOf;
    mapping(address => mapping(address => uint256)) public _allowance;

    // Note: Transfer and Approval events are already defined in IERC20 interface
    // so we don't need to declare them again

    constructor(uint256 totalSupplyAmount, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) 
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        _totalSupply = totalSupplyAmount * (10 ** tokenDecimals); // Solidity 0.8+ has built-in overflow protection
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        _balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // IERC20 interface functions - these must match exactly
    function name() public view returns (string memory) {
        return _name;    
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view  returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function transfer(address to, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than 0");
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        _balanceOf[msg.sender] -= amount;
        _balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        require(spender != address(0), "Approve to zero address");
        require(amount > 0, "Approve amount must be greater than 0");
        
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than 0");
        require(_balanceOf[from] >= amount, "Insufficient balance");
        require(_allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        _allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        require(to != address(0), "Mint to zero address");
        require(amount > 0, "Mint amount must be greater than 0");
        
        _balanceOf[to] += amount;
        _totalSupply += amount;
        
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Burn amount must be greater than 0");
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        _balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }

    // Pause and unpause functions - only owner can call
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Emergency functions for owner
    function emergencyWithdraw(address token, uint256 amount) public onlyOwner {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer any ERC20 tokens stuck in contract
        IERC20(token).transfer(owner(), amount);
    }

    function emergencyWithdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success, ) = owner().call{value: balance}("");
        require(success, "ETH transfer failed");
    }
}
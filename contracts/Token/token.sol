// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SuperToken - ERC20 Token Contract
 * @dev A secure, pausable ERC20 token with mint/burn functionality
 * @notice Implements the standard ERC20 interface with additional security features
 * @notice Includes reentrancy protection, pausability, and emergency functions
 */
contract Token is IERC20, ReentrancyGuard, Pausable, Ownable {
    // Token metadata
    string public _name;           // Token name (e.g., "SuperToken")
    string public _symbol;         // Token symbol (e.g., "SUPER")
    uint8 public _decimals;        // Token decimal places (typically 18)
    uint256 public _totalSupply;   // Total circulating supply

    // Token balances and allowances
    mapping(address => uint256) public _balanceOf;                                    // User balances
    mapping(address => mapping(address => uint256)) public _allowance;                 // Spending allowances

    // Note: Transfer and Approval events are already defined in IERC20 interface
    // so we don't need to declare them again

    /**
     * @dev Constructor to initialize the token contract
     * @param totalSupplyAmount Initial token supply amount
     * @param tokenName Name of the token
     * @param tokenSymbol Symbol of the token
     * @param tokenDecimals Number of decimal places
     * @notice All initial tokens are assigned to the deployer
     */
    constructor(uint256 totalSupplyAmount, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) 
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        // Calculate total supply with decimals (e.g., 1000 * 10^18 = 1000 tokens)
        _totalSupply = totalSupplyAmount * (10 ** tokenDecimals);
        
        // Set token metadata
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        
        // Assign all initial tokens to the deployer
        _balanceOf[msg.sender] = _totalSupply;
        
        // Emit transfer event from zero address to deployer (minting)
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // ============ IERC20 INTERFACE FUNCTIONS ============
    
    /**
     * @dev Returns the name of the token
     * @return The token name
     */
    function name() public view returns (string memory) {
        return _name;    
    }

    /**
     * @dev Returns the symbol of the token
     * @return The token symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used for token amounts
     * @return The number of decimals
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of tokens
     * @return The total token supply
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of tokens for a specific account
     * @param account The address to query
     * @return The token balance of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    /**
     * @dev Returns the amount of tokens the spender is allowed to spend on behalf of the owner
     * @param owner The address that owns the tokens
     * @param spender The address that can spend the tokens
     * @return The amount of tokens the spender can spend
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    // ============ CORE TRANSFER FUNCTIONS ============
    
    /**
     * @dev Transfers tokens from the caller to a specified address
     * @param to The recipient address
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful
     * @notice Protected against reentrancy and can be paused
     */
    function transfer(address to, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        // Validate recipient address
        require(to != address(0), "Transfer to zero address");
        
        // Validate transfer amount
        require(amount > 0, "Transfer amount must be greater than 0");
        
        // Check sufficient balance
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        // Update balances
        _balanceOf[msg.sender] -= amount;
        _balanceOf[to] += amount;
        
        // Emit transfer event
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Approves a spender to spend tokens on behalf of the caller
     * @param spender The address that can spend the tokens
     * @param amount The amount of tokens the spender can spend
     * @return True if the approval was successful
     * @notice Can be paused by owner
     */
    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        // Validate spender address
        require(spender != address(0), "Approve to zero address");
        
        // Validate approval amount
        require(amount > 0, "Approve amount must be greater than 0");
        
        // Set allowance
        _allowance[msg.sender][spender] = amount;
        
        // Emit approval event
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another using allowance
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful
     * @notice Protected against reentrancy and can be paused
     */
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        // Validate addresses
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        
        // Validate transfer amount
        require(amount > 0, "Transfer amount must be greater than 0");
        
        // Check sufficient balance and allowance
        require(_balanceOf[from] >= amount, "Insufficient balance");
        require(_allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        // Update balances and allowance
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        _allowance[from][msg.sender] -= amount;
        
        // Emit transfer event
        emit Transfer(from, to, amount);
        return true;
    }

    // ============ MINT & BURN FUNCTIONS ============
    
    /**
     * @dev Mints new tokens and assigns them to a specified address
     * @param to The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     * @notice Only owner can call this function
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        // Validate recipient address
        require(to != address(0), "Mint to zero address");
        
        // Validate mint amount
        require(amount > 0, "Mint amount must be greater than 0");
        
        // Update balances and total supply
        _balanceOf[to] += amount;
        _totalSupply += amount;
        
        // Emit transfer event from zero address (minting)
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Burns tokens from the caller's balance
     * @param amount The amount of tokens to burn
     * @notice Protected against reentrancy and can be paused
     */
    function burn(uint256 amount) public whenNotPaused nonReentrant {
        // Validate burn amount
        require(amount > 0, "Burn amount must be greater than 0");
        
        // Check sufficient balance
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        // Update balances and total supply
        _balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        
        // Emit transfer event to zero address (burning)
        emit Transfer(msg.sender, address(0), amount);
    }

    // ============ PAUSE & EMERGENCY FUNCTIONS ============
    
    /**
     * @dev Pauses all token operations (transfers, approvals, minting, burning)
     * @notice Only owner can call this function
     * @notice This is a safety mechanism for emergency situations
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes all token operations after being paused
     * @notice Only owner can call this function
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency function to withdraw ERC20 tokens stuck in the contract
     * @param token The address of the ERC20 token to withdraw
     * @param amount The amount of tokens to withdraw
     * @notice Only owner can call this function
     * @notice Useful for recovering tokens sent to the contract by mistake
     */
    function emergencyWithdraw(address token, uint256 amount) public onlyOwner {
        // Validate token address
        require(token != address(0), "Invalid token address");
        
        // Validate amount
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens to owner
        IERC20(token).transfer(owner(), amount);
    }

    /**
     * @dev Emergency function to withdraw ETH stuck in the contract
     * @notice Only owner can call this function
     * @notice Useful for recovering ETH sent to the contract by mistake
     */
    function emergencyWithdrawETH() public onlyOwner {
        // Get current ETH balance
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        // Transfer ETH to owner
        (bool success, ) = owner().call{value: balance}("");
        require(success, "ETH transfer failed");
    }

    // ============ TESTING & UTILITY FUNCTIONS ============
    
    /**
     * @dev Utility function for testing purposes
     * @return The address of the message sender
     * @notice This function is only used for testing and debugging
     */
    function getSender() public view returns (address) {
        return msg.sender;
    }
}
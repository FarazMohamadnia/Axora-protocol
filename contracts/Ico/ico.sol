// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC20 interface for token interactions
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Import Chainlink's price feed interface for ETH/USD price data
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title ICO (Initial Coin Offering) Contract
 * @dev This contract manages an Initial Coin Offering where users can purchase tokens
 * using either USDT or ETH. The contract integrates with Chainlink price feeds
 * to get real-time ETH/USD prices for accurate token calculations.
 * 
 * Key Features:
 * - Token purchases with USDT (1:1 USD value)
 * - Token purchases with ETH (converted to USD using price feed)
 * - Owner can deposit tokens for sale
 * - Owner can withdraw collected funds
 * - Real-time price oracle integration
 */
contract ICO {
    // Token contract instance - the token being sold in the ICO
    IERC20 public token; 
    // USDT contract instance - for USDT payments
    IERC20 public usdt;
    // Chainlink price feed for ETH/USD price data
    AggregatorV3Interface public priceFeed;
    // Contract owner address
    address public owner;
    // Price of one token in USDT (with 6 decimals)
    uint256 public tokenPriceInUSDT; 
    // Total amount of tokens deposited by owner for sale
    uint256 public totalTokensDeposited;
    // Total USDT collected from token sales
    uint256 public totalUSDTCollected;
    // Total ETH collected from token sales
    uint256 public totalETHCollected;

    // Events for tracking important contract activities
    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 amountPaid, string currency, uint256 tokenAmount);
    event Withdrawal(address indexed owner, uint256 amount, string currency);

    /**
     * @dev Modifier to restrict function access to contract owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev Constructor initializes the ICO contract with required parameters
     * @param _tokenAddress Address of the token contract being sold
     * @param _usdtAddress Address of the USDT contract for payments
     * @param _priceFeedAddress Address of Chainlink ETH/USD price feed
     * @param _tokenPriceInUSDT Price of one token in USDT (with 6 decimals)
     */
    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _priceFeedAddress,
        uint256 _tokenPriceInUSDT 
    ) {
        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        owner = msg.sender;
        tokenPriceInUSDT = _tokenPriceInUSDT;
    }

    /**
     * @dev Gets the latest ETH/USD price from Chainlink price feed
     * @return Current ETH price in USD with 8 decimals
     * @notice This function calls the external Chainlink oracle
     */
    function getLatestETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price from oracle");
        return uint256(price); // Price has 8 decimals
    }

    /**
     * @dev Calculates how many tokens a user will receive for a given ETH amount
     * @param ethAmount Amount of ETH sent (in wei)
     * @return Number of tokens to be received
     * @notice Uses current ETH/USD price to convert ETH to USD, then calculates tokens
     */
    function calculateTokenAmountForETH(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPriceInUSD = getLatestETHPrice(); // 8 decimals
        uint256 usdValue = (ethAmount * ethPriceInUSD) / 1e8; // Convert to USD (18 decimals)
        uint256 tokenAmount = (usdValue * 1e6) / tokenPriceInUSDT; // Calculate tokens (18 decimals)
        return tokenAmount;
    }

    /**
     * @dev Allows owner to deposit tokens into the contract for sale
     * @param amount Number of tokens to deposit (with 18 decimals)
     * @notice Only the contract owner can call this function
     * @notice Tokens must be approved for transfer to this contract first
     */
    function depositTokens(uint256 amount) external onlyOwner {
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        totalTokensDeposited = totalTokensDeposited + amount;
        emit TokensDeposited(msg.sender, amount);
    }

    /**
     * @dev Allows users to purchase tokens using USDT
     * @param usdtAmount Amount of USDT to spend (with 6 decimals)
     * @notice USDT must be approved for transfer to this contract first
     * @notice Token calculation: (usdtAmount * 1e18) / tokenPriceInUSDT
     */
    function buyTokensWithUSDT(uint256 usdtAmount) external {
        require(usdtAmount > 0, "USDT amount must be greater than 0");
        // Calculate tokens: USDT amount * 1e18 / token price (to handle decimals)
        uint256 tokenAmount = (usdtAmount * 1e18) / tokenPriceInUSDT;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        // Transfer USDT from buyer to contract
        require(usdt.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");
        // Transfer tokens from contract to buyer
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        totalUSDTCollected = totalUSDTCollected + usdtAmount;
        emit TokensPurchased(msg.sender, usdtAmount, "USDT", tokenAmount);
    }

    /**
     * @dev Allows users to purchase tokens using ETH
     * @notice This is a payable function - ETH is sent with the transaction
     * @notice Token amount is calculated based on current ETH/USD price
     * @notice Uses Chainlink price feed for accurate ETH valuation
     */
    function buyTokensWithETH() external payable {
        require(msg.value > 0, "ETH amount must be greater than 0");
        uint256 tokenAmount = calculateTokenAmountForETH(msg.value);
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        // Transfer tokens from contract to buyer
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        totalETHCollected = totalETHCollected + msg.value;
        emit TokensPurchased(msg.sender, msg.value, "ETH", tokenAmount);
    }

    /**
     * @dev Allows owner to withdraw collected USDT from the contract
     * @param amount Amount of USDT to withdraw (with 6 decimals)
     * @notice Only the contract owner can call this function
     */
    function withdrawUSDT(uint256 amount) external onlyOwner {
        require(amount <= usdt.balanceOf(address(this)), "Not enough USDT in contract");
        require(usdt.transfer(owner, amount), "USDT transfer failed");
        emit Withdrawal(owner, amount, "USDT");
    }

    /**
     * @dev Allows owner to withdraw collected ETH from the contract
     * @param amount Amount of ETH to withdraw (in wei)
     * @notice Only the contract owner can call this function
     * @notice Uses low-level call for ETH transfer
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH in contract");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH transfer failed");
        emit Withdrawal(owner, amount, "ETH");
    }

    /**
     * @dev Returns the current token balance of the contract
     * @return Number of tokens available for sale
     */
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns the current USDT balance of the contract
     * @return Amount of USDT collected from sales
     */
    function getUSDTBalance() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    /**
     * @dev Returns the current ETH balance of the contract
     * @return Amount of ETH collected from sales (in wei)
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to receive ETH
     * @notice Allows the contract to receive ETH directly
     */
    receive() external payable {}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract ICO {
    IERC20 public token; 
    IERC20 public usdt;
    AggregatorV3Interface public priceFeed;
    address public owner;
    uint256 public tokenPriceInUSDT; 
    uint256 public totalTokensDeposited;
    uint256 public totalUSDTCollected;
    uint256 public totalETHCollected;

    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 amountPaid, string currency, uint256 tokenAmount);
    event Withdrawal(address indexed owner, uint256 amount, string currency);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

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

   
    function getLatestETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price from oracle");
        return uint256(price); // قیمت به صورت 8 اعشار (مثلاً 2000 دلار = 200000000000)
    }

    
    function calculateTokenAmountForETH(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPriceInUSD = getLatestETHPrice(); 
        uint256 usdValue = (ethAmount * ethPriceInUSD) / 1e8; 
        uint256 tokenAmount = (usdValue * 1e6) / tokenPriceInUSDT;
        return tokenAmount;
    }

    // واریز توکن‌ها توسط صاحب
    function depositTokens(uint256 amount) external onlyOwner {
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        totalTokensDeposited = totalTokensDeposited + amount;
        emit TokensDeposited(msg.sender, amount);
    }

    // خرید توکن با USDT
    function buyTokensWithUSDT(uint256 usdtAmount) external {
        require(usdtAmount > 0, "USDT amount must be greater than 0");
        uint256 tokenAmount = (usdtAmount * 1e18) / tokenPriceInUSDT;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        require(usdt.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        totalUSDTCollected = totalUSDTCollected + usdtAmount;
        emit TokensPurchased(msg.sender, usdtAmount, "USDT", tokenAmount);
    }

   
    function buyTokensWithETH() external payable {
        require(msg.value > 0, "ETH amount must be greater than 0");
        uint256 tokenAmount = calculateTokenAmountForETH(msg.value);
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        totalETHCollected = totalETHCollected + msg.value;
        emit TokensPurchased(msg.sender, msg.value, "ETH", tokenAmount);
    }

    
    function withdrawUSDT(uint256 amount) external onlyOwner {
        require(amount <= usdt.balanceOf(address(this)), "Not enough USDT in contract");
        require(usdt.transfer(owner, amount), "USDT transfer failed");
        emit Withdrawal(owner, amount, "USDT");
    }

    
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH in contract");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH transfer failed");
        emit Withdrawal(owner, amount, "ETH");
    }

   
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

   
    function getUSDTBalance() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

   
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    
    receive() external payable {}
}
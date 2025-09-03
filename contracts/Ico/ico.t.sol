// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./ico.sol";
import "../Token/token.sol";

// Mock USDT contract for testing
contract MockUSDT {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

// Mock Chainlink Price Feed for testing
contract MockPriceFeed {
    int256 private price;
    
    constructor(int256 _price) {
        price = _price;
    }
    
    function setPrice(int256 _price) external {
        price = _price;
    }
    
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, price, block.timestamp, block.timestamp, 1);
    }
}

contract ICOTest is Test {
    ICO public ico;
    Token public token;
    MockUSDT public usdt;
    MockPriceFeed public priceFeed;
    
    address public owner = address(1);
    address public buyer1 = address(2);
    address public buyer2 = address(3);
    address public buyer3 = address(4);
    
    uint256 public constant TOKEN_PRICE_USDT = 1000000; // $1.00 in USDT (6 decimals)
    uint256 public constant INITIAL_TOKEN_SUPPLY = 1000000 * 10**18; // 1M tokens
    uint256 public constant INITIAL_USDT_SUPPLY = 1000000 * 10**6; // 1M USDT
    uint256 public constant ETH_PRICE_USD = 2000 * 10**8; // $2000 per ETH (8 decimals)
    
    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 amountPaid, string currency, uint256 tokenAmount);
    event Withdrawal(address indexed owner, uint256 amount, string currency);
    
    function setUp() public {
        // Deploy contracts
        vm.startPrank(owner);
        
        token = new Token(INITIAL_TOKEN_SUPPLY / 10**18, "SuperToken", "SUPER", 18);
        usdt = new MockUSDT(INITIAL_USDT_SUPPLY);
        priceFeed = new MockPriceFeed(int256(ETH_PRICE_USD));
        
        ico = new ICO(
            address(token),
            address(usdt),
            address(priceFeed),
            TOKEN_PRICE_USDT
        );
        
        vm.stopPrank();
        
        // Fund test accounts
        vm.startPrank(owner);
        usdt.transfer(buyer1, 10000 * 10**6); // 10k USDT
        usdt.transfer(buyer2, 10000 * 10**6); // 10k USDT
        usdt.transfer(buyer3, 10000 * 10**6); // 10k USDT
        vm.stopPrank();
        
        // Fund ETH to buyers
        vm.deal(buyer1, 10 ether);
        vm.deal(buyer2, 10 ether);
        vm.deal(buyer3, 10 ether);
    }
    
    // ============ CONSTRUCTOR TESTS ============
    
    function testConstructor() public {
        assertEq(address(ico.token()), address(token));
        assertEq(address(ico.usdt()), address(usdt));
        assertEq(address(ico.priceFeed()), address(priceFeed));
        assertEq(ico.owner(), owner);
        assertEq(ico.tokenPriceInUSDT(), TOKEN_PRICE_USDT);
        assertEq(ico.totalTokensDeposited(), 0);
        assertEq(ico.totalUSDTCollected(), 0);
        assertEq(ico.totalETHCollected(), 0);
    }
    
    // ============ PRICE FEED TESTS ============
    
    function testGetLatestETHPrice() public {
        uint256 price = ico.getLatestETHPrice();
        assertEq(price, ETH_PRICE_USD);
    }
    
    function testGetLatestETHPriceWithUpdatedPrice() public {
        // Update price feed
        priceFeed.setPrice(int256(3000 * 10**8)); // $3000 per ETH
        
        uint256 price = ico.getLatestETHPrice();
        assertEq(price, 3000 * 10**8);
    }
    
    function testGetLatestETHPriceRevertsOnInvalidPrice() public {
        // Set negative price
        priceFeed.setPrice(-1000 * 10**8);
        
        vm.expectRevert("Invalid price from oracle");
        ico.getLatestETHPrice();
    }
    
    // ============ TOKEN CALCULATION TESTS ============
    
    function testCalculateTokenAmountForETH() public {
        uint256 ethAmount = 1 ether; // 1 ETH
        uint256 expectedTokens = (ethAmount * ETH_PRICE_USD) / 1e8; // Convert to USD
        expectedTokens = (expectedTokens * 1e6) / TOKEN_PRICE_USDT; // Convert to tokens
        
        uint256 actualTokens = ico.calculateTokenAmountForETH(ethAmount);
        assertEq(actualTokens, expectedTokens);
    }
    
    function testCalculateTokenAmountForETHWithDifferentPrices() public {
        // Test with $3000 ETH price
        priceFeed.setPrice(int256(3000 * 10**8));
        
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = (ethAmount * 3000 * 10**8) / 1e8;
        expectedTokens = (expectedTokens * 1e6) / TOKEN_PRICE_USDT;
        
        uint256 actualTokens = ico.calculateTokenAmountForETH(ethAmount);
        assertEq(actualTokens, expectedTokens);
    }
    
    // ============ TOKEN DEPOSIT TESTS ============
    
    function testDepositTokens() public {
        uint256 depositAmount = 1000 * 10**18; // 1000 tokens
        
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        
        vm.expectEmit(true, false, false, true);
        emit TokensDeposited(owner, depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        assertEq(ico.totalTokensDeposited(), depositAmount);
        assertEq(ico.getTokenBalance(), depositAmount);
    }
    
    function testDepositTokensRevertsWhenNotOwner() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.startPrank(buyer1);
        token.approve(address(ico), depositAmount);
        
        vm.expectRevert("Only owner can call this function");
        ico.depositTokens(depositAmount);
        vm.stopPrank();
    }
    
    function testDepositTokensRevertsWhenInsufficientAllowance() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.startPrank(owner);
        // Don't approve tokens
        
        vm.expectRevert("Token transfer failed");
        ico.depositTokens(depositAmount);
        vm.stopPrank();
    }
    
    // ============ USDT PURCHASE TESTS ============
    
    function testBuyTokensWithUSDT() public {
        uint256 depositAmount = 10000 * 10**18; // 10k tokens
        uint256 usdtAmount = 1000 * 10**6; // $1000 USDT
        uint256 expectedTokens = (usdtAmount * 1e18) / TOKEN_PRICE_USDT; // 1000 tokens
        
        // Deposit tokens first
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        // Buy tokens with USDT
        vm.startPrank(buyer1);
        usdt.approve(address(ico), usdtAmount);
        
        vm.expectEmit(true, false, false, true);
        emit TokensPurchased(buyer1, usdtAmount, "USDT", expectedTokens);
        ico.buyTokensWithUSDT(usdtAmount);
        vm.stopPrank();
        
        assertEq(ico.totalUSDTCollected(), usdtAmount);
        assertEq(token.balanceOf(buyer1), expectedTokens);
        assertEq(usdt.balanceOf(address(ico)), usdtAmount);
    }
    
    function testBuyTokensWithUSDTRevertsWhenZeroAmount() public {
        vm.startPrank(buyer1);
        usdt.approve(address(ico), 1000 * 10**6);
        
        vm.expectRevert("USDT amount must be greater than 0");
        ico.buyTokensWithUSDT(0);
        vm.stopPrank();
    }
    
    function testBuyTokensWithUSDTRevertsWhenInsufficientTokens() public {
        uint256 depositAmount = 500 * 10**18; // 500 tokens
        uint256 usdtAmount = 1000 * 10**6; // $1000 USDT (would buy 1000 tokens)
        
        // Deposit only 500 tokens
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        // Try to buy 1000 tokens
        vm.startPrank(buyer1);
        usdt.approve(address(ico), usdtAmount);
        
        vm.expectRevert("Not enough tokens available");
        ico.buyTokensWithUSDT(usdtAmount);
        vm.stopPrank();
    }
    
    function testBuyTokensWithUSDTRevertsWhenInsufficientAllowance() public {
        uint256 depositAmount = 1000 * 10**18;
        uint256 usdtAmount = 1000 * 10**6;
        
        // Deposit tokens
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        // Try to buy without approval
        vm.startPrank(buyer1);
        // Don't approve USDT
        
        vm.expectRevert("USDT transfer failed");
        ico.buyTokensWithUSDT(usdtAmount);
        vm.stopPrank();
    }
    
    // ============ ETH PURCHASE TESTS ============
    
    function testBuyTokensWithETH() public {
        uint256 depositAmount = 10000 * 10**18; // 10k tokens
        uint256 ethAmount = 1 ether; // 1 ETH
        uint256 expectedTokens = ico.calculateTokenAmountForETH(ethAmount);
        
        // Deposit tokens first
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        // Buy tokens with ETH
        vm.startPrank(buyer1);
        
        vm.expectEmit(true, false, false, true);
        emit TokensPurchased(buyer1, ethAmount, "ETH", expectedTokens);
        ico.buyTokensWithETH{value: ethAmount}();
        vm.stopPrank();
        
        assertEq(ico.totalETHCollected(), ethAmount);
        assertEq(token.balanceOf(buyer1), expectedTokens);
        assertEq(address(ico).balance, ethAmount);
    }
    
    function testBuyTokensWithETHRevertsWhenZeroAmount() public {
        vm.startPrank(buyer1);
        
        vm.expectRevert("ETH amount must be greater than 0");
        ico.buyTokensWithETH{value: 0}();
        vm.stopPrank();
    }
    
    function testBuyTokensWithETHRevertsWhenInsufficientTokens() public {
        uint256 depositAmount = 500 * 10**18; // 500 tokens
        uint256 ethAmount = 1 ether; // 1 ETH (would buy more than 500 tokens)
        
        // Deposit only 500 tokens
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        // Try to buy with ETH
        vm.startPrank(buyer1);
        
        vm.expectRevert("Not enough tokens available");
        ico.buyTokensWithETH{value: ethAmount}();
        vm.stopPrank();
    }
    
    // ============ WITHDRAWAL TESTS ============
    
    function testWithdrawUSDT() public {
        uint256 usdtAmount = 1000 * 10**6;
        
        // First collect some USDT
        uint256 depositAmount = 1000 * 10**18;
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        usdt.approve(address(ico), usdtAmount);
        ico.buyTokensWithUSDT(usdtAmount);
        vm.stopPrank();
        
        // Withdraw USDT
        vm.startPrank(owner);
        uint256 balanceBefore = usdt.balanceOf(owner);
        
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(owner, usdtAmount, "USDT");
        ico.withdrawUSDT(usdtAmount);
        vm.stopPrank();
        
        uint256 balanceAfter = usdt.balanceOf(owner);
        assertEq(balanceAfter - balanceBefore, usdtAmount);
    }
    
    function testWithdrawUSDTRevertsWhenNotOwner() public {
        vm.startPrank(buyer1);
        
        vm.expectRevert("Only owner can call this function");
        ico.withdrawUSDT(1000 * 10**6);
        vm.stopPrank();
    }
    
    function testWithdrawUSDTRevertsWhenInsufficientBalance() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Not enough USDT in contract");
        ico.withdrawUSDT(1000 * 10**6);
        vm.stopPrank();
    }
    
    function testWithdrawETH() public {
        uint256 ethAmount = 1 ether;
        
        // First collect some ETH
        uint256 depositAmount = 10000 * 10**18;
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        ico.buyTokensWithETH{value: ethAmount}();
        vm.stopPrank();
        
        // Withdraw ETH
        vm.startPrank(owner);
        uint256 balanceBefore = owner.balance;
        
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(owner, ethAmount, "ETH");
        ico.withdrawETH(ethAmount);
        vm.stopPrank();
        
        uint256 balanceAfter = owner.balance;
        assertEq(balanceAfter - balanceBefore, ethAmount);
    }
    
    function testWithdrawETHRevertsWhenNotOwner() public {
        vm.startPrank(buyer1);
        
        vm.expectRevert("Only owner can call this function");
        ico.withdrawETH(1 ether);
        vm.stopPrank();
    }
    
    function testWithdrawETHRevertsWhenInsufficientBalance() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Not enough ETH in contract");
        ico.withdrawETH(1 ether);
        vm.stopPrank();
    }
    
    // ============ BALANCE QUERY TESTS ============
    
    function testGetTokenBalance() public {
        assertEq(ico.getTokenBalance(), 0);
        
        uint256 depositAmount = 1000 * 10**18;
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        assertEq(ico.getTokenBalance(), depositAmount);
    }
    
    function testGetUSDTBalance() public {
        assertEq(ico.getUSDTBalance(), 0);
        
        // Collect some USDT
        uint256 depositAmount = 1000 * 10**18;
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        usdt.approve(address(ico), 500 * 10**6);
        ico.buyTokensWithUSDT(500 * 10**6);
        vm.stopPrank();
        
        assertEq(ico.getUSDTBalance(), 500 * 10**6);
    }
    
    function testGetETHBalance() public {
        assertEq(ico.getETHBalance(), 0);
        
        // Collect some ETH
        uint256 depositAmount = 10000 * 10**18;
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        ico.buyTokensWithETH{value: 1 ether}();
        vm.stopPrank();
        
        assertEq(ico.getETHBalance(), 1 ether);
    }
    
    // ============ INTEGRATION TESTS ============
    
    function testCompleteICOScenario() public {
        uint256 depositAmount = 10000 * 10**18; // 10k tokens
        
        // 1. Owner deposits tokens
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        assertEq(ico.getTokenBalance(), depositAmount);
        
        // 2. Multiple buyers purchase with USDT
        vm.startPrank(buyer1);
        usdt.approve(address(ico), 2000 * 10**6);
        ico.buyTokensWithUSDT(2000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(buyer2);
        usdt.approve(address(ico), 1500 * 10**6);
        ico.buyTokensWithUSDT(1500 * 10**6);
        vm.stopPrank();
        
        // 3. Multiple buyers purchase with ETH
        vm.startPrank(buyer3);
        ico.buyTokensWithETH{value: 2 ether}();
        vm.stopPrank();
        
        // 4. Verify balances and totals
        assertEq(ico.totalUSDTCollected(), 3500 * 10**6);
        assertEq(ico.totalETHCollected(), 2 ether);
        assertEq(ico.getUSDTBalance(), 3500 * 10**6);
        assertEq(ico.getETHBalance(), 2 ether);
        
        // 5. Owner withdraws funds
        vm.startPrank(owner);
        ico.withdrawUSDT(2000 * 10**6);
        ico.withdrawETH(1 ether);
        vm.stopPrank();
        
        assertEq(ico.getUSDTBalance(), 1500 * 10**6);
        assertEq(ico.getETHBalance(), 1 ether);
    }
    
    // ============ EDGE CASE TESTS ============
    
    function testMultipleDeposits() public {
        uint256 deposit1 = 1000 * 10**18;
        uint256 deposit2 = 2000 * 10**18;
        
        vm.startPrank(owner);
        token.approve(address(ico), deposit1 + deposit2);
        
        ico.depositTokens(deposit1);
        assertEq(ico.totalTokensDeposited(), deposit1);
        
        ico.depositTokens(deposit2);
        assertEq(ico.totalTokensDeposited(), deposit1 + deposit2);
        vm.stopPrank();
    }
    
    function testPrecisionHandling() public {
        // Test with very small amounts
        uint256 depositAmount = 1 * 10**18; // 1 token
        uint256 usdtAmount = 1; // 1 wei of USDT
        
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        usdt.approve(address(ico), usdtAmount);
        ico.buyTokensWithUSDT(usdtAmount);
        vm.stopPrank();
    }
    
    function testReceiveFunction() public {
        // Test that contract can receive ETH directly
        vm.deal(address(ico), 0);
        assertEq(address(ico).balance, 0);
        
        payable(address(ico)).transfer(1 ether);
        assertEq(address(ico).balance, 1 ether);
    }
    
    // ============ GAS OPTIMIZATION TESTS ============
    
    function testGasUsageForTokenPurchase() public {
        uint256 depositAmount = 10000 * 10**18;
        
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        usdt.approve(address(ico), 1000 * 10**6);
        
        uint256 gasBefore = gasleft();
        ico.buyTokensWithUSDT(1000 * 10**6);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for USDT purchase:", gasUsed);
        vm.stopPrank();
    }
    
    function testGasUsageForETHPurchase() public {
        uint256 depositAmount = 10000 * 10**18;
        
        vm.startPrank(owner);
        token.approve(address(ico), depositAmount);
        ico.depositTokens(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        
        uint256 gasBefore = gasleft();
        ico.buyTokensWithETH{value: 1 ether}();
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for ETH purchase:", gasUsed);
        vm.stopPrank();
    }
}

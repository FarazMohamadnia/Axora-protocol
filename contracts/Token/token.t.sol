// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test} from "forge-std/Test.sol";
import {Token} from "./token.sol"; // Fixed case to match typical naming
import {console} from "forge-std/console.sol";

contract token is Test {
    Token public token;
    uint256 constant INITIAL_SUPPLY = 1000;
    

    function setUp() public {
        token = new Token(INITIAL_SUPPLY, "SuperToken", "SUPER", 18);
    }

    function test_totalSupply() public {
        console.log("Testing totalSupply: %s", token.totalSupply());
        uint256 totalSupply = 1000 *10**18;
        assertEq(token.totalSupply(), totalSupply, "Total supply should be 1000");
    }

    function test_name() public {
        console.log("Token name: %s", token.name());
        assertEq(token.name(), "SuperToken", "Name should be SuperToken");
    }

    function test_symbol() public {
        console.log("Token symbol: %s", token.symbol());
        assertEq(token.symbol(), "SUPER", "Symbol should be SUPER");
    }

    function test_decimals() public {
        assertEq(token.decimals(), 18, "Decimals should be 18");
    }


    function test_transfer() public {
        console.log("Testing transfer: %s", token.transfer(address(0x123), 100));
        assertEq(token.balanceOf(address(0x123)), 100, "Balance of 0x123 should be 100");
    }

    function test_transferFrom() public {
        address sender = token.getSender();
        token.approve(address(0x123), 100);
        // change msg.sender to 0x123
        vm.prank(address(0x123));
        token.transferFrom(sender, address(0x456), 100);
        assertEq(token.balanceOf(address(0x456)), 100, "Balance of 0x456 should be 100");
    }

    function test_balanceOf() public {
        token.transfer(address(0x123), 100);
        console.log("Testing balanceOf: %s", token.balanceOf(address(0x123)));
        assertEq(token.balanceOf(address(0x123)), 100, "Balance of 0x123 should be 100");
    }

    function test_allowance() public {
        address sender = token.getSender();
        token.approve(address(0x456), 100);
        assertEq(token.allowance(sender , address(0x456)), 100, "Allowance of 0x123 for 0x456 should be 100");
    }
}
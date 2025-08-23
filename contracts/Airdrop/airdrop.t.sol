// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Airdrop} from "./airdrop.sol"; // Assumes Airdrop.sol contains the Airdrop contract
import {Token} from "../Token/token.sol"; // Assumes Token.sol contains the ERC20 token contract
import {console} from "forge-std/console.sol";

contract AirdropTest is Test {
    Airdrop public airdrop;
    Token public token;
    address public contractOwner = address(0x100);
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    uint256 constant INITIAL_SUPPLY = 1000 * 10**18;
    // uint256 constant AIRDROP_AMOUNT = 100 * 10**18;
    // uint256 constant TOTAL_AMOUNT = 500 * 10**18;
    uint256 constant START_TIME_OFFSET = 1000; // 1000 seconds from now
    uint256 constant DURATION = 3600; // 1 hour duration

    function setUp() public {
        vm.startPrank(owner);
        token = new Token(INITIAL_SUPPLY, "SuperToken", "SUPER", 18);
        airdrop = new Airdrop(owner, address(token), 100, 10  , block.timestamp + 3000);
        require(token.transfer(address(airdrop), 100));
        vm.stopPrank();
    }

    function test_isAirdropActive() public {
        assertEq(airdrop.isAirdropActive(), true , "Airdrop is not active");
    }


    function test_airdrop() public {
        vm.startPrank(owner);
        airdrop.addUser(user1);
        assertEq(airdrop.getUser(user1).amount, 10 , "amount is not 10");
        assertEq(airdrop.getUser(user1).isClaimed, false , "isClaimed is not false");
        vm.stopPrank();
        vm.startPrank(user1);
        airdrop.airdrop();
        vm.stopPrank();
    }

    function test_deleteUser() public {
        vm.startPrank(owner);
        airdrop.addUser(user2);
        assertEq(airdrop.getUser(user2).amount, 10 , "amount is not 10");
        airdrop.deleteUser(user2);
        assertEq(airdrop.getUser(user2).isClaimed, false , "isClaimed is not false");
        vm.stopPrank();
        assertEq(airdrop.totalAmount(), 100 , "totalAmount is not 100");
    }


}
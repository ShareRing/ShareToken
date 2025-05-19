// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ShareTokenExtended} from "./mocks/PrevShareToken.sol";
import {PrevPrevShareToken} from "./mocks/PrevPrevShareToken.sol";

import "./mocks/PrevShareToken.sol";

contract PrevShareTokenTest is Test {
    PrevPrevShareToken public prevPrevShareToken;
    ShareTokenExtended public prevShareToken;

    address prevPrevShareTokenAddress;

    address admin = address(1000);
    address pauser = address(1001);
    address minter = address(1002);
    address userA = address(1003);
    address userB = address(1004);
    address userC = address(1005);

    error NoPrevShareToken(address tokenOwner);

    uint256 public constant PREV_DECIMAL_MUL = 10 ** 2;

    function setUp() public {
        // set up previous ShareToken contract
        prevPrevShareToken = new PrevPrevShareToken();
        prevPrevShareTokenAddress = address(prevPrevShareToken);
        prevPrevShareToken.unlockMainSaleToken();
        prevPrevShareToken.unlockRewardToken(userA);

        prevPrevShareToken.transfer(userA, 100 * PREV_DECIMAL_MUL);
        // new ShareToken contract
        prevShareToken = new ShareTokenExtended(prevPrevShareTokenAddress);
        prevShareToken.unlockMainSaleToken();
        prevShareToken.unlockRewardToken(userA);
    }

    function testSetUp() public {
        // check previous ShareToken contract set up
        assertEq(prevPrevShareToken.name(), "ShareToken");
        assertEq(prevPrevShareToken.balanceOf(userA), 100 * PREV_DECIMAL_MUL);

        // check new ShareToken contract set up
        assertEq(prevShareToken.name(), "ShareToken");
        assertEq(prevShareToken.symbol(), "SHR");
        assertEq(prevShareToken.decimals(), 2);
    }

    function testMigrateWhenTransfer() public {
        vm.startPrank(userA);
        assertEq(prevShareToken.balanceOf(userA), 100 * PREV_DECIMAL_MUL);
        assertEq(prevShareToken.balanceOf(userB), 0);

        prevShareToken.transfer(userB, 50 * PREV_DECIMAL_MUL);

        // after 1st transfer
        assertEq(prevShareToken.balanceOf(userA), 50 * PREV_DECIMAL_MUL);
        assertEq(prevShareToken.balanceOf(userB), 50 * PREV_DECIMAL_MUL);

        // 2nd transfer
        prevShareToken.transfer(userB, 20 * PREV_DECIMAL_MUL);

        // after 2nd transfer
        assertEq(prevShareToken.balanceOf(userA), 30 * PREV_DECIMAL_MUL);
        assertEq(prevShareToken.balanceOf(userB), 70 * PREV_DECIMAL_MUL);
    }

    function testMigrateWhenTransferFrom() public {
        vm.prank(userA);
        prevShareToken.approve(userB, 50 * PREV_DECIMAL_MUL);

        vm.prank(userB);
        prevShareToken.transferFrom(userA, userC, 50 * PREV_DECIMAL_MUL);

        // after 1st transfer
        assertEq(prevShareToken.balanceOf(userA), 50 * PREV_DECIMAL_MUL);
        assertEq(prevShareToken.balanceOf(userC), 50 * PREV_DECIMAL_MUL);

        // 2nd transfer
        vm.prank(userA);
        prevShareToken.approve(userB, 20 * PREV_DECIMAL_MUL);

        vm.prank(userB);
        prevShareToken.transferFrom(userA, userC, 20 * PREV_DECIMAL_MUL);

        // after 2nd transfer
        assertEq(prevShareToken.balanceOf(userA), 30 * PREV_DECIMAL_MUL);
        assertEq(prevShareToken.balanceOf(userC), 70 * PREV_DECIMAL_MUL);
    }

    function testTransferNotAllowedIfLocked() public {
        assertEq(prevShareToken.balanceOf(userA), 100 * PREV_DECIMAL_MUL);
        prevShareToken.lockMainSaleToken();
        vm.prank(userA);
        vm.expectRevert();
        prevShareToken.transfer(userB, 50 * PREV_DECIMAL_MUL);
    }
}

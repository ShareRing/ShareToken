// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import {Test, console2} from "forge-std/Test.sol";
import {ShareToken} from "../src/ShareToken.sol";
import {ShareTokenExtended} from "./mocks/PrevShareToken.sol";
import {PrevPrevShareToken} from "./mocks/PrevPrevShareToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ShareTokenTest is Test, IERC20Errors {
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error PrevShareTokenContractNotLocked();
    error EnforcedPause();

    event MigrateBalance(address indexed owner, uint256 amount);
    event MigrateAllowance(address indexed owner, address spender, uint256 amount);

    ShareToken public sharetoken;
    ShareTokenExtended public prevShareToken;
    PrevPrevShareToken public prevPrevShareToken;

    address prevPrevShareTokenAddress;
    address prevShareTokenAdress;

    address admin = address(1000);
    address minter = address(1001);
    address pauser = address(1002);
    address userA = address(1003);
    address userB = address(1004);
    address userC = address(1005);

    error NoPrevShareToken(address tokenOwner);

    uint256 public constant DECIMAL_MUL = 10 ** 18;
    uint256 public constant PREV_DECIMAL_MUL = 10 ** 2;
    uint256 public constant PREV_TOTAL_SUPPLY = 282_766_772_999; // in wei
    // Since there is no account hold over 90% of the total supply, we set AMOUNT_MAX_VALUE to 90% of the total supply
    uint256 public constant AMOUNT_MAX_VALUE = PREV_TOTAL_SUPPLY * 90 * 1 / (PREV_DECIMAL_MUL * 100);

    function setUp() public {
        // set up prev-prev ShareToken contract
        prevPrevShareToken = new PrevPrevShareToken();
        prevPrevShareTokenAddress = address(prevPrevShareToken);
        prevPrevShareToken.unlockMainSaleToken();

        // set up prev ShareToken contract
        prevShareToken = new ShareTokenExtended(prevPrevShareTokenAddress);
        prevShareTokenAdress = address(prevShareToken);
        prevShareToken.lockMainSaleToken();

        // new ShareToken contract
        sharetoken = new ShareToken(prevShareTokenAdress, admin, pauser, minter);
    }

    function testSetUp() public {
        // check previous ShareToken contract set up
        assertEq(prevShareToken.name(), "ShareToken");

        // check new ShareToken contract set up
        assertEq(sharetoken.name(), "ShareToken");
        assertEq(sharetoken.symbol(), "SHR");
        assertEq(sharetoken.decimals(), 18);
        assertEq(address(sharetoken.prevShareToken()), prevShareTokenAdress);
        assert(sharetoken.hasRole(sharetoken.DEFAULT_ADMIN_ROLE(), admin));
        assert(sharetoken.hasRole(sharetoken.MINTER_ROLE(), minter));
    }

    function testMigrateWhenTransferToSelf(uint256 amount1) public {
        prevShareToken.unlockMainSaleToken();
        amount1 = uint256(bound(amount1, 0, AMOUNT_MAX_VALUE));
        prevShareToken.transfer(userB, amount1 * PREV_DECIMAL_MUL);
        prevShareToken.lockMainSaleToken();

        // before 1st transfer
        assertEq(sharetoken.balanceMigrated(userB), false);
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        // 1st transfer: transfer to self, amount can be any value
        vm.startPrank(userB);
        sharetoken.transfer(userB, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        assertEq(sharetoken.balanceMigrated(userB), true);

        // 2nd transfer
        // 30% of amount1
        uint256 amount2 = 30 * amount1 / 100;
        sharetoken.transfer(userB, amount2 * DECIMAL_MUL);

        // after 2nd transfer
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        // use if statement to avoid underflow
        if (amount1 > amount2) {
            uint256 amount3 = amount1 - amount2;
            // 3rd transfer
            sharetoken.transfer(userC, amount3 * DECIMAL_MUL);

            // after 3rd transfer
            assertEq(sharetoken.balanceOf(userC), amount3 * DECIMAL_MUL);
            assertEq(sharetoken.balanceOf(userB), amount2 * DECIMAL_MUL);
            // revert if attempting transfer any amount larger than the current balance
            vm.expectRevert();
            sharetoken.transfer(userC, amount1 * DECIMAL_MUL);

            vm.stopPrank();
        }
    }

    function testMigrateWhenTransferToSeftAndRewardsLocked(uint256 amount1) public {
        prevShareToken.unlockMainSaleToken();
        amount1 = uint256(bound(amount1, 0, AMOUNT_MAX_VALUE));
        prevShareToken.transfer(userB, amount1 * PREV_DECIMAL_MUL);
        prevShareToken.lockRewardToken(userB);
        assert(prevShareToken.isLocked(userB));
        prevShareToken.rewardTokenLocked(userB);
        prevShareToken.lockMainSaleToken();

        vm.startPrank(userB);

        // before 1st transfer
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        // 1st transfer to self, amount can be any value
        sharetoken.transfer(userB, 0 * DECIMAL_MUL);

        // after 1st transfer
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        // 2nd transfer
        // 30% of amount1
        uint256 amount2 = 30 * amount1 / 100;
        sharetoken.transfer(userB, amount2 * DECIMAL_MUL);
        // after 2nd transfer
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        // use if statement to avoid underflow
        if (amount1 > amount2) {
            uint256 amount3 = amount1 - amount2;
            // 3rd transfer
            sharetoken.transfer(userC, amount3 * DECIMAL_MUL);

            // after 3rd transfer
            assertEq(sharetoken.balanceOf(userB), amount2 * DECIMAL_MUL);
            assertEq(sharetoken.balanceOf(userC), amount3 * DECIMAL_MUL);
            // revert if attempting transfer any amount larger than the current balance
            vm.expectRevert();
            sharetoken.transfer(userC, amount1 * DECIMAL_MUL);

            vm.stopPrank();
        }
    }

    function testMigrateWhenTransferFromToSelf(uint256 amount1) public {
        prevShareToken.unlockMainSaleToken();
        amount1 = uint256(bound(amount1, 0, AMOUNT_MAX_VALUE));
        prevShareToken.transfer(userB, amount1 * PREV_DECIMAL_MUL);
        prevShareToken.lockMainSaleToken();
        // before 1st transfer
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        vm.startPrank(userB);
        prevShareToken.approve(userA, amount1 * PREV_DECIMAL_MUL);
        prevShareToken.approve(userC, amount1 * PREV_DECIMAL_MUL);

        // 1st transfer - set the amount to 0, we can skip calling the approve function
        sharetoken.transferFrom(userB, userB, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);
        assertEq(sharetoken.allowance(userB, userA), amount1 * DECIMAL_MUL);
        assertEq(sharetoken.allowance(userB, userC), amount1 * DECIMAL_MUL);

        // 2nd transfer - self transfer, should not change the balance
        sharetoken.approve(userB, amount1 * DECIMAL_MUL);
        sharetoken.transferFrom(userB, userB, amount1 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);

        // 3rd transfer
        uint256 amount2 = 50 * amount1 / 100;
        sharetoken.approve(userC, amount2 * DECIMAL_MUL);
        vm.stopPrank();

        vm.prank(userC);
        sharetoken.transferFrom(userB, userC, amount2 * DECIMAL_MUL);
        uint256 amount3 = amount1 - amount2;
        assertEq(sharetoken.balanceOf(userB), amount3 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userC), amount2 * DECIMAL_MUL);
        assertEq(sharetoken.allowance(userB, userC), 0);

        // approve in the previous contract no longer works
        // ensure that amount1 is not the same as amount3
        if (amount2 != 0) {
            vm.prank(userB);
            prevShareToken.approve(userC, amount1 * PREV_DECIMAL_MUL);
            assertEq(sharetoken.allowance(userB, userC), 0);
            vm.prank(userC);
            vm.expectRevert(
                abi.encodeWithSelector(ERC20InsufficientAllowance.selector, userC, 0, amount1 * DECIMAL_MUL)
            );
            sharetoken.transferFrom(userB, userC, amount1 * DECIMAL_MUL);
        }

        // revert if attempting transfer any amount larger than the current balance
        if (amount1 > sharetoken.balanceOf(userB)) {
            vm.prank(userC);
            vm.expectRevert();
            sharetoken.transferFrom(userB, userC, amount1 * DECIMAL_MUL);
        }
    }

    function testMigrateWhenTransferFromToAnotherAccount(uint256 amount1) public {
        prevShareToken.unlockMainSaleToken();
        amount1 = uint256(bound(amount1, 0, AMOUNT_MAX_VALUE));
        prevShareToken.transfer(userB, amount1 * PREV_DECIMAL_MUL);
        prevShareToken.lockMainSaleToken();
        // before 1st transfer
        assertEq(sharetoken.balanceOf(userB), amount1 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userC), 0);

        vm.prank(userB);
        uint256 amount2 = 30 * amount1 / 100;
        // To test migrate allowance, we approve user C in prevShareToken contract
        prevShareToken.approve(userC, amount1 * PREV_DECIMAL_MUL);
        vm.prank(userC);

        // if amount1 is 0, we don't need to migrate
        if (amount1 != 0) {
            vm.expectEmit(true, false, false, true, address(sharetoken));
            emit MigrateBalance(userB, amount1 * DECIMAL_MUL);
            vm.expectEmit(true, false, false, true, address(sharetoken));
            emit MigrateAllowance(userB, userC, amount1 * DECIMAL_MUL);
        }

        sharetoken.transferFrom(userB, userC, amount2 * DECIMAL_MUL);

        // after 1st transfer
        uint256 amount3 = amount1 - amount2;
        assertEq(sharetoken.balanceOf(userB), amount3 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userC), amount2 * DECIMAL_MUL);
        assertEq(sharetoken.allowance(userB, userC), amount3 * DECIMAL_MUL);

        // 2nd transfer: approving in the prev contract no longer works
        if (amount3 != 0) {
            vm.prank(userB);
            prevShareToken.approve(userC, (amount3 * 2) * DECIMAL_MUL);

            vm.prank(userC);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ERC20InsufficientAllowance.selector, userC, amount3 * DECIMAL_MUL, (amount3 * 2) * DECIMAL_MUL
                )
            );
            sharetoken.transferFrom(userB, userC, (amount3 * 2) * DECIMAL_MUL);
        }

        // revert if attempting transfer any amount larger than the current balance
        if (amount1 * DECIMAL_MUL > sharetoken.balanceOf(userB)) {
            vm.prank(userB);
            sharetoken.approve(userC, amount1 * DECIMAL_MUL);

            vm.prank(userC);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ERC20InsufficientBalance.selector, userB, amount3 * DECIMAL_MUL, amount1 * DECIMAL_MUL
                )
            );
            sharetoken.transferFrom(userB, userC, amount1 * DECIMAL_MUL);
        }
    }
}

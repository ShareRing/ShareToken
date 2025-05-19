// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import {Test, console2} from "forge-std/Test.sol";
import {ShareToken} from "../src/ShareToken.sol";
import {ShareTokenExtended} from "./mocks/PrevShareToken.sol";
import {PrevPrevShareToken} from "./mocks/PrevPrevShareToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {SigUtils} from "./utils/SigUtils.sol";

contract ShareTokenTest is Test, IERC20Errors {
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error PrevShareTokenContractNotLocked();
    error EnforcedPause();

    event MigrateBalance(address indexed owner, uint256 amount);
    event MigrateAllowance(address indexed owner, address spender, uint256 amount);

    ShareToken public sharetoken;
    ShareTokenExtended public prevShareToken;
    PrevPrevShareToken public prevPrevShareToken;
    SigUtils internal sigUtils;

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

    uint256 public constant HUNDRED = 100 * DECIMAL_MUL;
    uint256 public constant HUNDRED_PREV = 100 * PREV_DECIMAL_MUL;
    uint256 public constant EIGHTY = 80 * DECIMAL_MUL;
    uint256 public constant SEVENTY = 70 * DECIMAL_MUL;
    uint256 public constant SIXTY = 60 * DECIMAL_MUL;
    uint256 public constant FIFTY = 50 * DECIMAL_MUL;
    uint256 public constant FIFTY_PREV = 50 * PREV_DECIMAL_MUL;
    uint256 public constant FOURTY = 40 * DECIMAL_MUL;
    uint256 public constant THIRTY = 30 * DECIMAL_MUL;
    uint256 public constant TWENTY = 20 * DECIMAL_MUL;

    function setUp() public {
        // set up prev-prev ShareToken contract
        prevPrevShareToken = new PrevPrevShareToken();
        prevPrevShareTokenAddress = address(prevPrevShareToken);
        prevPrevShareToken.unlockMainSaleToken();

        // set up prev ShareToken contract
        prevShareToken = new ShareTokenExtended(prevPrevShareTokenAddress);
        prevShareTokenAdress = address(prevShareToken);
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(userA, HUNDRED_PREV);
        prevShareToken.lockMainSaleToken();

        // new ShareToken contract
        sharetoken = new ShareToken(prevShareTokenAdress, admin, pauser, minter);

        sigUtils = new SigUtils(sharetoken.DOMAIN_SEPARATOR());
    }

    function testSetUp() public {
        // check previous ShareToken contract set up
        assertEq(prevShareToken.name(), "ShareToken");
        assertEq(prevShareToken.balanceOf(userA), HUNDRED_PREV);

        // check new ShareToken contract set up
        assertEq(sharetoken.name(), "ShareToken");
        assertEq(sharetoken.symbol(), "SHR");
        assertEq(sharetoken.decimals(), 18);
        assertEq(address(sharetoken.prevShareToken()), prevShareTokenAdress);
        assert(sharetoken.hasRole(sharetoken.DEFAULT_ADMIN_ROLE(), admin));
        assert(sharetoken.hasRole(sharetoken.MINTER_ROLE(), minter));
    }

    function testMigrateWhenTransferToSelf() public {
        // before 1st transfer
        assertEq(sharetoken.balanceMigrated(userA), false);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);

        // 1st transfer: transfer to self, amount can be any value
        vm.startPrank(userA);
        vm.expectEmit(true, false, false, true, address(sharetoken));
        emit MigrateBalance(userA, HUNDRED);
        sharetoken.transfer(userA, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceMigrated(userA), true);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);

        // 2nd transfer: transfer to self again, should not change the balance
        sharetoken.transfer(userA, THIRTY);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);

        // 3rd transfer: transfer to another account
        sharetoken.transfer(userB, THIRTY);
        assertEq(sharetoken.balanceOf(userA), SEVENTY);
        assertEq(sharetoken.balanceOf(userB), THIRTY);
        vm.stopPrank();

        // revert if attempting transfer any amount larger than the current balance
        vm.prank(userA);
        vm.expectRevert();
        sharetoken.transfer(userB, HUNDRED);

        vm.stopPrank();
    }

    function testRevertTransferIfPrevContractNotLocked() public {
        prevShareToken.unlockMainSaleToken();

        vm.startPrank(userA);
        vm.expectRevert(PrevShareTokenContractNotLocked.selector);
        sharetoken.transfer(userA, 0 * DECIMAL_MUL);
    }

    function testMigrateWhenTheAccountHaveBalanceOnTheNewContract() public {
        assertEq(sharetoken.balanceMigrated(userA), false);
        vm.prank(minter);
        sharetoken.mint(userA, HUNDRED);
        assertEq(sharetoken.balanceOf(userA), 200 * DECIMAL_MUL);

        vm.prank(userA);
        sharetoken.transfer(userA, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceMigrated(userA), true);
        assertEq(sharetoken.balanceOf(userA), 200 * DECIMAL_MUL);
    }

    function testMigrateWhenTransferToAnotherAccount() public {
        vm.startPrank(userA);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);
        assertEq(sharetoken.balanceOf(userB), 0);

        sharetoken.transfer(userB, FIFTY);

        // after 1st transfer
        assertEq(sharetoken.balanceOf(userA), FIFTY);
        assertEq(sharetoken.balanceOf(userB), FIFTY);

        // 2nd transfer
        sharetoken.transfer(userB, TWENTY);

        // after 2nd transfer
        assertEq(sharetoken.balanceOf(userA), THIRTY);
        assertEq(sharetoken.balanceOf(userB), SEVENTY);
    }

    // Also allow transfer if rewarded tokens is locked in PrevShareToken contract
    function testMigrateWhenTransferToSeftAndRewardsLocked() public {
        // setup
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(userB, HUNDRED_PREV);
        prevShareToken.lockRewardToken(userB);
        assert(prevShareToken.isLocked(userB));
        prevShareToken.rewardTokenLocked(userB);
        prevShareToken.lockMainSaleToken();

        vm.startPrank(userB);
        vm.expectRevert();
        prevShareToken.transfer(userC, HUNDRED_PREV);

        // before 1st transfer
        assertEq(sharetoken.balanceOf(userB), HUNDRED);

        // transfer to self, amount can be any value
        sharetoken.transfer(userB, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userB), HUNDRED);

        // transfer to another account
        sharetoken.transfer(userA, THIRTY);
        assertEq(sharetoken.balanceOf(userB), SEVENTY);
        assertEq(sharetoken.balanceOf(userA), 130 * DECIMAL_MUL);

        // revert if attempting transfer any amount larger than the current balance
        vm.expectRevert();
        sharetoken.transfer(userA, HUNDRED);
    }

    function testMigrateWhenTransferFromToSelf() public {
        // before 1st transfer
        assertEq(sharetoken.balanceOf(userA), HUNDRED);
        vm.startPrank(userA);
        prevShareToken.approve(userB, HUNDRED_PREV);
        prevShareToken.approve(userC, HUNDRED_PREV);

        assertEq(sharetoken.allowance(userA, userB), HUNDRED);
        assertEq(sharetoken.allowance(userA, userC), HUNDRED);
        assertEq(sharetoken.allowanceMigrated(userA, userB), false);
        assertEq(sharetoken.allowanceMigrated(userA, userC), false);

        // 1st transfer: set the amount to 0, we can skip calling the approve function in the new contract
        sharetoken.transferFrom(userA, userA, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);
        // it does not migrate the allowance
        assertEq(sharetoken.allowanceMigrated(userA, userB), false);
        assertEq(sharetoken.allowanceMigrated(userA, userC), false);

        // 2nd transfer: transfer to self again, should not change the balance
        // need to approve
        sharetoken.approve(userA, HUNDRED);
        sharetoken.transferFrom(userA, userA, HUNDRED);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);
        vm.stopPrank();

        // Transfer using another account
        vm.prank(userB);
        sharetoken.transferFrom(userA, userC, FIFTY);
        assertEq(sharetoken.balanceOf(userA), FIFTY);
        assertEq(sharetoken.balanceOf(userC), FIFTY);
        assertEq(sharetoken.allowanceMigrated(userA, userB), true);
        assertEq(sharetoken.allowance(userA, userB), FIFTY);
        // userC's allowance not yet migrated
        assertEq(sharetoken.allowanceMigrated(userA, userC), false);
        assertEq(sharetoken.allowance(userA, userC), HUNDRED);

        vm.prank(userC);
        sharetoken.transferFrom(userA, userC, THIRTY);
        assertEq(sharetoken.allowanceMigrated(userA, userC), true);
        assertEq(sharetoken.allowance(userA, userC), SEVENTY);

        // approve in the previous contract no longer works
        vm.prank(userA);
        prevShareToken.approve(userB, HUNDRED_PREV);

        vm.prank(userB);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, userB, FIFTY, HUNDRED));
        sharetoken.transferFrom(userA, userC, HUNDRED);

        // revert if attempting transfer any amount larger than the current balance
        vm.prank(userB);
        vm.expectRevert();
        sharetoken.transferFrom(userA, userC, SIXTY);
    }

    function testMigrateWhenTransferFromToAnotherAccount() public {
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(userB, HUNDRED_PREV);
        prevShareToken.lockMainSaleToken();

        // before 1st transfer
        assertEq(sharetoken.balanceOf(userA), HUNDRED);
        assertEq(sharetoken.balanceOf(userB), HUNDRED);

        // 1st transfer: to test migrate allowance, we call the previous contract approve function
        vm.startPrank(userA);
        prevShareToken.approve(userB, FIFTY_PREV);
        prevShareToken.approve(userC, FIFTY_PREV);
        vm.stopPrank();
        vm.prank(userB);
        prevShareToken.approve(userB, HUNDRED_PREV);

        assertEq(sharetoken.allowanceMigrated(userA, userB), false);
        assertEq(sharetoken.allowanceMigrated(userA, userC), false);
        assertEq(sharetoken.allowance(userA, userB), FIFTY);
        assertEq(sharetoken.allowance(userA, userC), FIFTY);

        vm.prank(userB);
        vm.expectEmit(true, false, false, true, address(sharetoken));
        emit MigrateBalance(userA, HUNDRED);
        vm.expectEmit(true, false, false, true, address(sharetoken));
        emit MigrateAllowance(userA, userB, FIFTY);

        sharetoken.transferFrom(userA, userC, THIRTY);
        assertEq(sharetoken.balanceOf(userA), SEVENTY);
        // assertEq(sharetoken.balanceOf(userB), HUNDRED);
        assertEq(sharetoken.balanceOf(userC), THIRTY);
        assertEq(sharetoken.allowanceMigrated(userA, userB), true);
        assertEq(sharetoken.allowance(userA, userB), TWENTY);
        // userC's allowance not yet migrated
        assertEq(sharetoken.allowanceMigrated(userA, userC), false);
        assertEq(sharetoken.allowance(userA, userC), FIFTY);

        vm.prank(userC);
        sharetoken.transferFrom(userA, userC, THIRTY);
        assertEq(sharetoken.allowanceMigrated(userA, userC), true);
        assertEq(sharetoken.allowance(userA, userC), TWENTY);

        // 2nd transfer: approving in the prev contract no longer works
        vm.prank(userA);
        prevShareToken.approve(userB, FOURTY);

        vm.prank(userB);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, userB, TWENTY, FOURTY));
        sharetoken.transferFrom(userA, userC, FOURTY);

        // revert if attempting transfer any amount larger than the current balance
        vm.prank(userA);
        sharetoken.approve(userB, EIGHTY);

        vm.prank(userB);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, userA, FOURTY, EIGHTY));
        sharetoken.transferFrom(userA, userC, EIGHTY);
    }

    function testMint() public {
        vm.prank(minter);
        sharetoken.mint(userA, HUNDRED);
        assertEq(sharetoken.balanceOf(userA), 200 * DECIMAL_MUL);

        vm.prank(userA);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, userA, keccak256("MINTER_ROLE"))
        );
        sharetoken.mint(userA, HUNDRED);
    }

    function testBurn() public {
        vm.prank(userA);
        prevShareToken.approve(userB, FIFTY_PREV);
        assertEq(sharetoken.balanceMigrated(userA), false);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);

        // Not yet migrated, calling burn will migrate the token and then burn the amount of token passed in
        vm.startPrank(userA);
        sharetoken.burn(FIFTY);
        assertEq(sharetoken.balanceMigrated(userA), true);
        // it should not migrate the allowance
        assertEq(sharetoken.allowanceMigrated(userA, userB), false);
        assertEq(sharetoken.balanceOf(userA), FIFTY);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, userA, FIFTY, HUNDRED));
        sharetoken.burn(HUNDRED);
        vm.stopPrank();

        // if the balance is already migrated, then burn will skip the migration and burn the amount passed in
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(userB, HUNDRED_PREV);
        prevShareToken.lockMainSaleToken();
        assertEq(sharetoken.balanceMigrated(userB), false);
        assertEq(sharetoken.balanceOf(userB), HUNDRED);

        vm.startPrank(userB);
        sharetoken.transfer(userB, 0 * DECIMAL_MUL);
        assertEq(sharetoken.balanceMigrated(userB), true);
        sharetoken.burn(FOURTY);
        assertEq(sharetoken.balanceOf(userB), SIXTY);
    }

    function testBurnFrom() public {
        assertEq(sharetoken.balanceMigrated(userA), false);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);

        // 1st transfer: to test burnFrom with allowance, we call the previous contract approve function
        vm.prank(userA);
        prevShareToken.approve(userB, FIFTY_PREV);
        assertEq(sharetoken.allowance(userA, userB), FIFTY);

        vm.prank(userB);
        sharetoken.burnFrom(userA, THIRTY);
        // it should migrate the balance and the allowance
        assertEq(sharetoken.balanceMigrated(userA), true);
        assertEq(sharetoken.allowanceMigrated(userA, userB), true);
        assertEq(sharetoken.balanceOf(userA), SEVENTY);
        assertEq(sharetoken.allowance(userA, userB), TWENTY);

        // 2nd transfer: approving in the prev contract no longer works
        vm.prank(userA);
        prevShareToken.approve(userB, FOURTY);

        vm.prank(userB);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, userB, TWENTY, FOURTY));
        sharetoken.burnFrom(userA, FOURTY);

        // if only the balance is already migrated, then burnFrom will only migrate the allowance
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(userB, HUNDRED_PREV);
        prevShareToken.lockMainSaleToken();
        assertEq(sharetoken.balanceMigrated(userB), false);
        assertEq(sharetoken.balanceOf(userB), HUNDRED);

        vm.startPrank(userB);
        // this transfer does not migrate the allowance
        sharetoken.transfer(userB, 0 * PREV_DECIMAL_MUL);
        assertEq(sharetoken.balanceMigrated(userB), true);
        assertEq(sharetoken.allowanceMigrated(userB, userA), false);
        assertEq(sharetoken.balanceOf(userB), HUNDRED);
        prevShareToken.approve(userA, FIFTY_PREV);
        vm.stopPrank();

        vm.prank(userA);
        sharetoken.burnFrom(userB, THIRTY);
        assertEq(sharetoken.balanceMigrated(userB), true);
        assertEq(sharetoken.allowanceMigrated(userB, userA), true);
        assertEq(sharetoken.balanceOf(userB), SEVENTY);
        assertEq(sharetoken.allowance(userB, userA), TWENTY);

        // now approve for burnFrom won't work
        vm.prank(userB);
        prevShareToken.approve(userA, FOURTY);

        vm.prank(userA);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, userA, TWENTY, FOURTY));
        sharetoken.burnFrom(userB, FOURTY);

        // test self burnFrom
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(userC, HUNDRED_PREV);
        prevShareToken.lockMainSaleToken();
        vm.startPrank(userC);
        prevShareToken.approve(userC, FIFTY_PREV);
        vm.startPrank(userC);

        sharetoken.burnFrom(userC, FIFTY);
        assertEq(sharetoken.balanceOf(userC), FIFTY);
        assertEq(sharetoken.balanceMigrated(userC), true);
        assertEq(sharetoken.allowanceMigrated(userC, userC), true);
        vm.stopPrank();
    }

    function testAllowanceWhenApproveAfterMigrateUsingTransfer() public {
        // approve in the previous contract
        vm.startPrank(userA);
        prevShareToken.approve(userB, FIFTY_PREV);
        assertEq(prevShareToken.allowance(userA, userB), FIFTY_PREV);
        // now the allowance in new token contract is FIFTY
        assertEq(sharetoken.allowance(userA, userB), FIFTY);

        // mirgrate
        // transfer amount can be any value, it only migrates the balance
        sharetoken.transfer(userA, 0);
        assertEq(sharetoken.balanceOf(userA), HUNDRED);
        // the allowance in new token contract is still FIFTY
        assertEq(sharetoken.allowance(userA, userB), FIFTY);

        // approve again in previous contract
        prevShareToken.approve(userB, HUNDRED_PREV);
        // the allowance in new token contract is now HUNDRED because userA has not migrated allowance yet
        assertEq(sharetoken.allowance(userA, userB), HUNDRED);

        // now user A approve in new token contract
        // this will mark the allowance as migrated
        sharetoken.approve(userB, FIFTY);
        assertEq(sharetoken.allowance(userA, userB), FIFTY);
        assertEq(sharetoken.allowanceMigrated(userA, userB), true);
        vm.stopPrank();
        // userB now can spend FIFTY SHR
        vm.startPrank(userB);
        sharetoken.transferFrom(userA, userB, TWENTY);
        assertEq(sharetoken.balanceOf(userB), TWENTY);

        // now revert
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, userB, THIRTY, FIFTY));
        sharetoken.transferFrom(userA, userB, FIFTY);
        vm.stopPrank();
    }

    function testPermit() public {
        address owner = 0x1D3B4e9DcBf4808Fd1718f1ed5cCF5101614Ae3A;
        uint256 ownerPrivateKey = 0xe7d932bdd401d6b005bd828c84ad7af72b94e053aba6c3030a818be0d8293f39;
        address spender = 0x3578b1Ad0a9038a0762d8c2a89d98996cB88CfD0;

        // mint prev token
        prevShareToken.unlockMainSaleToken();
        prevShareToken.transfer(owner, HUNDRED_PREV);
        assertEq(prevShareToken.balanceOf(owner), HUNDRED_PREV);
        vm.prank(owner);
        prevShareToken.approve(spender, FIFTY_PREV);
        prevShareToken.lockMainSaleToken();

        // can't spend HUNDRED on new token contract
        vm.prank(spender);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, spender, FIFTY, HUNDRED));
        sharetoken.transferFrom(owner, spender, HUNDRED);

        // permit
        // obtain signature from owner
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: HUNDRED, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // anyone can call permit
        vm.prank(minter);
        sharetoken.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        // expect allowance to be migrated (balance not yet migrated)
        assertEq(sharetoken.balanceMigrated(owner), false);
        assertEq(sharetoken.allowanceMigrated(owner, spender), true);
        assertEq(sharetoken.balanceOf(owner), HUNDRED);
        assertEq(sharetoken.allowance(owner, spender), HUNDRED);
        assertEq(sharetoken.nonces(owner), 1);

        // spend allowance
        vm.prank(spender);
        sharetoken.transferFrom(owner, spender, HUNDRED);
        assertEq(sharetoken.balanceOf(spender), HUNDRED);
        assertEq(sharetoken.balanceOf(owner), 0);
        assertEq(sharetoken.allowance(owner, spender), 0);
    }

    function testPause() public {
        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, minter, keccak256("PAUSER_ROLE"))
        );
        sharetoken.pause();

        vm.prank(pauser);
        sharetoken.pause();

        vm.startPrank(userA);
        vm.expectRevert(EnforcedPause.selector);
        sharetoken.transfer(userA, HUNDRED);

        sharetoken.approve(userB, HUNDRED);
        vm.expectRevert(EnforcedPause.selector);
        sharetoken.transferFrom(userA, userB, HUNDRED);
        vm.stopPrank();

        vm.prank(minter);
        vm.expectRevert(EnforcedPause.selector);
        sharetoken.mint(userA, HUNDRED);

        vm.prank(userA);
        vm.expectRevert(EnforcedPause.selector);
        sharetoken.burn(HUNDRED);

        vm.prank(userB);
        vm.expectRevert(EnforcedPause.selector);
        sharetoken.burnFrom(userA, THIRTY);

        vm.prank(pauser);
        sharetoken.unpause();

        vm.prank(userA);
        sharetoken.transfer(userA, HUNDRED);
        sharetoken.approve(userB, HUNDRED);
        vm.prank(userB);
        sharetoken.transferFrom(userA, userB, HUNDRED);

        vm.prank(minter);
        sharetoken.mint(userA, HUNDRED);

        vm.startPrank(userA);
        sharetoken.burn(SEVENTY);
        sharetoken.approve(userB, THIRTY);
        vm.stopPrank();

        vm.prank(userB);
        sharetoken.burnFrom(userA, THIRTY);
    }
}

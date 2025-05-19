// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";
import "../src/ShareToken.sol";

contract DeployAndPause is Script {
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function run() external {
        address previousShareTokenAddress = vm.envAddress("PREV_SHARE_TOKEN_ADDRESS");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");
        address pauserAddress = vm.envAddress("PAUSER_ADDRESS");
        address minterAddress = vm.envAddress("MINTER_ADDRESS");

        vm.startBroadcast();
        // deploy contract
        console2.log("Deploying ShareToken contract...");
        ShareToken shareToken = new ShareToken(previousShareTokenAddress, adminAddress, pauserAddress, minterAddress);
        console2.log("Deployed ShareToken at: %s", address(shareToken));

        // pause contract
        console2.log("Pausing ShareToken contract...");
        shareToken.pause();
        // check if paused
        bool isPaused = shareToken.paused();
        console2.log("Is ShareToken contract paused? %s", isPaused);

        // check if roles are set
        bool hasRoleAdmin = shareToken.hasRole(DEFAULT_ADMIN_ROLE, adminAddress);
        bool hasRolePauser = shareToken.hasRole(PAUSER_ROLE, pauserAddress);
        bool hasRoleMinter = shareToken.hasRole(MINTER_ROLE, minterAddress);

        console2.log("Does %s has role Admin: %s", adminAddress, hasRoleAdmin);
        console2.log("Does %s has role Pauser: %s", pauserAddress, hasRolePauser);
        console2.log("Does %s has role Minter: %s", minterAddress, hasRoleMinter);

        vm.stopBroadcast();
    }
}

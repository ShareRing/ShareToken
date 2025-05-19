// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";
import "../src/ShareToken.sol";

contract DeployMainnet is Script {
    function run() external {
        address previousShareTokenAddress = vm.envAddress("PREV_SHARE_TOKEN_ADDRESS");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");
        address pauserAddress = vm.envAddress("PAUSER_ADDRESS");
        address minterAddress = vm.envAddress("MINTER_ADDRESS");

        vm.startBroadcast();

        ShareToken shareToken = new ShareToken(previousShareTokenAddress, adminAddress, pauserAddress, minterAddress);

        console2.log("Deployed ShareToken at: %s", address(shareToken));

        vm.stopBroadcast();
    }
}

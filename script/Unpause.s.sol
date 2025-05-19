// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";
import "../src/ShareToken.sol";

contract Unpause is Script {
    function run() external {
        address shareTokenAddress = vm.envAddress("SHARE_TOKEN_ADDRESS");
        vm.startBroadcast();

        ShareToken shareToken = ShareToken(shareTokenAddress);

        shareToken.unpause();

        // check if paused
        bool isPaused = shareToken.paused();
        console2.log("Is ShareToken paused: %s", isPaused);
    }
}

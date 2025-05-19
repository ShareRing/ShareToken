// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";
import "../src/ShareToken.sol";

contract RenounceRole is Script {
    function run(bytes calldata role, address callerConfirmation) external {
        address shareTokenAddress = vm.envAddress("SHARE_TOKEN_ADDRESS");
        vm.startBroadcast();

        ShareToken shareToken = ShareToken(shareTokenAddress);

        shareToken.renounceRole(keccak256(role), callerConfirmation);

        // check if revoked
        bool hasRole = shareToken.hasRole(keccak256(role), callerConfirmation);
        console2.log("Is role revoked: %s", !hasRole);
    }
}

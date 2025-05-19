// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";
import "../src/ShareToken.sol";
import {ShareTokenExtended} from "../test/mocks/PrevShareToken.sol";
import {PrevPrevShareToken} from "../test/mocks/PrevPrevShareToken.sol";

// This script is used to deploy the two previous ShareToken contracts for testing purposes
contract DeploySepolia is Script {
    function run() external {
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");
        address pauserAddress = vm.envAddress("PAUSER_ADDRESS");
        address minterAddress = vm.envAddress("MINTER_ADDRESS");
        vm.startBroadcast();

        PrevPrevShareToken prevPrevShareToken = new PrevPrevShareToken();

        console2.log("Deployed PrevPrevShareToken at: %s", address(prevPrevShareToken));

        ShareTokenExtended prevShareToken = new ShareTokenExtended(address(prevPrevShareToken));

        console2.log("Deployed PrevShareToken at: %s", address(prevShareToken));

        ShareToken shareToken = new ShareToken(address(prevShareToken), adminAddress, pauserAddress, minterAddress);

        console2.log("Deployed ShareToken at: %s", address(shareToken));

        // unlock mainSaleToken on PrevPrevShareToken
        prevPrevShareToken.unlockMainSaleToken();

        // unlock mainSaleToken on PrevShareToken
        prevShareToken.unlockMainSaleToken();

        // pause ShareToken
        shareToken.pause();

        vm.stopBroadcast();
    }
}

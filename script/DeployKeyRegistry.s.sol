// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {KeyRegistry} from "../src/KeyRegistry.sol";

contract DeployKeyRegistry is Script {
    function run() external {
        vm.startBroadcast();

        KeyRegistry keyRegistry = new KeyRegistry();

        vm.stopBroadcast();

        console.log("KeyRegistry deployed at:", address(keyRegistry));
        console.log("Deploy block: use cast block-number --rpc-url <RPC> to record it");
    }
}

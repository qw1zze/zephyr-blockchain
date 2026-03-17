// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MessageRegistry} from "../src/MessageRegistry.sol";

contract DeployMessageRegistry is Script {
    function run() external {
        vm.startBroadcast();

        MessageRegistry messageRegistry = new MessageRegistry();

        vm.stopBroadcast();

        console.log("MessageRegistry deployed at:", address(messageRegistry));
        console.log("Deploy block: use cast block-number --rpc-url <RPC> to record it");
    }
}

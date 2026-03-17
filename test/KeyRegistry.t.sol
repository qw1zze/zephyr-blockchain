// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {KeyRegistry} from "../src/KeyRegistry.sol";

contract KeyRegistryTest is Test {
    KeyRegistry internal registry;

    event KeyPublished(address indexed user, bytes publicKey, uint256 blockNumber);

    address internal constant USER  = address(0x1);
    address internal constant OTHER = address(0x2);

    bytes internal constant SAMPLE_KEY =
        hex"0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";

    bytes internal constant SAMPLE_KEY_2 =
        hex"02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5";

    function setUp() public {
        registry = new KeyRegistry();
    }

    function test_PublishKey_Success() public {
        vm.prank(USER);
        registry.publishKey(SAMPLE_KEY);

        vm.prank(USER);
        bytes memory stored = registry.getKey(USER);
        assertEq(stored, SAMPLE_KEY, "stored key should match published key");
    }

    function test_PublishKey_UpdateExisting() public {
        vm.prank(USER);
        registry.publishKey(SAMPLE_KEY);

        vm.prank(USER);
        registry.publishKey(SAMPLE_KEY_2);

        bytes memory stored = registry.getKey(USER);
        assertEq(stored, SAMPLE_KEY_2, "key should be updated to the new value");
    }

    function test_RevertWhen_PublishKey_EmptyKey() public {
        vm.prank(USER);
        vm.expectRevert("KeyRegistry: empty public key");
        registry.publishKey(new bytes(0));
    }

    function test_GetKey_Success() public {
        vm.prank(OTHER);
        registry.publishKey(SAMPLE_KEY);

        bytes memory result = registry.getKey(OTHER);
        assertEq(result, SAMPLE_KEY);
    }

    function test_RevertWhen_GetKey_NotPublished() public {
        vm.expectRevert("KeyRegistry: key not found");
        registry.getKey(address(0xDEAD));
    }

    function test_PublishKey_EmitsEvent() public {
        uint256 expectedBlock = 42;
        vm.roll(expectedBlock);

        vm.expectEmit(true, false, false, true, address(registry));
        emit KeyPublished(USER, SAMPLE_KEY, expectedBlock);

        vm.prank(USER);
        registry.publishKey(SAMPLE_KEY);
    }

    function test_Fuzz_PublishKey_RandomKey(bytes calldata key) public {
        vm.assume(key.length > 0);

        vm.prank(USER);
        registry.publishKey(key);

        bytes memory stored = registry.getKey(USER);
        assertEq(stored, key, "stored key must equal the fuzzed input");
    }
}

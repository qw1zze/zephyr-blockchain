// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MessageRegistry} from "../src/MessageRegistry.sol";

contract MessageRegistryTest is Test {
    MessageRegistry internal registry;

    event ChatCreated(
        bytes32 indexed chatId,
        address indexed creator,
        address indexed recipient,
        uint256 blockNumber
    );
    event BatchAnchored(
        bytes32   indexed chatId,
        address   indexed sender,
        bytes32[] messageIds,
        string[]  cids,
        uint256[] timestamps,
        uint256   blockNumber
    );

    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB   = address(0xB0B);
    address internal constant EVE   = address(0xE4E);

    bytes32 internal constant CHAT_ID = keccak256("alice-bob-chat");

    function _createDefaultChat() internal {
        vm.prank(ALICE);
        registry.createChat(CHAT_ID, BOB);
    }

    function _makeBatch(uint256 n)
        internal
        pure
        returns (
            bytes32[] memory messageIds,
            string[]  memory cids,
            uint256[] memory timestamps
        )
    {
        messageIds = new bytes32[](n);
        cids       = new string[](n);
        timestamps = new uint256[](n);
        for (uint256 i; i < n; i++) {
            messageIds[i] = keccak256(abi.encodePacked("msg", i));
            cids[i]       = "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi";
            timestamps[i] = 1_700_000_000 + i;
        }
    }

    function setUp() public {
        registry = new MessageRegistry();
    }

    function test_CreateChat_Success() public {
        uint256 expectedBlock = 10;
        vm.roll(expectedBlock);

        _createDefaultChat();

        assertEq(registry.getChatCreatedAtBlock(CHAT_ID), expectedBlock);
    }

    function test_RevertWhen_CreateChat_ZeroRecipient() public {
        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: zero recipient");
        registry.createChat(CHAT_ID, address(0));
    }

    function test_RevertWhen_CreateChat_SelfChat() public {
        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: self-chat not allowed");
        registry.createChat(CHAT_ID, ALICE);
    }

    function test_RevertWhen_CreateChat_AlreadyExists() public {
        _createDefaultChat();

        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: chat already exists");
        registry.createChat(CHAT_ID, BOB);
    }

    function test_CreateChat_BothParticipantsAdded() public {
        _createDefaultChat();

        bytes32[] memory aliceChats = registry.getUserChats(ALICE);
        bytes32[] memory bobChats   = registry.getUserChats(BOB);

        assertEq(aliceChats.length, 1);
        assertEq(aliceChats[0], CHAT_ID);

        assertEq(bobChats.length, 1);
        assertEq(bobChats[0], CHAT_ID);
    }

    function test_CreateChat_EmitsEvent() public {
        uint256 expectedBlock = 7;
        vm.roll(expectedBlock);

        vm.expectEmit(true, true, true, true, address(registry));
        emit ChatCreated(CHAT_ID, ALICE, BOB, expectedBlock);

        vm.prank(ALICE);
        registry.createChat(CHAT_ID, BOB);
    }

    function test_AnchorBatch_Success() public {
        _createDefaultChat();

        (bytes32[] memory ids, string[] memory cids, uint256[] memory ts) = _makeBatch(3);

        vm.prank(ALICE);
        registry.anchorBatch(CHAT_ID, ids, cids, ts);
    }

    function test_RevertWhen_AnchorBatch_ChatNotExists() public {
        (bytes32[] memory ids, string[] memory cids, uint256[] memory ts) = _makeBatch(1);

        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: chat does not exist");
        registry.anchorBatch(keccak256("unknown-chat"), ids, cids, ts);
    }

    function test_RevertWhen_AnchorBatch_NotParticipant() public {
        _createDefaultChat();

        (bytes32[] memory ids, string[] memory cids, uint256[] memory ts) = _makeBatch(1);

        vm.prank(EVE);
        vm.expectRevert("MessageRegistry: not a participant");
        registry.anchorBatch(CHAT_ID, ids, cids, ts);
    }

    function test_RevertWhen_AnchorBatch_LengthMismatch() public {
        _createDefaultChat();

        bytes32[] memory ids = new bytes32[](2);
        string[]  memory cids = new string[](1);  
        uint256[] memory ts = new uint256[](2);

        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: length mismatch");
        registry.anchorBatch(CHAT_ID, ids, cids, ts);
    }

    function test_RevertWhen_AnchorBatch_EmptyBatch() public {
        _createDefaultChat();

        bytes32[] memory ids = new bytes32[](0);
        string[]  memory cids = new string[](0);
        uint256[] memory ts = new uint256[](0);

        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: empty batch");
        registry.anchorBatch(CHAT_ID, ids, cids, ts);
    }

    function test_RevertWhen_AnchorBatch_TooLarge() public {
        _createDefaultChat();

        (bytes32[] memory ids, string[] memory cids, uint256[] memory ts) = _makeBatch(51);

        vm.prank(ALICE);
        vm.expectRevert("MessageRegistry: batch too large");
        registry.anchorBatch(CHAT_ID, ids, cids, ts);
    }

    function test_GetUserChats_Success() public {
        bytes32 chat1 = keccak256("chat1");
        bytes32 chat2 = keccak256("chat2");

        vm.prank(ALICE);
        registry.createChat(chat1, BOB);

        vm.prank(ALICE);
        registry.createChat(chat2, EVE);

        bytes32[] memory chats = registry.getUserChats(ALICE);
        assertEq(chats.length, 2);
        assertEq(chats[0], chat1);
        assertEq(chats[1], chat2);
    }

    function test_GetChatCreatedAtBlock_Success() public {
        vm.roll(99);
        _createDefaultChat();

        assertEq(registry.getChatCreatedAtBlock(CHAT_ID), 99);
    }

    function test_RevertWhen_GetChatCreatedAtBlock_NotExists() public {
        vm.expectRevert("MessageRegistry: chat does not exist");
        registry.getChatCreatedAtBlock(keccak256("nonexistent"));
    }

    function test_AnchorBatch_EmitsEvent() public {
        _createDefaultChat();

        uint256 expectedBlock = 55;
        vm.roll(expectedBlock);

        (bytes32[] memory ids, string[] memory cids, uint256[] memory ts) = _makeBatch(2);

        vm.expectEmit(true, true, false, true, address(registry));
        emit BatchAnchored(CHAT_ID, ALICE, ids, cids, ts, expectedBlock);

        vm.prank(ALICE);
        registry.anchorBatch(CHAT_ID, ids, cids, ts);
    }

    function test_Fuzz_AnchorBatch_RandomBatchSize(uint8 rawSize) public {
        _createDefaultChat();

        uint256 size = uint256(rawSize) % 101;

        bytes32[] memory ids = new bytes32[](size);
        string[]  memory cids = new string[](size);
        uint256[] memory ts = new uint256[](size);
        for (uint256 i; i < size; i++) {
            ids[i] = keccak256(abi.encodePacked(i));
            cids[i] = "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi";
            ts[i]   = i;
        }

        vm.prank(ALICE);
        if (size == 0) {
            vm.expectRevert("MessageRegistry: empty batch");
            registry.anchorBatch(CHAT_ID, ids, cids, ts);
        } else if (size > 50) {
            vm.expectRevert("MessageRegistry: batch too large");
            registry.anchorBatch(CHAT_ID, ids, cids, ts);
        } else {
            registry.anchorBatch(CHAT_ID, ids, cids, ts);
        }
    }
}

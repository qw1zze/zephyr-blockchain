// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MessageRegistry {
    uint256 private constant MAX_BATCH_SIZE = 50;

    mapping(bytes32 => uint256) private _chatCreatedAtBlock;
    mapping(address => bytes32[]) private _userChats;
    mapping(bytes32 => address[2]) private _chatParticipants;

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

    function createChat(bytes32 chatId, address recipient) external {
        require(chatId != bytes32(0), "MessageRegistry: zero chatId");
        require(recipient != address(0), "MessageRegistry: zero recipient");
        require(recipient != msg.sender, "MessageRegistry: self-chat not allowed");
        require(
            _chatCreatedAtBlock[chatId] == 0,
            "MessageRegistry: chat already exists"
        );

        _chatCreatedAtBlock[chatId] = block.number;
        _chatParticipants[chatId] = [msg.sender, recipient];
        _userChats[msg.sender].push(chatId);
        _userChats[recipient].push(chatId);

        emit ChatCreated(chatId, msg.sender, recipient, block.number);
    }

    function anchorBatch(
        bytes32          chatId,
        bytes32[] calldata messageIds,
        string[]  calldata cids,
        uint256[] calldata timestamps
    ) external {
        require(
            _chatCreatedAtBlock[chatId] != 0,
            "MessageRegistry: chat does not exist"
        );
        require(_isParticipant(chatId, msg.sender), "MessageRegistry: not a participant");
        require(messageIds.length == cids.length, "MessageRegistry: length mismatch");
        require(messageIds.length == timestamps.length, "MessageRegistry: length mismatch");
        require(messageIds.length >= 1, "MessageRegistry: empty batch");
        require(messageIds.length <= MAX_BATCH_SIZE, "MessageRegistry: batch too large");

        emit BatchAnchored(chatId, msg.sender, messageIds, cids, timestamps, block.number);
    }

    function getUserChats(address user) external view returns (bytes32[] memory) {
        return _userChats[user];
    }

    function getChatCreatedAtBlock(bytes32 chatId) external view returns (uint256) {
        require(
            _chatCreatedAtBlock[chatId] != 0,
            "MessageRegistry: chat does not exist"
        );
        return _chatCreatedAtBlock[chatId];
    }

    function _isParticipant(bytes32 chatId, address user) internal view returns (bool) {
        address[2] storage participants = _chatParticipants[chatId];
        return participants[0] == user || participants[1] == user;
    }
}

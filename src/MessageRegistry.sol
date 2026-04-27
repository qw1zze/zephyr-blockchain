// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MessageRegistry {
    uint256 private constant MAX_BATCH_SIZE = 50;
    uint256 private constant MAX_PARTICIPANTS = 5;

    mapping(bytes32 => uint256) private _chatCreatedAtBlock;
    mapping(address => bytes32[]) private _userChats;
    mapping(bytes32 => address[]) private _chatParticipants;
    mapping(bytes32 => mapping(address => bool)) private _participantSet;

    event ChatCreated(
        bytes32 indexed chatId,
        address indexed creator,
        address[] participants,
        uint256 blockNumber
    );

    event BatchAnchored(
        bytes32 indexed chatId,
        address indexed sender,
        bytes32[] messageIds,
        string[] cids,
        uint256[] timestamps,
        uint256 blockNumber
    );

    function createChat(bytes32 chatId, address[] calldata recipients) external {
        require(chatId != bytes32(0), "MessageRegistry: zero chatId");
        require(recipients.length >= 1, "MessageRegistry: no recipients");
        require(
            recipients.length <= MAX_PARTICIPANTS - 1,
            "MessageRegistry: too many recipients"
        );
        require(
            _chatCreatedAtBlock[chatId] == 0,
            "MessageRegistry: chat already exists"
        );

        address[] memory participants = new address[](recipients.length + 1);
        participants[0] = msg.sender;
        _participantSet[chatId][msg.sender] = true;

        for (uint256 i; i < recipients.length; i++) {
            address r = recipients[i];
            require(r != address(0), "MessageRegistry: zero recipient");
            require(r != msg.sender, "MessageRegistry: self-chat not allowed");
            require(!_participantSet[chatId][r], "MessageRegistry: duplicate recipient");
            _participantSet[chatId][r] = true;
            participants[i + 1] = r;
        }

        _chatCreatedAtBlock[chatId] = block.number;

        for (uint256 i; i < participants.length; i++) {
            _chatParticipants[chatId].push(participants[i]);
            _userChats[participants[i]].push(chatId);
        }

        emit ChatCreated(chatId, msg.sender, participants, block.number);
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
        require(_participantSet[chatId][msg.sender], "MessageRegistry: not a participant");
        require(messageIds.length == cids.length, "MessageRegistry: length mismatch");
        require(messageIds.length == timestamps.length, "MessageRegistry: length mismatch");
        require(messageIds.length >= 1, "MessageRegistry: empty batch");
        require(messageIds.length <= MAX_BATCH_SIZE, "MessageRegistry: batch too large");

        emit BatchAnchored(chatId, msg.sender, messageIds, cids, timestamps, block.number);
    }

    function getUserChats(address user) external view returns (bytes32[] memory) {
        return _userChats[user];
    }

    function getChatParticipants(bytes32 chatId) external view returns (address[] memory) {
        require(
            _chatCreatedAtBlock[chatId] != 0,
            "MessageRegistry: chat does not exist"
        );
        return _chatParticipants[chatId];
    }

    function getChatCreatedAtBlock(bytes32 chatId) external view returns (uint256) {
        require(
            _chatCreatedAtBlock[chatId] != 0,
            "MessageRegistry: chat does not exist"
        );
        return _chatCreatedAtBlock[chatId];
    }
}

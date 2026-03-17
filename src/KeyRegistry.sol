// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KeyRegistry {

    mapping(address => bytes) private _keys;

    event KeyPublished(
        address indexed user,
        bytes publicKey,
        uint256 blockNumber
    );

    function publishKey(bytes calldata publicKey) external {
        require(publicKey.length > 0, "KeyRegistry: empty public key");

        _keys[msg.sender] = publicKey;

        emit KeyPublished(msg.sender, publicKey, block.number);
    }

    function getKey(address user) external view returns (bytes memory) {
        bytes memory key = _keys[user];
        require(key.length > 0, "KeyRegistry: key not found");
        return key;
    }
}

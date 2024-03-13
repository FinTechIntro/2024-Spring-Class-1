// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IV1 {
    function increment() external returns (uint256);
}

interface IV2 {
    function increment() external returns (uint256);
}

contract V1 {
    address internal owner;
    address internal implementation;
    uint256 public count;

    function VERSION() external pure returns (string memory) {
        return "1.0";
    }

    function increment() external returns (uint256) {
        count += 1;
        return count;
    }
}

contract V2 {
    address internal owner;
    address internal implementation;
    uint256 public count;

    function VERSION() external pure returns (string memory) {
        return "2.0";
    }

    function increment() external returns (uint256) {
        count += 1;
        return count;
    }
}

contract Delegation {
    address internal owner;
    address internal implementation;

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }

    constructor(address _impl) payable {
        owner = msg.sender;
        implementation = _impl;
    }

    function upgrade(address _newImpl) public {
        require(msg.sender == owner, "Only the owner can upgrade");
        implementation = _newImpl;
    }

    fallback() external payable {
        address _impl = implementation;
        require(_impl != address(0), "Implementation address not set");

        (bool success,) = _impl.delegatecall(msg.data);
        require(success, "delegation failed");
    }

    receive() external payable {}
}
